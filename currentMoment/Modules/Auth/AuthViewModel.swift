import Foundation

final class AuthViewModel {

    private let repository: CurrentMomentRepositoryProtocol

    init(repository: CurrentMomentRepositoryProtocol) {
        self.repository = repository
    }

    func login(username: String, password: String) async throws {
        try await repository.signIn(username: username, password: password)
    }

    func loginDemo() async throws {
        try await repository.signInDemoUser()
    }
    
    func register(username: String, email: String?, password: String, fullName: String) async throws {
        try await repository.signUp(username: username, email: email ?? "", password: password, fullName: fullName)
    }
}
