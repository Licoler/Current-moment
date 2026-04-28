import UIKit

final class FriendTableViewCell: UITableViewCell {
    
    static let reuseIdentifier = "FriendTableViewCell"
    
    // MARK: - UI
    
    private let cardView = CardContainerView(cornerRadius: 22)
    private let avatarView = AvatarView()
    private let nameLabel = UILabel()
    private let usernameLabel = UILabel()
    private let actionButton = UIButton(type: .system)
    
    private var currentUser: User?
    private var actionHandler: ((User) -> Void)?
    
    // MARK: - Init
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        
        nameLabel.font = CMTypography.bodySemibold
        nameLabel.textColor = CMColor.textPrimary
        
        usernameLabel.font = CMTypography.footnote
        usernameLabel.textColor = CMColor.textSecondary
        
        var buttonConfig = UIButton.Configuration.filled()
        buttonConfig.cornerStyle = .capsule
        buttonConfig.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14)
        buttonConfig.baseBackgroundColor = .white
        buttonConfig.baseForegroundColor = .black
        buttonConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var attrs = attrs
            attrs.font = CMTypography.footnote
            return attrs
        }
        actionButton.configuration = buttonConfig
        actionButton.enableScaleFeedback()
        actionButton.addTarget(self, action: #selector(handleActionTap), for: .touchUpInside)
        
        let textStack = UIStackView(arrangedSubviews: [nameLabel, usernameLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        
        let rowStack = UIStackView(arrangedSubviews: [avatarView, textStack, UIView(), actionButton])
        rowStack.axis = .horizontal
        rowStack.alignment = .center
        rowStack.spacing = 14
        
        cardView.addSubview(rowStack)
        contentView.addSubview(cardView)
        
        [cardView, rowStack, avatarView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            
            rowStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            rowStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            rowStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            rowStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14),
            
            avatarView.widthAnchor.constraint(equalToConstant: 52),
            avatarView.heightAnchor.constraint(equalToConstant: 52)
        ])
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Configure
    
    func configure(with user: User, isFriend: Bool, actionHandler: @escaping (User) -> Void) {
        currentUser = user
        self.actionHandler = actionHandler
        avatarView.configure(with: user, imagePipeline: .shared)
        nameLabel.text = user.displayName
        usernameLabel.text = "@\(user.username)"
        
        actionButton.configuration?.title = isFriend ? "Remove" : "Add"
        actionButton.configuration?.baseBackgroundColor = isFriend ? UIColor.white.withAlphaComponent(0.12) : .white
        actionButton.configuration?.baseForegroundColor = isFriend ? .white : .black
    }
    
    @objc private func handleActionTap() {
        guard let currentUser else { return }
        actionHandler?(currentUser)
    }
}
