import UIKit

final class MomentGridCell: UICollectionViewCell {
    
    static let reuseIdentifier = "MomentGridCell"
    
    private let imageView = UIImageView()
    private let gradientView = UIView()
    private let senderLabel = UILabel()
    private let dateLabel = UILabel()
    private var gradientLayer: CAGradientLayer?
    
    private var representedMomentID: String?
    
    private let mockImageNames = ["mockOne", "mockTwo", "mockThree", "mockFour", "mockFive"]
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.layer.cornerRadius = 24
        contentView.layer.cornerCurve = .continuous
        contentView.clipsToBounds = true
        contentView.backgroundColor = UIColor(white: 0.15, alpha: 1)
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        let gl = CAGradientLayer()
        gl.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.82).cgColor]
        gl.locations = [0.48, 1]
        gradientView.layer.addSublayer(gl)
        gradientLayer = gl
        
        senderLabel.font = CMTypography.footnote
        senderLabel.textColor = CMColor.textPrimary
        
        dateLabel.font = CMTypography.caption
        dateLabel.textColor = CMColor.textSecondary
        
        [imageView, gradientView, senderLabel, dateLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            gradientView.topAnchor.constraint(equalTo: contentView.topAnchor),
            gradientView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            gradientView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            senderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            senderLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            senderLabel.bottomAnchor.constraint(equalTo: dateLabel.topAnchor, constant: -3),
            
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            dateLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer?.frame = gradientView.bounds
    }
    
    func configure(with moment: Moment) {
        representedMomentID = moment.id
        senderLabel.text = moment.senderName
        dateLabel.text = moment.createdAt.shortRelativeDescription()
        
        let mockIndex = abs(moment.id.hashValue) % mockImageNames.count
        let mockImage = UIImage(named: mockImageNames[mockIndex])
        imageView.image = mockImage
        
        Task { [weak self] in
            let image = await ImagePipeline.shared.image(for: moment.thumbnailURL ?? moment.imageURL)
            await MainActor.run {
                guard self?.representedMomentID == moment.id else { return }
                if let img = image {
                    self?.imageView.image = img
                }
            }
        }
    }
}
