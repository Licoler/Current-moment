import Combine
import Foundation

protocol CurrentMomentRepositoryProtocol: AnyObject {
    var sessionPublisher: AnyPublisher<User?, Never> { get }
    var momentsPublisher: AnyPublisher<[Moment], Never> { get }
    var friendsPublisher: AnyPublisher<[User], Never> { get }

    func loadInitialState() async
    func currentUser() -> User?
    func signInDemoUser() async throws
    func signInAnonymously() async throws
    func signOut() async throws
    func updateProfile(fullName: String, username: String, avatarURL: String?) async throws
    func searchUsers(matching query: String) async throws -> [User]
    func addFriend(_ friendID: String) async throws
    func removeFriend(_ friendID: String) async throws
    func sendMoment(_ draft: MomentDraft) async throws -> Moment
}

enum CurrentMomentRepositoryFactory {
    static func makeRepository(widgetService: CurrentMomentWidgetServiceProtocol) -> CurrentMomentRepositoryProtocol {
        #if canImport(FirebaseAuth) && canImport(FirebaseFirestore) && canImport(FirebaseStorage)
        return FirebaseCurrentMomentRepository(widgetService: widgetService)
        #else
        return MockCurrentMomentRepository(widgetService: widgetService)
        #endif
    }
}

private struct MockRepositoryState: Codable {
    var currentUserID: String?
    var users: [User]
    var moments: [Moment]
    var friendships: [Friendship]
}

final class MockCurrentMomentRepository: CurrentMomentRepositoryProtocol {
    private let sessionSubject = CurrentValueSubject<User?, Never>(nil)
    private let momentsSubject = CurrentValueSubject<[Moment], Never>([])
    private let friendsSubject = CurrentValueSubject<[User], Never>([])
    private let widgetService: CurrentMomentWidgetServiceProtocol
    private let stateURL: URL
    private let imagesDirectoryURL: URL

    private var state: MockRepositoryState

