import Combine
import Foundation

@MainActor
final class AuthViewModel {
    
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    private let repository: CurrentMomentRepositoryProtocol
    var onAuthenticated: (() -> Void)?
    
    init(repository: CurrentMomentRepositoryProtocol) {
        self.repository = repository
    }
    
    func continueWithDemo() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await repository.signInDemoUser()
                isLoading = false
                onAuthenticated?()
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func continueAsGuest() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await repository.signInAnonymously()
                isLoading = false
                onAuthenticated?()
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
