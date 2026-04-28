import Combine
import Foundation

@MainActor
final class HistoryViewModel {
    
    @Published private(set) var moments: [Moment] = []
    
    private let repository:   CurrentMomentRepositoryProtocol
    private var allMoments:   [Moment] = []
    private var visibleCount  = 18
    private var cancellables: Set<AnyCancellable> = []
    
    init(repository: CurrentMomentRepositoryProtocol) {
        self.repository = repository
        
        repository.momentsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] moments in
                guard let self else { return }
                self.allMoments   = moments.sorted { $0.createdAt > $1.createdAt }
                self.visibleCount = max(self.visibleCount, min(18, self.allMoments.count))
                self.moments      = Array(self.allMoments.prefix(self.visibleCount))
            }
            .store(in: &cancellables)
    }
    
    func loadMoreIfNeeded(currentIndex: Int) {
        guard currentIndex >= moments.count - 6 else { return }
        let nextCount = min(allMoments.count, visibleCount + 18)
        guard nextCount != visibleCount else { return }
        visibleCount = nextCount
        moments      = Array(allMoments.prefix(visibleCount))
    }
    
    func moment(with id: String) -> Moment? {
        allMoments.first { $0.id == id }
    }
}
