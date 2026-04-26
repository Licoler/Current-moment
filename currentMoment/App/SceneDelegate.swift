import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var coordinator: AppCoordinator?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard
            let windowScene = scene as? UIWindowScene,
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
        else { return }

        let window      = UIWindow(windowScene: windowScene)
        window.frame = windowScene.coordinateSpace.bounds
        let coordinator = AppCoordinator(window: window, container: appDelegate.container)
        self.window      = window
        self.coordinator = coordinator
        coordinator.start()

        if let url = connectionOptions.urlContexts.first?.url {
            coordinator.handle(DeepLinkRoute.parse(url: url) ?? .history)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard
            let url   = URLContexts.first?.url,
            let route = DeepLinkRoute.parse(url: url)
        else { return }

        coordinator?.handle(route)
    }
}
