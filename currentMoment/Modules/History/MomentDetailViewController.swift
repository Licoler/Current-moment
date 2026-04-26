import UIKit

final class MomentDetailViewController: UIViewController {

    private let moment:        Moment
    private let imagePipeline: ImagePipeline

    // MARK: - UI

    private let backButton    = IconCircleButton(symbol: "chevron.left")
    private let imageView     = UIImageView()
    private let senderLabel   = UILabel()
    private let dateLabel     = UILabel()
    private let captionLabel  = UILabel()

    // MARK: - Callbacks

    var onBack: (() -> Void)?

    // MARK: - Init

    init(moment: Moment, imagePipeline: ImagePipeline) {
        self.moment        = moment
        self.imagePipeline = imagePipeline
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CMColor.background
        setupViews()
        loadImage()
    }

    // MARK: - Setup

    private func setupViews() {
        imageView.contentMode    = .scaleAspectFill
        imageView.clipsToBounds  = true
        imageView.layer.cornerRadius    = 30
        imageView.layer.cornerCurve     = .continuous
        imageView.backgroundColor       = CMColor.cardElevated

        senderLabel.font      = CMTypography.title2
        senderLabel.textColor = CMColor.textPrimary
        senderLabel.text      = moment.senderName

        dateLabel.font      = CMTypography.footnote
        dateLabel.textColor = CMColor.textSecondary
        dateLabel.text      = moment.createdAt.dayMonthDescription()

        captionLabel.font          = CMTypography.body
        captionLabel.textColor     = CMColor.textSecondary
        captionLabel.numberOfLines = 0
        captionLabel.text          = moment.caption

        backButton.addTarget(self, action: #selector(handleBackTap), for: .touchUpInside)

        [backButton, imageView, senderLabel, dateLabel, captionLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            imageView.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 18),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            imageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.48),

            senderLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            senderLabel.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            senderLabel.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),

            dateLabel.topAnchor.constraint(equalTo: senderLabel.bottomAnchor, constant: 6),
            dateLabel.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),

            captionLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 16),
            captionLabel.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            captionLabel.trailingAnchor.constraint(equalTo: imageView.trailingAnchor)
        ])
    }

    // MARK: - Image loading

    private func loadImage() {
        Task { [weak self] in
            guard let self else { return }
            let image = await self.imagePipeline.image(for: self.moment.imageURL)
            await MainActor.run { self.imageView.image = image }
        }
    }

    @objc private func handleBackTap() { onBack?() }
}
