import Foundation

struct User: Identifiable, Codable, Hashable, Sendable {
    let id: String
    var username: String
    var fullName: String
    var email: String?
    var avatarURL: String?
    var friendIDs: [String]
    let createdAt: Date
    var friendsCount: Int
    
    init(
        id: String,
        username: String,
        fullName: String,
        email: String? = nil,
        avatarURL: String? = nil,
        friendIDs: [String] = [],
        createdAt: Date = .now,
        friendsCount: Int = 0
    ) {
        self.id = id
        self.username = username
        self.fullName = fullName
        self.email = email
        self.avatarURL = avatarURL
        self.friendIDs = friendIDs
        self.createdAt = createdAt
        self.friendsCount = friendsCount
    }
    
    var displayName: String {
        fullName.isEmpty ? username : fullName
    }
    
    var initials: String {
        let source = fullName.isEmpty ? username : fullName
        let components = source
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
        
        let value = String(components)
        return value.isEmpty ? String(source.prefix(1)).uppercased() : value.uppercased()
    }
    
    func applying(friendIDs: [String]) -> User {
        var updated = self
        updated.friendIDs = friendIDs
        updated.friendsCount = friendIDs.count
        return updated
    }
}
