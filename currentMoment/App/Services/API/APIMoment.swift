import Foundation

struct APIMoment: Codable {
    let id: String
    let sender: APISender
    let imageURL: String
    let caption: String?
    let isLivePhoto: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case sender
        case imageURL = "image_url"
        case caption
        case isLivePhoto = "is_live_photo"
        case createdAt = "created_at"
    }
}

struct APISender: Codable {
    let id: String
    let username: String?
    let fullName: String?
    let avatarURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case fullName = "full_name"
        case avatarURL = "avatar_url"
    }
}
