import UIKit

final class ProfileHeaderView: UIView {
    
    private let avatarView = AvatarView()
    private let nameLabel = UILabel()
    private let usernameLabel = UILabel()
    private let editButton = UIButton(type: .system)
    private let statsStack = UIStackView()
    
    private let sentCard = StatCardView(value: "0", title: "Photos")
    private let friendsCard = StatCardView(value: "0", title: "Friends")
    private let streakCard = StatCardView(value: "0", title: "Streak")
    
    var onEditTap: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func setup() {
        backgroundColor = .clear
        
        nameLabel.font = CMTypography.title
        nameLabel.textColor = CMColor.textPrimary
        nameLabel.textAlignment = .center
        
        usernameLabel.font = CMTypography.body
        usernameLabel.textColor = CMColor.textSecondary
        usernameLabel.textAlignment = .center
        
        var cfg = UIButton.Configuration.plain()
        cfg.title = "Edit profile"
        cfg.baseForegroundColor = CMColor.textPrimary
        editButton.configuration = cfg
        editButton.enableScaleFeedback()
        editButton.addTarget(self, action: #selector(handleEdit), for: .touchUpInside)
        
        statsStack.axis = .horizontal
        statsStack.alignment = .fill
        statsStack.distribution = .fillEqually
        statsStack.spacing = 12
        statsStack.addArrangedSubview(sentCard)
        statsStack.addArrangedSubview(friendsCard)
        statsStack.addArrangedSubview(streakCard)
        
        [avatarView, nameLabel, usernameLabel, editButton, statsStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            avatarView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            avatarView.centerXAnchor.constraint(equalTo: centerXAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 120),
            avatarView.heightAnchor.constraint(equalToConstant: 120),
            
            nameLabel.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            
            usernameLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            usernameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            usernameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            
            editButton.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 12),
            editButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            statsStack.topAnchor.constraint(equalTo: editButton.bottomAnchor, constant: 18),
            statsStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            statsStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            statsStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            
            sentCard.heightAnchor.constraint(equalToConstant: 110)
        ])
    }
    
    @objc private func handleEdit() { onEditTap?() }
    
    func configure(with user: User?, stats: ProfileStats?, imagePipeline: ImagePipeline = .shared) {
        if let user {
            avatarView.configure(with: user, imagePipeline: imagePipeline)
            nameLabel.text = user.displayName
            usernameLabel.text = "@\(user.username)"
        } else {
            nameLabel.text = ""
            usernameLabel.text = ""
        }
        
        if let stats {
            sentCard.update(value: "\(stats.photosSent)", title: "Photos")
            friendsCard.update(value: "\(stats.friendsCount)", title: "Friends")
            streakCard.update(value: "\(stats.streakDays)", title: "Streak days")
        }
    }
}
