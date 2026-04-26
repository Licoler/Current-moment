import Foundation

struct WidgetMomentSnapshot: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let momentId: String
    let username: String
    let imageURL: String
    let thumbnailURL: String?
    let deepLink: String
}
