import UIKit

final class AvatarView: UIView {
    private let imageView = UIImageView()
    private let initialsLabel = UILabel()
    private var currentUserID: String?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 18
        layer.cornerCurve = .continuous
        clipsToBounds = true
        backgroundColor = UIColor(hex: "#A855F7") ?? .systemPurple
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        initialsLabel.font = CMTypography.bodySemibold
        initialsLabel.textAlignment = .center
        initialsLabel.textColor = CMColor.textPrimary
        
        addSubview(imageView)
        addSubview(initialsLabel)
        imageView.pinEdges(to: self)
        initialsLabel.pinEdges(to: self)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with user: User, imagePipeline: ImagePipeline? = nil) {
        currentUserID = user.id
        initialsLabel.text = user.initials
        imageView.image = nil
        
        let colors = [
            UIColor(hex: "#A855F7") ?? .systemPurple,
            UIColor(hex: "#EC4899") ?? .systemPink,
            UIColor(hex: "#F97316") ?? .systemOrange,
            UIColor(hex: "#3B82F6") ?? .systemBlue,
            UIColor(hex: "#22C55E") ?? .systemGreen
        ]
        backgroundColor = colors[abs(user.id.hashValue) % colors.count]
        
        guard let imagePipeline else {
            return
        }
        
        Task { [weak self] in
            let image = await imagePipeline.image(for: user.avatarURL)
            await MainActor.run {
                guard self?.currentUserID == user.id else { return }
                self?.imageView.image = image
                self?.initialsLabel.isHidden = image != nil
            }
        }
    }
}
