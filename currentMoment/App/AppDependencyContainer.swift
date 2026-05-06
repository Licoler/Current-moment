import Foundation
import UIKit

@MainActor
final class AppDependencyContainer {
    
    let repository: CurrentMomentRepositoryProtocol
    let widgetService: CurrentMomentWidgetServiceProtocol
    let imagePipeline: ImagePipeline
    let notificationService: CurrentMomentNotificationServiceProtocol
    
    let authViewModel: AuthViewModel
    let cameraViewModel: CameraViewModel
    let historyViewModel: HistoryViewModel
    let profileViewModel: ProfileViewModel
    let friendsViewModel: FriendsViewModel
    
    private init(
        repository: CurrentMomentRepositoryProtocol,
        widgetService: CurrentMomentWidgetServiceProtocol,
        imagePipeline: ImagePipeline
    ) {
        self.repository = repository
        self.widgetService = widgetService
        self.imagePipeline = imagePipeline
        self.notificationService = CurrentMomentNotificationService(repository: repository)
        
        self.authViewModel = AuthViewModel(repository: repository)
        self.cameraViewModel = CameraViewModel(repository: repository)
        self.historyViewModel = HistoryViewModel(repository: repository)
        self.profileViewModel = ProfileViewModel(repository: repository)
        self.friendsViewModel = FriendsViewModel(repository: repository)
    }
    
    static func makeDefault() -> AppDependencyContainer {
        let widgetService = CurrentMomentWidgetService()
        let repository = VaporCurrentMomentRepository()
        return AppDependencyContainer(
            repository: repository,
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
