import Foundation

@MainActor
final class AppDependencyContainer {

    let repository:           CurrentMomentRepositoryProtocol
    let widgetService:        CurrentMomentWidgetServiceProtocol
    let imagePipeline:        ImagePipeline
    let notificationService:  CurrentMomentNotificationServiceProtocol

    private init(
        repository:    CurrentMomentRepositoryProtocol,
        widgetService: CurrentMomentWidgetServiceProtocol,
        imagePipeline: ImagePipeline
    ) {
        self.repository          = repository
        self.widgetService       = widgetService
        self.imagePipeline       = imagePipeline
        self.notificationService = CurrentMomentNotificationService(repository: repository)
    }

    static func makeDefault() -> AppDependencyContainer {
        let widgetService = CurrentMomentWidgetService()
        let repository    = CurrentMomentRepositoryFactory.makeRepository(widgetService: widgetService)
        return AppDependencyContainer(
            repository:    repository,
            widgetService: widgetService,
            imagePipeline: .shared
        )
    }

    func warmUp() {
        Task {
            await repository.loadInitialState()
            await notificationService.configure()
        }
    }
}
