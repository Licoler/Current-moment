import Foundation

struct APIUser: Codable {
    let id: String
    let username: String
    let fullName: String
    let email: String?
    let avatarURL: String?
    let bio: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case fullName = "full_name"
        case email
        case avatarURL = "avatar_url"
        case bio
        case createdAt = "created_at"
    }
}
