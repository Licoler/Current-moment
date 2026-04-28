#if canImport(FirebaseAuth) && canImport(FirebaseCore) && canImport(FirebaseFirestore) && canImport(FirebaseStorage)
import Combine
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage
import Foundation

final class FirebaseCurrentMomentRepository: NSObject, CurrentMomentRepositoryProtocol {
    private let sessionSubject = CurrentValueSubject<User?, Never>(nil)
    private let momentsSubject = CurrentValueSubject<[Moment], Never>([])
    private let friendsSubject = CurrentValueSubject<[User], Never>([])
    private let widgetService: CurrentMomentWidgetServiceProtocol
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    private var momentsListener: ListenerRegistration?
    private var friendshipsListener: ListenerRegistration?
    
    init(widgetService: CurrentMomentWidgetServiceProtocol) {
        self.widgetService = widgetService
    }
    
    deinit {
        momentsListener?.remove()
        friendshipsListener?.remove()
    }
    
    var sessionPublisher: AnyPublisher<User?, Never> { sessionSubject.eraseToAnyPublisher() }
    var momentsPublisher: AnyPublisher<[Moment], Never> { momentsSubject.eraseToAnyPublisher() }
    var friendsPublisher: AnyPublisher<[User], Never> { friendsSubject.eraseToAnyPublisher() }
    
    func loadInitialState() async {
        guard let authUser = Auth.auth().currentUser else {
            sessionSubject.send(nil)
            return
        }
        
        do {
            let user = try await fetchUser(id: authUser.uid)
            sessionSubject.send(user)
            startListeners(for: user)
        } catch {
            sessionSubject.send(nil)
        }
    }
    
    func currentUser() -> User? {
        sessionSubject.value
    }
    
    func signInDemoUser() async throws {
        let result = try await Auth.auth().signInAnonymously()
        let user = try await ensureDemoUser(for: result.user)
        sessionSubject.send(user)
        startListeners(for: user)
    }
    
    func signInAnonymously() async throws {
        let result = try await Auth.auth().signInAnonymously()
        let user = try await ensureAnonymousUser(for: result.user)
        sessionSubject.send(user)
        startListeners(for: user)
    }
    
    func signOut() async throws {
        try Auth.auth().signOut()
        sessionSubject.send(nil)
        momentsSubject.send([])
        friendsSubject.send([])
        await widgetService.syncSnapshots(moments: [], users: [], currentUser: nil)
    }
    
    func updateProfile(fullName: String, username: String, avatarURL: String?) async throws {
        guard let currentUser = sessionSubject.value else {
            throw AppError.missingCurrentUser
        }
        
        let cleanedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedUsername.isEmpty else {
            throw AppError.invalidUsername
        }
        
        let cleanedFullName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let payload: [String: Any] = [
            "username": cleanedUsername,
            "fullName": cleanedFullName.isEmpty ? cleanedUsername : cleanedFullName,
            "avatarURL": avatarURL as Any
        ]
        
        try await db.collection("users").document(currentUser.id).setData(payload, merge: true)
        if let refreshed = try? await fetchUser(id: currentUser.id) {
            sessionSubject.send(refreshed)
            startListeners(for: refreshed)
        }
    }
    
    func searchUsers(matching query: String) async throws -> [User] {
        let snapshot = try await db.collection("users")
            .order(by: "username")
            .limit(to: 30)
            .getDocuments()
        
        let currentUser = sessionSubject.value
        let cleaned = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        return snapshot.documents.compactMap { User(documentID: $0.documentID, data: $0.data()) }
            .filter { user in
                guard user.id != currentUser?.id else { return false }
                guard !(currentUser?.friendIDs.contains(user.id) ?? false) else { return false }
                guard !cleaned.isEmpty else { return true }
                return user.username.lowercased().contains(cleaned) || user.displayName.lowercased().contains(cleaned)
            }
    }
    