    init(widgetService: CurrentMomentWidgetServiceProtocol, rootURL: URL? = nil) {
        self.widgetService = widgetService

        let supportURL = rootURL ?? ((try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? URL(fileURLWithPath: NSTemporaryDirectory()))

        let repositoryRootURL = supportURL.appendingPathComponent("MockCurrentMomentRepository", isDirectory: true)
        self.stateURL = repositoryRootURL.appendingPathComponent("state.json")
        self.imagesDirectoryURL = repositoryRootURL.appendingPathComponent("Images", isDirectory: true)
        self.state = Self.seedState()

        try? FileManager.default.createDirectory(at: repositoryRootURL, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: imagesDirectoryURL, withIntermediateDirectories: true)
    }

    var sessionPublisher: AnyPublisher<User?, Never> {
        sessionSubject.eraseToAnyPublisher()
    }

    var momentsPublisher: AnyPublisher<[Moment], Never> {
        momentsSubject.eraseToAnyPublisher()
    }

    var friendsPublisher: AnyPublisher<[User], Never> {
        friendsSubject.eraseToAnyPublisher()
    }

    func loadInitialState() async {
        if let data = try? Data(contentsOf: stateURL),
           let decoded = try? JSONDecoder.currentMoment.decode(MockRepositoryState.self, from: data) {
            state = decoded
        } else {
            persist()
        }

        publishState()
        await widgetService.syncSnapshots(
            moments: visibleMoments(for: currentUser()),
            users: decoratedUsers(),
            currentUser: currentUser()
        )
    }

    func currentUser() -> User? {
        guard let currentUserID = state.currentUserID,
              let user = state.users.first(where: { $0.id == currentUserID }) else {
            return nil
        }

        return decorate(user: user)
    }

    func signInDemoUser() async throws {
        if currentUser() != nil {
            publishState()
            return
        }

        let primaryUser = Self.seedPrimaryUser()
        if !state.users.contains(where: { $0.id == primaryUser.id }) {
            state.users.insert(primaryUser, at: 0)
        }
        state.currentUserID = primaryUser.id
        persist()
        publishState()
    }

    func signInAnonymously() async throws {
        let identifier = UUID().uuidString
        let user = User(
            id: identifier,
            username: "guest_\(identifier.prefix(4))",
            fullName: "Guest User",
            friendIDs: [],
            createdAt: .now,
            friendsCount: 0
        )
        state.users.insert(user, at: 0)
        state.currentUserID = identifier
        persist()
        publishState()
    }

    func signOut() async throws {
        state.currentUserID = nil
        persist()
        publishState()
        await widgetService.syncSnapshots(moments: [], users: decoratedUsers(), currentUser: nil)
    }

    func updateProfile(fullName: String, username: String, avatarURL: String?) async throws {
        let cleanedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedFullName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanedUsername.isEmpty else {
            throw AppError.invalidUsername
        }

        guard let currentUserID = state.currentUserID,
              let index = state.users.firstIndex(where: { $0.id == currentUserID }) else {
            throw AppError.missingCurrentUser
        }

        state.users[index].username = cleanedUsername
        state.users[index].fullName = cleanedFullName.isEmpty ? cleanedUsername : cleanedFullName
        state.users[index].avatarURL = avatarURL

        persist()
        publishState()
    }

    func searchUsers(matching query: String) async throws -> [User] {
        let cleaned = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let currentUser = currentUser()

        return decoratedUsers()
            .filter { user in
                guard user.id != currentUser?.id else { return false }
                guard !(currentUser?.friendIDs.contains(user.id) ?? false) else { return false }
                guard !cleaned.isEmpty else { return true }
                return user.username.lowercased().contains(cleaned) || user.displayName.lowercased().contains(cleaned)
            }
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    func addFriend(_ friendID: String) async throws {
        guard let currentUserID = state.currentUserID else {
            throw AppError.missingCurrentUser
        }

        guard state.users.contains(where: { $0.id == friendID }) else {
            throw AppError.generic("Friend not found.")
        }

        if state.friendships.contains(where: { $0.status == .accepted && Set([$0.requesterId, $0.receiverId]) == Set([currentUserID, friendID]) }) {
            return
        }

        let friendship = Friendship(
            id: UUID().uuidString,
            requesterId: currentUserID,
            receiverId: friendID,
            status: .accepted,
            createdAt: .now
        )
        state.friendships.append(friendship)
        persist()
        publishState()
    }

    func removeFriend(_ friendID: String) async throws {
        guard let currentUserID = state.currentUserID else {
            throw AppError.missingCurrentUser
        }

        state.friendships.removeAll {
            $0.status == .accepted && Set([$0.requesterId, $0.receiverId]) == Set([currentUserID, friendID])
        }

        persist()
        publishState()
    }

    func sendMoment(_ draft: MomentDraft) async throws -> Moment {
        guard let currentUser = currentUser() else {
            throw AppError.missingCurrentUser
        }

        guard !draft.recipientIds.isEmpty else {
            throw AppError.noRecipientsSelected
        }

        let identifier = UUID().uuidString
        let imageURL = try write(data: draft.imageData, named: "\(identifier).jpg")
        let thumbnailURL = try write(data: draft.thumbnailData, named: "\(identifier)-thumb.jpg")
        let moment = Moment(
            id: identifier,
            senderId: currentUser.id,
            recipientIds: draft.recipientIds,
            imageURL: imageURL.path,
            caption: draft.caption,
            createdAt: .now,
            thumbnailURL: thumbnailURL.path,
            senderName: currentUser.displayName,
            isLivePhoto: draft.isLivePhoto
        )

        state.moments.insert(moment, at: 0)
        persist()
        publishState()
        await widgetService.syncSnapshots(
            moments: visibleMoments(for: currentUser),
            users: decoratedUsers(),
            currentUser: currentUser
        )
        return moment
    }

    private func publishState() {
        let currentUser = currentUser()
        sessionSubject.send(currentUser)
        momentsSubject.send(visibleMoments(for: currentUser))
        friendsSubject.send(visibleFriends(for: currentUser))
    }

    private func visibleMoments(for currentUser: User?) -> [Moment] {
        guard let currentUser else { return [] }
        return state.moments
            .filter { $0.senderId == currentUser.id || $0.recipientIds.contains(currentUser.id) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private func visibleFriends(for currentUser: User?) -> [User] {
        guard let currentUser else { return [] }
        let friendIDs = Set(currentUser.friendIDs)
        return decoratedUsers()
            .filter { friendIDs.contains($0.id) }
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    private func decoratedUsers() -> [User] {
        state.users.map(decorate(user:))
    }

    private func decorate(user: User) -> User {
        let friendIDs = acceptedFriendIDs(for: user.id)
        return user.applying(friendIDs: friendIDs)
    }

    private func acceptedFriendIDs(for userID: String) -> [String] {
        state.friendships.compactMap { friendship in
            guard friendship.status == .accepted else { return nil }
            if friendship.requesterId == userID {
                return friendship.receiverId
            }
            if friendship.receiverId == userID {
                return friendship.requesterId
            }
            return nil
        }
    }

    private func persist() {
        do {
            let data = try JSONEncoder.currentMoment.encode(state)
            try data.write(to: stateURL, options: .atomic)
        } catch {
            #if DEBUG
            print("Persist failed: \(error)")
            #endif
        }
    }

    private func write(data: Data, named fileName: String) throws -> URL {
        let fileURL = imagesDirectoryURL.appendingPathComponent(fileName)
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }
}

private extension MockCurrentMomentRepository {
    static func seedPrimaryUser() -> User {
        User(
            id: "user-current",
            username: "current.moment",
            fullName: "Alex Current",
            email: "alex@currentmoment.app",
            friendIDs: ["user-lena", "user-mila", "user-sam", "user-noah"],
            createdAt: Date(timeIntervalSince1970: 1_711_000_000),
            friendsCount: 4
        )
    }

    static func seedState() -> MockRepositoryState {
        let now = Date()
        let currentUser = seedPrimaryUser()
        let users = [
            currentUser,
            User(id: "user-lena", username: "lena.c", fullName: "Lena Carter", email: "lena@currentmoment.app", createdAt: now.addingTimeInterval(-40_000)),
            User(id: "user-mila", username: "mila.day", fullName: "Mila Day", email: "mila@currentmoment.app", createdAt: now.addingTimeInterval(-80_000)),
            User(id: "user-sam", username: "sam.green", fullName: "Sam Green", email: "sam@currentmoment.app", createdAt: now.addingTimeInterval(-120_000)),
            User(id: "user-noah", username: "noah.k", fullName: "Noah Kim", email: "noah@currentmoment.app", createdAt: now.addingTimeInterval(-150_000)),
            User(id: "user-jules", username: "jules.park", fullName: "Jules Park", email: "jules@currentmoment.app", createdAt: now.addingTimeInterval(-210_000)),
            User(id: "user-ruby", username: "ruby.chen", fullName: "Ruby Chen", email: "ruby@currentmoment.app", createdAt: now.addingTimeInterval(-260_000))
        ]

        let friendships = [
            Friendship(id: "friendship-1", requesterId: currentUser.id, receiverId: "user-lena", status: .accepted, createdAt: now.addingTimeInterval(-90_000)),
            Friendship(id: "friendship-2", requesterId: currentUser.id, receiverId: "user-mila", status: .accepted, createdAt: now.addingTimeInterval(-85_000)),
            Friendship(id: "friendship-3", requesterId: currentUser.id, receiverId: "user-sam", status: .accepted, createdAt: now.addingTimeInterval(-75_000)),
            Friendship(id: "friendship-4", requesterId: currentUser.id, receiverId: "user-noah", status: .accepted, createdAt: now.addingTimeInterval(-65_000))
        ]

        let moments = [
            Moment(
                id: "moment-1",
                senderId: "user-lena",
                recipientIds: [currentUser.id],
                imageURL: "",
                caption: "Golden hour from the tram.",
                createdAt: now.addingTimeInterval(-1_200),
                thumbnailURL: nil,
                senderName: "Lena Carter",
                isLivePhoto: false
            ),
            Moment(
                id: "moment-2",
                senderId: "user-mila",
                recipientIds: [currentUser.id],
                imageURL: "",
                caption: "Coffee worth leaving the desk for.",
                createdAt: now.addingTimeInterval(-3_200),
                thumbnailURL: nil,
                senderName: "Mila Day",
                isLivePhoto: false
            ),
            Moment(
                id: "moment-3",
                senderId: currentUser.id,
                recipientIds: ["user-lena", "user-noah"],
                imageURL: "",
                caption: "Current build check-in.",
                createdAt: now.addingTimeInterval(-6_200),
                thumbnailURL: nil,
                senderName: currentUser.displayName,
                isLivePhoto: false
            )
        ]

        return MockRepositoryState(
            currentUserID: nil,
            users: users,
            moments: moments,
            friendships: friendships
        )
    }
}

private extension JSONDecoder {
    static var currentMoment: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

private extension JSONEncoder {
    static var currentMoment: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
