import Combine
import Foundation

@MainActor
final class FriendsViewModel {

    @Published private(set) var friends:      [User] = []
    @Published private(set) var suggestions:  [User] = []
    @Published private(set) var errorMessage: String?

    private let repository:    CurrentMomentRepositoryProtocol
    private let searchSubject  = CurrentValueSubject<String, Never>("")
    private var cancellables:  Set<AnyCancellable> = []

    init(repository: CurrentMomentRepositoryProtocol) {
        self.repository = repository

        repository.friendsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] friends in self?.friends = friends }
            .store(in: &cancellables)

        searchSubject
            .removeDuplicates()
            .debounce(for: .milliseconds(250), scheduler: DispatchQueue.main)
            .sink { [weak self] query in self?.search(query: query) }
            .store(in: &cancellables)

        search(query: "")
    }

    func updateSearchText(_ value: String) {
        searchSubject.send(value)
    }

    func addFriend(_ user: User) {
        Task {
            do {
                try await repository.addFriend(user.id)
                search(query: searchSubject.value)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func removeFriend(_ user: User) {
        Task {
            do {
                try await repository.removeFriend(user.id)
                search(query: searchSubject.value)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func search(query: String) {
        Task {
            do {
                suggestions = try await repository.searchUsers(matching: query)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