    func addFriend(_ friendID: String) async throws {
        guard let currentUser = sessionSubject.value else {
            throw AppError.missingCurrentUser
        }
        
        let friendship = Friendship(
            id: UUID().uuidString,
            requesterId: currentUser.id,
            receiverId: friendID,
            status: .accepted,
            createdAt: .now
        )
        
        try await db.collection("friendships").document(friendship.id).setData(friendship.firestoreData)
    }
    
    func removeFriend(_ friendID: String) async throws {
        guard let currentUser = sessionSubject.value else {
            throw AppError.missingCurrentUser
        }
        
        let snapshot = try await db.collection("friendships")
            .whereField("participants", arrayContains: currentUser.id)
            .getDocuments()
        
        let targetDocument = snapshot.documents.first { document in
            let requesterId = document["requesterId"] as? String
            let receiverId = document["receiverId"] as? String
            return Set([requesterId, receiverId].compactMap { $0 }) == Set([currentUser.id, friendID])
        }
        
        if let targetDocument {
            try await db.collection("friendships").document(targetDocument.documentID).delete()
        }
    }
    
    func sendMoment(_ draft: MomentDraft) async throws -> Moment {
        guard let currentUser = sessionSubject.value else {
            throw AppError.missingCurrentUser
        }
        
        guard !draft.recipientIds.isEmpty else {
            throw AppError.noRecipientsSelected
        }
        
        let momentID = UUID().uuidString
        let imageReference = storage.reference().child("moments/\(momentID).jpg")
        _ = try await imageReference.putDataAsync(draft.imageData)
        let imageURL = try await imageReference.downloadURL()
        
        let thumbReference = storage.reference().child("moments/\(momentID)-thumb.jpg")
        _ = try await thumbReference.putDataAsync(draft.thumbnailData)
        let thumbURL = try await thumbReference.downloadURL()
        
        let moment = Moment(
            id: momentID,
            senderId: currentUser.id,
            recipientIds: draft.recipientIds,
            imageURL: imageURL.absoluteString,
            caption: draft.caption,
            createdAt: .now,
            thumbnailURL: thumbURL.absoluteString,
            senderName: currentUser.displayName,
            isLivePhoto: draft.isLivePhoto
        )
        
        try await db.collection("moments").document(moment.id).setData(moment.firestoreData)
        return moment
    }
    
    private func startListeners(for user: User) {
        momentsListener?.remove()
        friendshipsListener?.remove()
        
        momentsListener = db.collection("moments")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self else { return }
                let moments = snapshot?.documents.compactMap { Moment(documentID: $0.documentID, data: $0.data()) } ?? []
                let visible = moments.filter { $0.senderId == user.id || $0.recipientIds.contains(user.id) }
                self.momentsSubject.send(visible)
                Task {
                    await self.widgetService.syncSnapshots(
                        moments: visible,
                        users: [user] + self.friendsSubject.value,
                        currentUser: user
                    )
                }
            }
        
        friendshipsListener = db.collection("friendships")
            .whereField("participants", arrayContains: user.id)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self else { return }
                let friendships = snapshot?.documents.compactMap { Friendship(documentID: $0.documentID, data: $0.data()) } ?? []
                Task {
                    let friendIDs = friendships.compactMap { friendship -> String? in
                        guard friendship.status == .accepted else { return nil }
                        if friendship.requesterId == user.id {
                            return friendship.receiverId
                        }
                        if friendship.receiverId == user.id {
                            return friendship.requesterId
                        }
                        return nil
                    }
                    
                    let friends = await self.fetchUsers(ids: friendIDs)
                    self.friendsSubject.send(friends)
                    self.sessionSubject.send(user.applying(friendIDs: friendIDs))
                }
            }
    }
    
    private func fetchUser(id: String) async throws -> User {
        let snapshot = try await db.collection("users").document(id).getDocument()
        guard let data = snapshot.data(), let user = User(documentID: id, data: data) else {
            throw AppError.authenticationFailed
        }
        return user
    }
    
    private func fetchUsers(ids: [String]) async -> [User] {
        guard !ids.isEmpty else { return [] }
        return await withTaskGroup(of: User?.self, returning: [User].self) { group in
            ids.forEach { id in
                group.addTask { try? await self.fetchUser(id: id) }
            }
            
            var users: [User] = []
            for await user in group {
                if let user {
                    users.append(user)
                }
            }
            return users.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
        }
    }
    
    private func ensureDemoUser(for authUser: FirebaseAuth.User) async throws -> User {
        if let existing = try? await fetchUser(id: authUser.uid) {
            return existing
        }
        
        let user = User(
            id: authUser.uid,
            username: "demo.current",
            fullName: "CurrentMoment Demo",
            email: authUser.email,
            createdAt: .now
        )
        
        try await db.collection("users").document(user.id).setData(user.firestoreData, merge: true)
        return user
    }
    
    private func ensureAnonymousUser(for authUser: FirebaseAuth.User) async throws -> User {
        if let existing = try? await fetchUser(id: authUser.uid) {
            return existing
        }
        
        let user = User(
            id: authUser.uid,
            username: "guest_\(authUser.uid.prefix(4))",
            fullName: "Guest User",
            createdAt: .now
        )
        
        try await db.collection("users").document(user.id).setData(user.firestoreData, merge: true)
        return user
    }
}

