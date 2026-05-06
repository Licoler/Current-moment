import Combine
import Foundation

protocol CurrentMomentRepositoryProtocol: AnyObject {
    var sessionPublisher: AnyPublisher<User?, Never> { get }
    var momentsPublisher: AnyPublisher<[Moment], Never> { get }
    var friendsPublisher: AnyPublisher<[User], Never> { get }
    
    func loadInitialState() async
    func signUp(username: String, email: String, password: String, fullName: String) async throws
    func signIn(username: String, password: String) async throws
    func currentUser() -> User?
    func signInDemoUser() async throws
    func signInAnonymously() async throws
    func signOut() async throws
    func updateProfile(fullName: String, username: String, avatarURL: String?) async throws
    func searchUsers(matching query: String) async throws -> [User]
    func addFriend(_ friendID: String) async throws
    func removeFriend(_ friendID: String) async throws
    func sendMoment(_ draft: MomentDraft) async throws -> Moment
    func sendReply(momentId: String, content: String) async throws
    func deleteMoment(_ momentId: String) async throws
    func createMoment(imageUrl: String, caption: String?, isLivePhoto: Bool) async throws -> Moment
}
