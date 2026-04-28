import UIKit

final class MomentDetailViewController: UIViewController {

    private let moment:        Moment
    private let imagePipeline: ImagePipeline

    // MARK: - UI

    private let backButton     = IconCircleButton(symbol: "chevron.left")
    private let shareButton    = IconCircleButton(symbol: "square.and.arrow.up")
    private let downloadButton = IconCircleButton(symbol: "arrow.down.to.line")

    private let scrollView    = UIScrollView()
    private let contentStack  = UIStackView()

    private let imageView     = UIImageView()
    private let senderLabel   = UILabel()
    private let dateLabel     = UILabel()
    private let captionCard   = UIView()
    private let captionLabel  = UILabel()

    var onBack: (() -> Void)?

    // MARK: - Init

    init(moment: Moment, imagePipeline: ImagePipeline) {
        self.moment        = moment
        self.imagePipeline = imagePipeline
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CMColor.background
        setupViews()
        loadImage()
    }

    // MARK: - Setup

    private func setupViews() {
        // Image view
        imageView.contentMode   = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius   = 28
        imageView.layer.cornerCurve    = .continuous
        imageView.backgroundColor      = CMColor.cardElevated

        // Sender info
        senderLabel.font      = CMTypography.title2
        senderLabel.textColor = CMColor.textPrimary
        senderLabel.text      = moment.senderName

        dateLabel.font      = CMTypography.footnote
        dateLabel.textColor = CMColor.textSecondary
        dateLabel.text      = moment.createdAt.dayMonthDescription()

        // Caption card (показываем только если есть текст)
        captionCard.backgroundColor    = CMColor.cardElevated
        captionCard.layer.cornerRadius = 20
        captionCard.layer.cornerCurve  = .continuous
        captionCard.isHidden           = moment.caption.isEmpty

        captionLabel.font          = CMTypography.body
        captionLabel.textColor     = CMColor.textPrimary
        captionLabel.numberOfLines = 0
        captionLabel.text          = moment.caption

        captionCard.addSubview(captionLabel)
        captionLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            captionLabel.topAnchor.constraint(equalTo: captionCard.topAnchor, constant: 16),
            captionLabel.leadingAnchor.constraint(equalTo: captionCard.leadingAnchor, constant: 16),
            captionLabel.trailingAnchor.constraint(equalTo: captionCard.trailingAnchor, constant: -16),
            captionLabel.bottomAnchor.constraint(equalTo: captionCard.bottomAnchor, constant: -16)
        ])

        // Meta row
        let metaStack = UIStackView(arrangedSubviews: [senderLabel, dateLabel])
        metaStack.axis    = .vertical
        metaStack.spacing = 4

        // Content stack
        contentStack.axis    = .vertical
        contentStack.spacing = 18
        contentStack.addArrangedSubview(imageView)
        contentStack.addArrangedSubview(metaStack)
        if !moment.caption.isEmpty { contentStack.addArrangedSubview(captionCard) }

        scrollView.addSubview(contentStack)
        view.addSubview(backButton)
        view.addSubview(shareButton)
        view.addSubview(downloadButton)
        view.addSubview(scrollView)

        // Constraints
        [backButton, shareButton, downloadButton, scrollView, contentStack, imageView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        backButton.addTarget(self,     action: #selector(handleBackTap),     for: .touchUpInside)
        shareButton.addTarget(self,    action: #selector(handleShareTap),    for: .touchUpInside)
        downloadButton.addTarget(self, action: #selector(handleDownloadTap), for: .touchUpInside)

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            shareButton.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            shareButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            downloadButton.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            downloadButton.trailingAnchor.constraint(equalTo: shareButton.leadingAnchor, constant: -10),

            scrollView.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),

            // Квадратное фото
            imageView.widthAnchor.constraint(equalTo: contentStack.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor)
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

    // MARK: - Actions

    @objc private func handleBackTap() {
        onBack?()
    }

    @objc private func handleDownloadTap() {
        guard let image = imageView.image else { return }
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(imageSaved(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    @objc private func handleShareTap() {
        guard let image = imageView.image else { return }
        let items: [Any] = [image]
        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        present(vc, animated: true)
    }

    @objc private func imageSaved(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        let title   = error == nil ? "Saved" : "Error"
        let message = error == nil ? "Photo saved to library." : error?.localizedDescription
        let alert   = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
