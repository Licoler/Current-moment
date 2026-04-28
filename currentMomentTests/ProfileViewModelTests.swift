import XCTest
import Combine
@testable import currentMoment

final class ProfileViewModelTests: XCTestCase {
    
    var cancellables = Set<AnyCancellable>()
    
    @MainActor
    func testProfileStatsReflectSentMoments() async throws {
        let repository = MockCurrentMomentRepository(
            widgetService: TestCurrentMomentWidgetService(),
            rootURL: try makeTemporaryDirectory()
        )
        
        await repository.loadInitialState()
        try await repository.signInDemoUser()
        
        let image = makeImage()
        let data = try XCTUnwrap(image.jpegData(compressionQuality: 0.9))
        
        _ = try await repository.sendMoment(
            MomentDraft(
                imageData: data,
                thumbnailData: data,
                caption: "Profile stat moment",
                recipientIds: ["user-lena"],
                isLivePhoto: false
            )
        )
        
        let viewModel = ProfileViewModel(repository: repository)
        
        let profileLoaded = expectation(description: "profile stats")
        
        viewModel.$stats
            .dropFirst()
            .sink { stats in
                if stats.photosSent >= 1 {
                    profileLoaded.fulfill()
                }
            }
            .store(in: &cancellables)
        
        await fulfillment(of: [profileLoaded], timeout: 1)
        
        XCTAssertGreaterThanOrEqual(viewModel.stats.photosSent, 1)
        XCTAssertGreaterThanOrEqual(viewModel.stats.friendsCount, 4)
        XCTAssertNotNil(viewModel.user)
    }
}
