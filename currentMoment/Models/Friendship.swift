import Foundation

enum FriendshipStatus: String, Codable, Hashable, Sendable {
    case pending
    case accepted
    case blocked
}

struct Friendship: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let requesterId: String
    let receiverId: String
    let status: FriendshipStatus
    let createdAt: Date
}
