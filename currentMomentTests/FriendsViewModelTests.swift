import XCTest
import Combine
@testable import currentMoment

final class FriendsViewModelTests: XCTestCase {
    
    var cancellables = Set<AnyCancellable>()
    
    @MainActor
    func testSearchShowsSuggestionsAndAddFriendMovesUserToFriends() async throws {
        let repository = MockCurrentMomentRepository(
            widgetService: TestCurrentMomentWidgetService(),
            rootURL: try makeTemporaryDirectory()
        )
        
        await repository.loadInitialState()
        try await repository.signInDemoUser()
        
        let viewModel = FriendsViewModel(repository: repository)
        
        let suggestionsLoaded = expectation(description: "suggestions")
        
        viewModel.$suggestions
            .dropFirst()
            .sink { users in
                if users.contains(where: { $0.id == "user-jules" }) {
                    suggestionsLoaded.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.updateSearchText("jules")
        
        await fulfillment(of: [suggestionsLoaded], timeout: 2)
        
        let user = try XCTUnwrap(
            viewModel.suggestions.first(where: { $0.id == "user-jules" })
        )
        
        let friendsUpdated = expectation(description: "friend added")
        
        viewModel.$friends
            .dropFirst()
            .sink { friends in
                if friends.contains(where: { $0.id == "user-jules" }) {
                    friendsUpdated.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.addFriend(user)
        
        await fulfillment(of: [friendsUpdated], timeout: 2)
    }
}
