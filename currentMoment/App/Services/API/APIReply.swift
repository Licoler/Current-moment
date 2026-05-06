import Foundation

struct APIReply: Codable {
    let id: String
    let content: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, content
        case createdAt = "created_at"
    }
}