private extension User {
    init?(documentID: String, data: [String: Any]) {
        guard let username = data["username"] as? String,
              let fullName = data["fullName"] as? String,
              let createdAt = data["createdAt"] as? Timestamp else {
            return nil
        }
        
        self.init(
            id: documentID,
            username: username,
            fullName: fullName,
            email: data["email"] as? String,
            avatarURL: data["avatarURL"] as? String,
            friendIDs: data["friendIDs"] as? [String] ?? [],
            createdAt: createdAt.dateValue(),
            friendsCount: data["friendsCount"] as? Int ?? 0
        )
    }
    
    var firestoreData: [String: Any] {
        [
            "username": username,
            "fullName": fullName,
            "email": email as Any,
            "avatarURL": avatarURL as Any,
            "friendIDs": friendIDs,
            "friendsCount": friendsCount,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
}

private extension Moment {
    init?(documentID: String, data: [String: Any]) {
        guard let senderId = data["senderId"] as? String,
              let recipientIds = data["recipientIds"] as? [String],
              let imageURL = data["imageURL"] as? String,
              let caption = data["caption"] as? String,
              let createdAt = data["createdAt"] as? Timestamp,
              let senderName = data["senderName"] as? String else {
            return nil
        }
        
        self.init(
            id: documentID,
            senderId: senderId,
            recipientIds: recipientIds,
            imageURL: imageURL,
            caption: caption,
            createdAt: createdAt.dateValue(),
            thumbnailURL: data["thumbnailURL"] as? String,
            senderName: senderName,
            isLivePhoto: data["isLivePhoto"] as? Bool ?? false
        )
    }
    
    var firestoreData: [String: Any] {
        [
            "senderId": senderId,
            "recipientIds": recipientIds,
            "imageURL": imageURL,
            "caption": caption,
            "createdAt": Timestamp(date: createdAt),
            "thumbnailURL": thumbnailURL as Any,
            "senderName": senderName,
            "isLivePhoto": isLivePhoto
        ]
    }
}

private extension Friendship {
    init?(documentID: String, data: [String: Any]) {
        guard let requesterId = data["requesterId"] as? String,
              let receiverId = data["receiverId"] as? String,
              let statusRaw = data["status"] as? String,
              let status = FriendshipStatus(rawValue: statusRaw),
              let createdAt = data["createdAt"] as? Timestamp else {
            return nil
        }
        
        self.init(
            id: documentID,
            requesterId: requesterId,
            receiverId: receiverId,
            status: status,
            createdAt: createdAt.dateValue()
        )
    }
    
    var firestoreData: [String: Any] {
        [
            "requesterId": requesterId,
            "receiverId": receiverId,
            "status": status.rawValue,
            "createdAt": Timestamp(date: createdAt),
            "participants": [requesterId, receiverId]
        ]
    }
}
#endif
