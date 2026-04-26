import Foundation
import UIKit
import XCTest
@testable import currentMoment

final class TestCurrentMomentWidgetService: CurrentMomentWidgetServiceProtocol {
    private(set) var syncedSnapshots: [[WidgetMomentSnapshot]] = []

    func syncSnapshots(moments: [Moment], users: [User], currentUser: User?) async {
        guard let currentUser else {
            syncedSnapshots.append([])
            return
        }

        let userIndex = Dictionary(uniqueKeysWithValues: users.map { ($0.id, $0) })
        let snapshots = moments
            .filter { $0.senderId != currentUser.id }
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(4)
            .compactMap { moment -> WidgetMomentSnapshot? in
                guard let sender = userIndex[moment.senderId] else { return nil }
                return WidgetMomentSnapshot(
                    id: sender.id,
                    momentId: moment.id,
                    username: sender.displayName,
                    imageURL: moment.imageURL,
                    thumbnailURL: moment.thumbnailURL,
                    deepLink: "currentmoment://history/\(moment.id)"
                )
            }

        syncedSnapshots.append(Array(snapshots))
    }
}

extension XCTestCase {
    func makeImage(color: UIColor = .orange) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 120, height: 120))
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: CGSize(width: 120, height: 120)))
        }
    }

    func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
