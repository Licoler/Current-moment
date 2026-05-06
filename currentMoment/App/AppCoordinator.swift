import UIKit

@MainActor
final class AppCoordinator {

    private let window: UIWindow
    private let container: AppDependencyContainer
    private let navigationController = UINavigationController()

    init(window: UIWindow, container: AppDependencyContainer) {
        self.window = window
        self.container = container
    }

    func start() {
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        routeInitial()
    }

    private func routeInitial() {
        if container.repository.currentUser() == nil {
            showAuth()
        } else {
            showCamera()
        }
    }

    func handle(_ route: DeepLinkRoute) {
        switch route {
        case .history:
            showHistory()
        case .moment(let id):
            showMoment(id: id)
        }
    }

    private func showAuth() {
        let authVC = AuthViewController()
        authVC.viewModel = container.authViewModel
        authVC.onLoginSuccess = { [weak self] in
            self?.showCamera()
        }
        navigationController.setViewControllers([authVC], animated: false)
    }

    private func showCamera() {
        let cameraVC = CameraViewController(viewModel: container.cameraViewModel)
        cameraVC.onHistoryButtonTap = { [weak self] in self?.showHistory() }
        cameraVC.onProfileButtonTap = { [weak self] in self?.showProfile() }
        cameraVC.onFriendsButtonTap = { [weak self] in self?.showFriends() }
        cameraVC.onPreviewRequested = { [weak self] asset in self?.showPreview(with: asset) }
        navigationController.setViewControllers([cameraVC], animated: false)
    }

    private func showHistory() {
        let historyVC = HistoryViewController(viewModel: container.historyViewModel)
        historyVC.onBack = { [weak self] in self?.navigationController.popViewController(animated: true) }
        historyVC.onMomentSelected = { [weak self] moment in self?.showMomentDetail(moment) }
        navigationController.pushViewController(historyVC, animated: true)
    }

    private func showProfile() {
        let profileVC = ProfileViewController(viewModel: container.profileViewModel)
        profileVC.onBack = { [weak self] in
            self?.navigationController.popViewController(animated: true)
        }
        profileVC.onLoggedOut = { [weak self] in
            self?.navigationController.popToRootViewController(animated: false)
            self?.showAuth()
        }
        navigationController.pushViewController(profileVC, animated: true)
    }

    private func showFriends() {
        let friendsVC = FriendsViewController(viewModel: container.friendsViewModel)
        friendsVC.onBack = { [weak self] in self?.navigationController.popViewController(animated: true) }
        navigationController.pushViewController(friendsVC, animated: true)
    }

    private func showPreview(with asset: CapturedMomentAsset) {
        let previewVM = PreviewViewModel(
            repository: container.repository,
            imagePipeline: container.imagePipeline,
            asset: asset
        )
        let previewVC = PreviewViewController(viewModel: previewVM)
        previewVC.onDismiss = { [weak self] in self?.navigationController.dismiss(animated: true) }
        previewVC.onMomentSent = { [weak self] _ in self?.navigationController.dismiss(animated: true) }
        previewVC.modalPresentationStyle = .fullScreen
        navigationController.present(previewVC, animated: true)
    }

    private func showMomentDetail(_ moment: Moment) {
        let detailVC = MomentDetailViewController(moment: moment, imagePipeline: container.imagePipeline)
        detailVC.onBack = { [weak self] in self?.navigationController.popViewController(animated: true) }
        navigationController.pushViewController(detailVC, animated: true)
    }

    private func showMoment(id: String) {
        let vc = UIViewController()
        vc.view.backgroundColor = .systemBackground
        vc.title = "Moment \(id)"
        navigationController.pushViewController(vc, animated: true)
    }
}
