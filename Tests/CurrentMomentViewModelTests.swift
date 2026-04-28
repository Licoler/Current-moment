import Combine
import XCTest
@testable import currentMoment

final class CameraViewModelTests: XCTestCase {
    @MainActor
    func testCaptureUsesDemoImageWhenCameraUnavailable() {
        let repository = MockCurrentMomentRepository(widgetService: TestCurrentMomentWidgetService())
        let viewModel = CameraViewModel(repository: repository)
        
        let expectation = expectation(description: "captured asset")
        viewModel.onCaptureAsset = { asset in
            XCTAssertFalse(asset.isLivePhoto)
            expectation.fulfill()
        }
        
        viewModel.captureMoment()
        wait(for: [expectation], timeout: 1)
    }
}

final class PreviewViewModelTests: XCTestCase {
    @MainActor
    func testSendCreatesMomentForSelectedRecipients() async throws {
        let repository = MockCurrentMomentRepository(
            widgetService: TestCurrentMomentWidgetService(),
            rootURL: try makeTemporaryDirectory()
        )
        await repository.loadInitialState()
        try await repository.signInDemoUser()
        
        let asset = try XCTUnwrap(CapturedMomentAsset.make(from: makeImage(), isLivePhoto: false))
        let viewModel = PreviewViewModel(repository: repository, imagePipeline: .shared, asset: asset)
        
        let recipientsLoaded = expectation(description: "friends loaded")
        let cancellable = viewModel.$recipients.dropFirst().sink { recipients in
            if !recipients.isEmpty {
                recipientsLoaded.fulfill()
            }
        }
        await fulfillment(of: [recipientsLoaded], timeout: 1)
        
        viewModel.caption = "Sent from tests"
        
        let sent = expectation(description: "moment sent")
        viewModel.send { result in
            if case let .success(moment) = result {
                XCTAssertEqual(moment.caption, "Sent from tests")
            } else {
                XCTFail("Expected successful send.")
            }
            sent.fulfill()
        }
        await fulfillment(of: [sent], timeout: 2)
        _ = cancellable
    }
}

final class FriendsViewModelTests: XCTestCase {
    @MainActor
    func testSearchShowsSuggestionsAndAddFriendMovesUserToFriends() async throws {
        let repository = MockCurrentMomentRepository(
            widgetService: TestCurrentMomentWidgetService(),
            rootURL: try makeTemporaryDirectory()
        )
        await repository.loadInitialState()
        try await repository.signInDemoUser()
        
        let viewModel = FriendsViewModel(repository: repository)
        viewModel.updateSearchText("jules")
        
        let suggestionsLoaded = expectation(description: "suggestions")
        let cancellable = viewModel.$suggestions.dropFirst().sink { users in
            if users.contains(where: { $0.id == "user-jules" }) {
                suggestionsLoaded.fulfill()
            }
        }
        await fulfillment(of: [suggestionsLoaded], timeout: 2)
        
        let user = try XCTUnwrap(viewModel.suggestions.first(where: { $0.id == "user-jules" }))
        viewModel.addFriend(user)
        
        let friendsUpdated = expectation(description: "friend added")
        let friendsCancellable = viewModel.$friends.dropFirst().sink { friends in
            if friends.contains(where: { $0.id == "user-jules" }) {
                friendsUpdated.fulfill()
            }
        }
        await fulfillment(of: [friendsUpdated], timeout: 2)
        _ = cancellable
        _ = friendsCancellable
    }
}

final class ProfileViewModelTests: XCTestCase {
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
        let cancellable = viewModel.$stats.dropFirst().sink { stats in
            if stats.photosSent >= 1 {
                profileLoaded.fulfill()
            }
        }
        await fulfillment(of: [profileLoaded], timeout: 1)
        
        XCTAssertGreaterThanOrEqual(viewModel.stats.photosSent, 1)
        XCTAssertGreaterThanOrEqual(viewModel.stats.friendsCount, 4)
        XCTAssertNotNil(viewModel.user)
        _ = cancellable
    }
}
