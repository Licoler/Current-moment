import UIKit

final class ProfileGridCell: UICollectionViewCell {
    static let reuseIdentifier = "ProfileGridCell"

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with moment: Moment, imagePipeline: ImagePipeline = .shared) {
        imageView.image = nil
        Task { @MainActor in
            let url = moment.thumbnailURL ?? moment.imageURL
            let image = await imagePipeline.image(for: url)
            imageView.image = image
        }
    }
}
