import Combine
import Foundation

struct ProfileStats {
    let photosSent: Int
    let friendsCount: Int
    let streakDays: Int
}

@MainActor
final class ProfileViewModel {
    @Published private(set) var user: User?
    @Published private(set) var stats = ProfileStats(photosSent: 0, friendsCount: 0, streakDays: 0)
    @Published private(set) var isSaving = false
    @Published private(set) var errorMessage: String?

    private let repository: CurrentMomentRepositoryProtocol
    private var allMoments: [Moment] = []
    private var cancellables: Set<AnyCancellable> = []

    init(repository: CurrentMomentRepositoryProtocol) {
        self.repository = repository

        repository.sessionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.user = user
                self?.recalculateStats()
            }
            .store(in: &cancellables)

        repository.momentsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] moments in
                self?.allMoments = moments
                self?.recalculateStats()
            }
            .store(in: &cancellables)
    }

    func saveProfile(fullName: String, username: String) {
        guard !isSaving else { return }
        isSaving = true
        errorMessage = nil

        Task {
            do {
                try await repository.updateProfile(fullName: fullName, username: username, avatarURL: nil)
                isSaving = false
            } catch {
                isSaving = false
                errorMessage = error.localizedDescription
            }
        }
    }

    func logout(completion: @escaping () -> Void) {
        Task {
            do {
                try await repository.signOut()
                completion()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func recalculateStats() {
        guard let user else {
            stats = ProfileStats(photosSent: 0, friendsCount: 0, streakDays: 0)
            return
        }

        let sentMoments = allMoments.filter { $0.senderId == user.id }
        stats = ProfileStats(
            photosSent: sentMoments.count,
            friendsCount: user.friendsCount,
            streakDays: streakDays(from: sentMoments.map(\.createdAt))
        )
    }

    private func streakDays(from dates: [Date]) -> Int {
        let calendar = Calendar.current
        let uniqueDays = Set(dates.map { calendar.startOfDay(for: $0) }).sorted(by: >)
        guard let firstDay = uniqueDays.first else { return 0 }

        var streak = 0
        var currentDay = calendar.startOfDay(for: .now)

        while currentDay >= firstDay && uniqueDays.contains(currentDay) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: currentDay) else { break }
            currentDay = previous
        }
        return streak
    }
}
