import Combine
import Foundation
import UIKit
import UserNotifications

protocol CurrentMomentNotificationServiceProtocol: AnyObject {
    func configure() async
    func deleteMoment(_ momentId: String) async throws
}

final class CurrentMomentNotificationService: NSObject, CurrentMomentNotificationServiceProtocol {
    func deleteMoment(_ momentId: String) async throws {
        print("")
    }
    
    private let repository: CurrentMomentRepositoryProtocol
    private var cancellables: Set<AnyCancellable> = []
    private var seenMomentIDs: Set<String> = []
    private var isPrimed = false

    init(repository: CurrentMomentRepositoryProtocol) {
        self.repository = repository
        super.init()
    }

    func configure() async {
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        do {
            _ = try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            #if DEBUG
            print("Local notification authorization failed: \(error)")
            #endif
        }

        repository.momentsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] moments in
                self?.handleIncoming(moments: moments)
            }
            .store(in: &cancellables)
    }

    private func handleIncoming(moments: [Moment]) {
        guard let currentUser = repository.currentUser() else {
            seenMomentIDs.removeAll()
            isPrimed = false
            return
        }

        let incomingMoments = moments.filter { $0.senderId != currentUser.id }
        if !isPrimed {
            incomingMoments.forEach { seenMomentIDs.insert($0.id) }
            isPrimed = true
            return
        }

        let freshMoments = incomingMoments.filter { !seenMomentIDs.contains($0.id) }
        incomingMoments.forEach { seenMomentIDs.insert($0.id) }

        guard let latest = freshMoments.first else { return }

        let content = UNMutableNotificationContent()
        content.title = latest.senderName
        content.body = latest.caption.isEmpty ? "Sent you a new moment." : latest.caption
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: latest.id,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        UNUserNotificationCenter.current().add(request)
    }
}

extension CurrentMomentNotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
