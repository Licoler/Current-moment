import XCTest
import Combine
@testable import currentMoment

final class CurrentMomentRepositoryTests: XCTestCase {
    
    var cancellables = Set<AnyCancellable>()
    
    func testDemoSignInSendMomentAndWidgetReload() async throws {
        let widgetService = TestCurrentMomentWidgetService()
        let rootURL = try makeTemporaryDirectory()
        let repository = MockCurrentMomentRepository(
            widgetService: widgetService,
            rootURL: rootURL
        )
        
        await repository.loadInitialState()
        try await repository.signInDemoUser()
        
        let image = makeImage()
        let data = try XCTUnwrap(image.jpegData(compressionQuality: 0.9))
        
        let draft = MomentDraft(
            imageData: data,
            thumbnailData: data,
            caption: "Test moment",
            recipientIds: ["user-lena"],
            isLivePhoto: false
        )
        
        let sentMoment = try await repository.sendMoment(draft)
        
        XCTAssertEqual(sentMoment.caption, "Test moment")
        XCTAssertFalse(sentMoment.imageURL.isEmpty)
        XCTAssertEqual(
            widgetService.syncedSnapshots.last?.first?.momentId,
            sentMoment.id
        )
    }
    
    func testAddAndRemoveFriendUpdatesFriendsPublisher() async throws {
        let repository = MockCurrentMomentRepository(
            widgetService: TestCurrentMomentWidgetService(),
            rootURL: try makeTemporaryDirectory()
        )
        
        await repository.loadInitialState()
        try await repository.signInDemoUser()
        
        var latestFriends: [User] = []
        
        repository.friendsPublisher
            .sink { latestFriends = $0 }
            .store(in: &cancellables)
        
        try await repository.addFriend("user-jules")
        XCTAssertTrue(latestFriends.contains { $0.id == "user-jules" })
        
        try await repository.removeFriend("user-jules")
        XCTAssertFalse(latestFriends.contains { $0.id == "user-jules" })
    }
}
