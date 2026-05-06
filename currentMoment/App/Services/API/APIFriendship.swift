import Foundation

struct APIFriendship: Codable {
    let id: String
    let requester: APIUserRef
    let receiver: APIUserRef
    let status: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, requester, receiver, status
        case createdAt = "created_at"
    }
}

struct APIUserRef: Codable {
    let id: String
    let username: String
    let fullName: String

    enum CodingKeys: String, CodingKey {
        case id, username
        case fullName = "full_name"
    }
}
