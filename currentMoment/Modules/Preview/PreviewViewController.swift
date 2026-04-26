import Combine
import UIKit

final class PreviewViewController: UIViewController {

    private let viewModel: PreviewViewModel
    private var cancellables: Set<AnyCancellable> = []

    private enum Section { case recipients }
    private var dataSource: UICollectionViewDiffableDataSource<Section, User>?

    private let closeButton       = IconCircleButton(symbol: "xmark")
    private let downloadButton    = IconCircleButton(symbol: "arrow.down.to.line")
    private let titleLabel        = UILabel()
    private let imageCard         = CardContainerView(cornerRadius: 30)
    private let imageView         = UIImageView()
    private let captionContainer  = CardContainerView(cornerRadius: 22)
    private let captionTextView   = UITextView()
    private let captionPlaceholder = UILabel()
    private let sendButton        = PrimaryButton(title: "Send moment", imageSystemName: "paperplane.fill")
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: Self.makeRecipientsLayout())
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.register(PreviewRecipientCell.self, forCellWithReuseIdentifier: PreviewRecipientCell.reuseIdentifier)
        return cv
    }()

    var onDismiss: (() -> Void)?
    var onMomentSent: ((Moment) -> Void)?

    init(viewModel: PreviewViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CMColor.background
        setupViews()
        configureDataSource()
        bindViewModel()
    }

    private func setupViews() {
        titleLabel.text = "Preview"
        titleLabel.font = CMTypography.headline
        titleLabel.textColor = CMColor.textPrimary

        imageView.image = viewModel.asset.previewImage
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        captionTextView.backgroundColor = .clear
        captionTextView.font = CMTypography.body
        captionTextView.textColor = CMColor.textPrimary
        captionTextView.delegate = self
        captionTextView.textContainerInset = UIEdgeInsets(top: 14, left: 0, bottom: 14, right: 0)

        captionPlaceholder.text = "Add a caption"
        captionPlaceholder.font = CMTypography.body
        captionPlaceholder.textColor = CMColor.textTertiary

        activityIndicator.hidesWhenStopped = true

        view.addSubview(closeButton)
        view.addSubview(downloadButton)
        view.addSubview(titleLabel)
        view.addSubview(imageCard)
        view.addSubview(collectionView)
        view.addSubview(captionContainer)
        view.addSubview(sendButton)
        view.addSubview(activityIndicator)

        imageCard.addSubview(imageView)
        captionContainer.addSubview(captionTextView)
        captionContainer.addSubview(captionPlaceholder)

        closeButton.addTarget(self, action: #selector(handleCloseTap), for: .touchUpInside)
        downloadButton.addTarget(self, action: #selector(handleDownloadTap), for: .touchUpInside)
        sendButton.addTarget(self, action: #selector(handleSendTap), for: .touchUpInside)

        [closeButton, downloadButton, titleLabel, imageCard, imageView,
         collectionView, captionContainer, captionTextView, captionPlaceholder,
         sendButton, activityIndicator].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            downloadButton.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            downloadButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),

            imageCard.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 20),
            imageCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            imageCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            imageCard.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.45),

            imageView.topAnchor.constraint(equalTo: imageCard.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: imageCard.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: imageCard.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: imageCard.trailingAnchor),

            collectionView.topAnchor.constraint(equalTo: imageCard.bottomAnchor, constant: 22),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.heightAnchor.constraint(equalToConstant: 106),

            captionContainer.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 18),
            captionContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            captionContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            captionContainer.heightAnchor.constraint(equalToConstant: 112),

            captionTextView.topAnchor.constraint(equalTo: captionContainer.topAnchor),
            captionTextView.bottomAnchor.constraint(equalTo: captionContainer.bottomAnchor),
            captionTextView.leadingAnchor.constraint(equalTo: captionContainer.leadingAnchor, constant: 16),
            captionTextView.trailingAnchor.constraint(equalTo: captionContainer.trailingAnchor, constant: -16),

            captionPlaceholder.leadingAnchor.constraint(equalTo: captionContainer.leadingAnchor, constant: 20),
            captionPlaceholder.topAnchor.constraint(equalTo: captionContainer.topAnchor, constant: 18),

            sendButton.topAnchor.constraint(equalTo: captionContainer.bottomAnchor, constant: 18),
            sendButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            sendButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            sendButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -18),
            sendButton.heightAnchor.constraint(equalToConstant: 56),

            activityIndicator.centerYAnchor.constraint(equalTo: sendButton.centerYAnchor),
            activityIndicator.trailingAnchor.constraint(equalTo: sendButton.trailingAnchor, constant: -18)
        ])
    }

    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, User>(collectionView: collectionView) { [weak self] collectionView, indexPath, user in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PreviewRecipientCell.reuseIdentifier, for: indexPath) as! PreviewRecipientCell
            cell.configure(with: user, isSelected: self?.viewModel.isSelected(user) ?? false)
            return cell
        }
        collectionView.delegate = self
    }

    private func bindViewModel() {
        viewModel.$recipients
            .receive(on: DispatchQueue.main)
            .sink { [weak self] recipients in
                var snapshot = NSDiffableDataSourceSnapshot<Section, User>()
                snapshot.appendSections([.recipients])
                snapshot.appendItems(recipients, toSection: .recipients)
                self?.dataSource?.apply(snapshot, animatingDifferences: true)
            }
            .store(in: &cancellables)

        viewModel.$selectedRecipientIDs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                var snapshot = NSDiffableDataSourceSnapshot<Section, User>()
                snapshot.appendSections([.recipients])
                snapshot.appendItems(self.viewModel.recipients, toSection: .recipients)
                self.dataSource?.apply(snapshot, animatingDifferences: true)
            }
            .store(in: &cancellables)

        viewModel.$isSending
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSending in
                self?.sendButton.isEnabled = !isSending
                isSending ? self?.activityIndicator.startAnimating() : self?.activityIndicator.stopAnimating()
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let message else { return }
                let alert = UIAlertController(title: "Send failed", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            }
            .store(in: &cancellables)
    }

    @objc private func handleCloseTap() { onDismiss?() }
    @objc private func handleDownloadTap() {
        UIImageWriteToSavedPhotosAlbum(viewModel.asset.previewImage, nil, nil, nil)
        let alert = UIAlertController(title: "Saved", message: "Photo saved to library", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    @objc private func handleSendTap() {
        viewModel.send { [weak self] result in
            guard case let .success(moment) = result else { return }
            self?.onMomentSent?(moment)
        }
    }

    private static func makeRecipientsLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(82), heightDimension: .absolute(98))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .estimated(82), heightDimension: .absolute(98))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = 12
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4)
        return UICollectionViewCompositionalLayout(section: section)
    }
}

extension PreviewViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let user = dataSource?.itemIdentifier(for: indexPath) else { return }
        viewModel.toggleRecipient(user)
    }
}

extension PreviewViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        viewModel.caption = textView.text
        captionPlaceholder.isHidden = !textView.text.isEmpty
    }
}
