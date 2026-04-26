import Foundation

struct Moment: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let senderId: String
    let recipientIds: [String]
    let imageURL: String
    let caption: String
    let createdAt: Date
    let thumbnailURL: String?
    let senderName: String
    let isLivePhoto: Bool
}

struct MomentDraft: Sendable {
    let imageData: Data
    let thumbnailData: Data
    let caption: String
    let recipientIds: [String]
    let isLivePhoto: Bool
}
