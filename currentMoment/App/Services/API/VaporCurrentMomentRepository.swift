import Foundation
import Combine

final class VaporCurrentMomentRepository: CurrentMomentRepositoryProtocol {

    private let sessionSubject = CurrentValueSubject<User?, Never>(nil)
    private let momentsSubject = CurrentValueSubject<[Moment], Never>([])
    private let friendsSubject = CurrentValueSubject<[User], Never>([])

    var sessionPublisher: AnyPublisher<User?, Never> { sessionSubject.eraseToAnyPublisher() }
    var momentsPublisher: AnyPublisher<[Moment], Never> { momentsSubject.eraseToAnyPublisher() }
    var friendsPublisher: AnyPublisher<[User], Never> { friendsSubject.eraseToAnyPublisher() }

    func currentUser() -> User? { sessionSubject.value }

    func loadInitialState() async {
        guard APIClient.shared.hasToken else {
            clear()
            return
        }
        do {
            async let userDTO = APIClient.shared.fetchCurrentUser()
            async let usersDTO = APIClient.shared.fetchUsers()
            async let momentsDTO = APIClient.shared.fetchMoments()
            let user = try await userDTO
            let users = try await usersDTO
            let moments = try await momentsDTO
            let domainUser = user.toDomainUser()
            let domainUsers = users.map { $0.toDomainUser() }
            let domainMoments = moments.map { $0.toDomainMoment() }
            sessionSubject.send(domainUser)
            momentsSubject.send(domainMoments)
            await loadFriends(userId: domainUser.id, allUsers: domainUsers)
        } catch {
            print("loadInitialState error: \(error)")
            APIClient.shared.clearToken()
            clear()
        }
    }

    func signIn(username: String, password: String) async throws {
        _ = try await APIClient.shared.login(username: username, password: password)
        await loadInitialState()
    }

    func signInDemoUser() async throws {
        try await signIn(username: "demo", password: "demo12345")
    }

    func signInAnonymously() async throws {
        try await signInDemoUser()
    }

    func signOut() async throws {
        APIClient.shared.clearToken()
        clear()
    }

    func updateProfile(fullName: String, username: String, avatarURL: String?) async throws {
        let updatedUserDTO = try await APIClient.shared.updateProfile(fullName: fullName, username: username, avatarURL: avatarURL)
        let domainUser = updatedUserDTO.toDomainUser()
        sessionSubject.send(domainUser)
    }

    func searchUsers(matching query: String) async throws -> [User] { [] }
    func addFriend(_ friendID: String) async throws {}
    func removeFriend(_ friendID: String) async throws {}
    
    // MARK: - Моменты

    func sendMoment(_ draft: MomentDraft) async throws -> Moment {
        // Пока заглушка
        throw AppError.generic("Not implemented")
    }

    // удаление момента
    func deleteMoment(_ momentId: String) async throws {
        try await APIClient.shared.deleteMoment(momentId)
        await loadInitialState()
    }

    //отправка комментария
    func sendReply(momentId: String, content: String) async throws {
        _ = try await APIClient.shared.createReply(momentId: momentId, content: content)
    }

    // создать момент
    func createMoment(imageUrl: String, caption: String?, isLivePhoto: Bool) async throws -> Moment {
        let apiMoment = try await APIClient.shared.createMoment(imageUrl: imageUrl, caption: caption, isLivePhoto: isLivePhoto)
        return apiMoment.toDomainMoment()
    }

    func signUp(username: String, email: String, password: String, fullName: String) async throws {
        let request = RegisterRequest(username: username, email: email, password: password, fullName: fullName)
        let response = try await APIClient.shared.register(request)
        AuthTokenStore.save(response.token!)
        await loadInitialState()
    }

    private func clear() {
        sessionSubject.send(nil)
        momentsSubject.send([])
        friendsSubject.send([])
    }

    private func loadFriends(userId: String, allUsers: [User]) async {
        print("=== loadFriends called with userId: \(userId)")
        do {
            let friendships = try await APIClient.shared.fetchFriendships(for: userId)
            print("friendships received: \(friendships)")
            
            let friendIDs = friendships.compactMap { friendship -> String? in
                guard friendship.status == "accepted" else { return nil }
                if friendship.requester.id == userId {
                    return friendship.receiver.id
                } else if friendship.receiver.id == userId {
                    return friendship.requester.id
                }
                return nil
            }
            print("friendIDs extracted: \(friendIDs)")
            
            let friends = allUsers.filter { friendIDs.contains($0.id) }
            print("friends after filter: \(friends.map { $0.username })")
            
            await MainActor.run {
                self.friendsSubject.send(friends)
            }
        } catch {
            print("Failed to load friends: \(error)")
            await MainActor.run {
                self.friendsSubject.send([])
            }
        }
    }
}
