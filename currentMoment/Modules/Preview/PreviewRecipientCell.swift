import UIKit

final class PreviewRecipientCell: UICollectionViewCell {
    static let reuseIdentifier = "PreviewRecipientCell"

    private let ringView   = UIView()
    private let avatarView = AvatarView()
    private let nameLabel  = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        ringView.layer.cornerRadius = 28
        ringView.layer.borderWidth  = 2
        ringView.layer.borderColor  = UIColor.clear.cgColor
        ringView.isUserInteractionEnabled = false

        nameLabel.font          = CMTypography.caption
        nameLabel.textColor     = CMColor.textPrimary
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 2

        [ringView, avatarView, nameLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            ringView.topAnchor.constraint(equalTo: contentView.topAnchor),
            ringView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            ringView.widthAnchor.constraint(equalToConstant: 56),
            ringView.heightAnchor.constraint(equalToConstant: 56),

            avatarView.centerXAnchor.constraint(equalTo: ringView.centerXAnchor),
            avatarView.centerYAnchor.constraint(equalTo: ringView.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 48),
            avatarView.heightAnchor.constraint(equalToConstant: 48),

            nameLabel.topAnchor.constraint(equalTo: ringView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with user: User, isSelected: Bool) {
        avatarView.configure(with: user, imagePipeline: .shared)
        nameLabel.text = user.displayName
        ringView.layer.borderColor = isSelected ? UIColor.white.cgColor : UIColor.clear.cgColor
        contentView.alpha = isSelected ? 1.0 : 0.66
    }
}
