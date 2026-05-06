import Foundation

extension APIUser {
    func toDomainUser() -> User {
        User(
            id: self.id,
            username: self.username,
            fullName: self.fullName,
            email: self.email,
            avatarURL: self.avatarURL,
            friendIDs: [],
            createdAt: self.createdAt,
            friendsCount: 0
        )
    }
}

extension APIMoment {
    func toDomainMoment() -> Moment {
        Moment(
            id: self.id,
            senderId: self.sender.id,
            recipientIds: [],
            imageURL: self.imageURL,
            caption: self.caption ?? "",
            createdAt: self.createdAt,
            thumbnailURL: nil,
            senderName: self.sender.fullName ?? self.sender.username ?? "",
            isLivePhoto: self.isLivePhoto
        )
    }
}
