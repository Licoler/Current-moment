import XCTest
@testable import currentMoment

final class CameraViewModelTests: XCTestCase {
    
    @MainActor
    func testCaptureUsesDemoImageWhenCameraUnavailable() {
        let repository = MockCurrentMomentRepository(
            widgetService: TestCurrentMomentWidgetService()
        )
        
        let viewModel = CameraViewModel(repository: repository)
        
        let expectation = expectation(description: "captured asset")
        
        viewModel.onCaptureAsset = { (asset: CapturedMomentAsset) in
            XCTAssertFalse(asset.isLivePhoto)
            expectation.fulfill()
        }
        
        viewModel.captureMoment()
        
        wait(for: [expectation], timeout: 1)
    }
}
