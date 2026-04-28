import Combine
import Foundation
import UIKit

@MainActor
final class AppCoordinator {
    
    private enum RootState {
        case launch
        case auth
        case main
    }
    
    private let window: UIWindow
    private let container: AppDependencyContainer
    private let navigationController = UINavigationController()
    private var cancellables: Set<AnyCancellable> = []
    private var rootState: RootState = .launch
    
    init(window: UIWindow, container: AppDependencyContainer) {
        self.window    = window
        self.container = container
    }
    
    // MARK: - Start
    
    func start() {
        configureNavigationController()
        showLaunch()
        window.rootViewController = navigationController
        window.overrideUserInterfaceStyle = .dark
        window.makeKeyAndVisible()
        
        
        bindSession()
        container.warmUp()
    }
    
    func handle(_ route: DeepLinkRoute) {
        guard container.repository.currentUser() != nil else { return }
        switch route {
        case .history:
            showMainIfNeeded(); showHistory()
        case .moment(let id):
            showMainIfNeeded(); showHistory(momentID: id)
        }
    }
    
    // MARK: - Session binding
    
    private func bindSession() {
        container.repository.sessionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                guard let self else { return }
                if user == nil { self.showAuthIfNeeded() }
                else           { self.showMainIfNeeded() }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Navigation helpers
    
    private func configureNavigationController() {
        navigationController.setNavigationBarHidden(true, animated: false)
        navigationController.view.backgroundColor = CMColor.background
    }
    
    private func showLaunch() {
        rootState = .launch
        navigationController.setViewControllers([LaunchViewController()], animated: false)
    }
    
    private func showAuthIfNeeded() {
        guard rootState != .auth else { return }
        rootState = .auth
        let viewModel = AuthViewModel(repository: container.repository)
        viewModel.onAuthenticated = { [weak self] in self?.showMainIfNeeded() }
        let controller = AuthViewController(viewModel: viewModel)
        navigationController.setViewControllers([controller], animated: true)
    }
    
    private func showMainIfNeeded() {
        guard rootState != .main else { return }
        rootState = .main
        navigationController.setViewControllers([makeCameraModule()], animated: true)
    }
    
    // MARK: - Camera module
    
    private func makeCameraModule() -> UIViewController {
        let viewModel  = CameraViewModel(repository: container.repository)
        let controller = CameraViewController(viewModel: viewModel)
        
        controller.onFriendsButtonTap = { [weak self] in self?.showFriends() }
        controller.onProfileButtonTap = { [weak self] in self?.showProfile() }
        controller.onHistoryButtonTap = { [weak self] in self?.showHistory() }
        controller.onPreviewRequested = { [weak self] asset in self?.showPreview(for: asset) }
        
        return controller
    }
    
    // MARK: - Screens
    
    private func showPreview(for asset: CapturedMomentAsset) {
        let viewModel  = PreviewViewModel(repository: container.repository, imagePipeline: container.imagePipeline, asset: asset)
        let controller = PreviewViewController(viewModel: viewModel)
        controller.modalPresentationStyle = .fullScreen
        controller.onDismiss     = { [weak controller] in controller?.dismiss(animated: true) }
        controller.onMomentSent  = { [weak self, weak controller] moment in
            controller?.dismiss(animated: true)
            self?.showHistory(momentID: moment.id)
        }
        navigationController.topViewController?.present(controller, animated: true)
    }
    
    private func showFriends() {
        let viewModel  = FriendsViewModel(repository: container.repository)
        let controller = FriendsViewController(viewModel: viewModel)
        controller.onBack = { [weak self] in self?.navigationController.popViewController(animated: true) }
        push(controller)
    }
    
    private func showHistory(momentID: String? = nil) {
        let viewModel  = HistoryViewModel(repository: container.repository)
        let controller = HistoryViewController(viewModel: viewModel)
        controller.onBack = { [weak self] in self?.navigationController.popViewController(animated: true) }
        controller.onMomentSelected = { [weak self] moment in self?.showMomentDetail(moment) }
        push(controller)
        if let momentID { controller.scrollToMoment(with: momentID) }
    }
    
    private func showMomentDetail(_ moment: Moment) {
        let controller = MomentDetailViewController(moment: moment, imagePipeline: container.imagePipeline)
        controller.onBack = { [weak self] in self?.navigationController.popViewController(animated: true) }
        controller.onDelete = { [weak self] in self?.navigationController.popViewController(animated: true) }
        push(controller)
    }
    
    private func showProfile() {
        let viewModel  = ProfileViewModel(repository: container.repository)
        let controller = ProfileViewController(viewModel: viewModel)
        controller.onBack      = { [weak self] in self?.navigationController.popViewController(animated: true) }
        controller.onLoggedOut = { [weak self] in self?.showAuthIfNeeded() }
        push(controller)
    }
    
    private func push(_ viewController: UIViewController) {
        guard !(navigationController.topViewController?.isKind(of: type(of: viewController)) ?? false) else { return }
        navigationController.pushViewController(viewController, animated: true)
    }
}
