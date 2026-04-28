import XCTest
import Combine
@testable import currentMoment

final class PreviewViewModelTests: XCTestCase {
    
    var cancellables = Set<AnyCancellable>()
    
    @MainActor
    func testSendCreatesMomentForSelectedRecipients() async throws {
        let repository = MockCurrentMomentRepository(
            widgetService: TestCurrentMomentWidgetService(),
            rootURL: try makeTemporaryDirectory()
        )
        
        await repository.loadInitialState()
        try await repository.signInDemoUser()
        
        let asset: CapturedMomentAsset = try XCTUnwrap(
            CapturedMomentAsset.make(from: makeImage())
        )
        
        let viewModel = PreviewViewModel(
            repository: repository,
            imagePipeline: .shared,
            asset: asset
        )
        
        let recipientsLoaded = expectation(description: "friends loaded")
        
        viewModel.$recipients
            .dropFirst()
            .sink { recipients in
                if !recipients.isEmpty {
                    recipientsLoaded.fulfill()
                }
            }
            .store(in: &cancellables)
        
        await fulfillment(of: [recipientsLoaded], timeout: 1)
        
        viewModel.caption = "Sent from tests"
        
        let sent = expectation(description: "moment sent")
        
        viewModel.send { result in
            switch result {
            case .success(let moment):
                XCTAssertEqual(moment.caption, "Sent from tests")
            case .failure:
                XCTFail("Expected successful send")
            }
            sent.fulfill()
        }
        
        await fulfillment(of: [sent], timeout: 2)
    }
}
