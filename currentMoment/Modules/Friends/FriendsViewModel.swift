import Combine
import UIKit

@MainActor
final class FriendsViewModel {

    @Published private(set) var friends: [User] = []
    @Published private(set) var errorMessage: String?

    private let repository: CurrentMomentRepositoryProtocol
    private let searchSubject = CurrentValueSubject<String, Never>("")
    private var cancellables: Set<AnyCancellable> = []

    init(repository: CurrentMomentRepositoryProtocol) {
        self.repository = repository
        repository.friendsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] friends in
                self?.friends = friends
            }
            .store(in: &cancellables)
    }

    func updateSearchText(_ value: String) {
        searchSubject.send(value)
    }

    func addFriend(_ user: User) {
        Task {
            do { try await repository.addFriend(user.id) }
            catch { errorMessage = error.localizedDescription }
        }
    }

    func removeFriend(_ user: User) {
        Task {
            do { try await repository.removeFriend(user.id) }
            catch { errorMessage = error.localizedDescription }
        }
    }
    
    func shareLink(through app: AppShareOption) {
        let inviteText = "Join me on CurrentMoment! Download here: https://apps.apple.com/app/idYOUR_APP_ID"
        guard let encodedText = inviteText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            fallbackShare(text: inviteText)
            return
        }
        
        var urlToOpen: URL?
        switch app {
        case .telegram:
            urlToOpen = URL(string: "tg://msg?text=\(encodedText)")
        case .whatsapp:
            urlToOpen = URL(string: "whatsapp://send?text=\(encodedText)")
        case .instagramDMs:
            urlToOpen = URL(string: "instagram://direct?text=\(encodedText)")
        case .instagramStory:
            urlToOpen = URL(string: "instagram://")  // Instagram Story сложнее, просто открываем Instagram
        case .messages:
            urlToOpen = URL(string: "sms:&body=\(encodedText)")
        case .other:
            urlToOpen = nil
        }
        
        if let url = urlToOpen, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            fallbackShare(text: inviteText)
        }
    }
    
    private func fallbackShare(text: String) {
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}
