import Combine
import UIKit
import Photos

final class PreviewViewController: UIViewController {
    
    private let viewModel: PreviewViewModel
    private var cancellables = Set<AnyCancellable>()
    private var bottomConstraint: NSLayoutConstraint?
    private var isKeyboardVisible = false
    
    private enum Section { case recipients }
    private var dataSource: UICollectionViewDiffableDataSource<Section, User>?
    
    // MARK: - UI
    
    private let closeButton = makeCircleButton(symbol: "xmark")
    private let downloadButton = makeCircleButton(symbol: "arrow.down.to.line")
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Preview"
        label.font = CMTypography.headline
        label.textColor = CMColor.textPrimary
        return label
    }()
    
    private let imageCard: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.layer.cornerRadius = 24
        view.layer.cornerCurve = .continuous
        view.clipsToBounds = true
        return view
    }()
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    private let recipientBadge: UILabel = {
        let label = UILabel()
        label.font = CMTypography.caption
        label.textColor = .white
        label.textAlignment = .center
        label.backgroundColor = UIColor.black.withAlphaComponent(0.54)
        label.layer.cornerRadius = 12
        label.clipsToBounds = true
        label.isHidden = true
        return label
    }()
    
    private let captionContainer: UIView = {
        let view = UIView()
        view.backgroundColor = CMColor.cardElevated
        view.layer.cornerRadius = 22
        view.layer.cornerCurve = .continuous
        view.clipsToBounds = true
        return view
    }()
    
    private let captionTextView: UITextView = {
        let tv = UITextView()
        tv.backgroundColor = .clear
        tv.font = CMTypography.body
        tv.textColor = CMColor.textPrimary
        tv.tintColor = CMColor.textPrimary
        tv.textContainerInset = UIEdgeInsets(top: 14, left: 0, bottom: 14, right: 0)
        return tv
    }()
    
    private let captionPlaceholder: UILabel = {
        let label = UILabel()
        label.text = "Add a caption…"
        label.font = CMTypography.body
        label.textColor = CMColor.textTertiary
        return label
    }()
    
    private let sendButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Send moment"
        config.image = UIImage(systemName: "paperplane.fill")
        config.imagePadding = 8
        config.cornerStyle = .capsule
        config.baseBackgroundColor = .white
        config.baseForegroundColor = .black
        let button = UIButton(configuration: config)
        return button
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .medium)
        ai.hidesWhenStopped = true
        return ai
    }()
    
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
        imageView.image = viewModel.asset.previewImage
        captionTextView.delegate = self
        setupKeyboardHandling()
        setupTapToDismissKeyboard()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerKeyboardNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterKeyboardNotifications()
    }
    
    private func setupViews() {
        view.addSubview(closeButton)
        view.addSubview(downloadButton)
        view.addSubview(titleLabel)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(imageCard)
        contentView.addSubview(collectionView)
        contentView.addSubview(captionContainer)
        contentView.addSubview(sendButton)
        contentView.addSubview(activityIndicator)
        
        imageCard.addSubview(imageView)
        imageCard.addSubview(recipientBadge)
        captionContainer.addSubview(captionTextView)
        captionContainer.addSubview(captionPlaceholder)
        
        closeButton.addTarget(self, action: #selector(handleCloseTap), for: .touchUpInside)
        downloadButton.addTarget(self, action: #selector(handleDownloadTap), for: .touchUpInside)
        sendButton.addTarget(self, action: #selector(handleSendTap), for: .touchUpInside)
        
        [closeButton, downloadButton, titleLabel, scrollView, contentView, imageCard, imageView,
         recipientBadge, collectionView, captionContainer, captionTextView, captionPlaceholder,
         sendButton, activityIndicator].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            downloadButton.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            downloadButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            
            scrollView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            imageCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            imageCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            imageCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            imageCard.heightAnchor.constraint(equalTo: imageCard.widthAnchor),
            
            imageView.topAnchor.constraint(equalTo: imageCard.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: imageCard.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: imageCard.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: imageCard.trailingAnchor),
            
            recipientBadge.trailingAnchor.constraint(equalTo: imageCard.trailingAnchor, constant: -12),
            recipientBadge.bottomAnchor.constraint(equalTo: imageCard.bottomAnchor, constant: -12),
            recipientBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
            recipientBadge.heightAnchor.constraint(equalToConstant: 24),
            
            collectionView.topAnchor.constraint(equalTo: imageCard.bottomAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            collectionView.heightAnchor.constraint(equalToConstant: 106),
            
            captionContainer.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 14),
            captionContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            captionContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            captionContainer.heightAnchor.constraint(equalToConstant: 100),
            
            captionTextView.topAnchor.constraint(equalTo: captionContainer.topAnchor),
            captionTextView.bottomAnchor.constraint(equalTo: captionContainer.bottomAnchor),
            captionTextView.leadingAnchor.constraint(equalTo: captionContainer.leadingAnchor, constant: 16),
            captionTextView.trailingAnchor.constraint(equalTo: captionContainer.trailingAnchor, constant: -16),
            
            captionPlaceholder.leadingAnchor.constraint(equalTo: captionContainer.leadingAnchor, constant: 20),
            captionPlaceholder.topAnchor.constraint(equalTo: captionContainer.topAnchor, constant: 18),
            
            sendButton.topAnchor.constraint(equalTo: captionContainer.bottomAnchor, constant: 16),
            sendButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            sendButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            sendButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
            sendButton.heightAnchor.constraint(equalToConstant: 56),
            
            activityIndicator.centerYAnchor.constraint(equalTo: sendButton.centerYAnchor),
            activityIndicator.trailingAnchor.constraint(equalTo: sendButton.trailingAnchor, constant: -18)
        ])
    }
    
    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let keyboardHeight = keyboardFrame.height
        let bottomInset = keyboardHeight - view.safeAreaInsets.bottom
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0)
        scrollView.scrollIndicatorInsets = scrollView.contentInset
        
        let textFieldRect = captionTextView.convert(captionTextView.bounds, to: scrollView)
        scrollView.scrollRectToVisible(textFieldRect, animated: true)
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
    
    private func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func unregisterKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func setupTapToDismissKeyboard() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, User>(collectionView: collectionView) { [weak self] cv, indexPath, user in
            let cell = cv.dequeueReusableCell(withReuseIdentifier: PreviewRecipientCell.reuseIdentifier, for: indexPath) as! PreviewRecipientCell
            cell.configure(with: user, isSelected: self?.viewModel.isSelected(user) ?? false)
            return cell
        }
        collectionView.delegate = self
    }
    
    private func bindViewModel() {
        viewModel.$recipients
            .receive(on: DispatchQueue.main)
            .sink { [weak self] recipients in
                self?.applySnapshot(recipients: recipients)
            }
            .store(in: &cancellables)
        
        viewModel.$selectedRecipientIDs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] selectedIDs in
                guard let self else { return }
                self.applySnapshot(recipients: self.viewModel.recipients)
                let count = selectedIDs.count
                if count > 0 {
                    self.recipientBadge.text = "  \(count) recipient\(count == 1 ? "" : "s")  "
                    self.recipientBadge.isHidden = false
                } else {
                    self.recipientBadge.isHidden = true
                }
                self.sendButton.isEnabled = count > 0
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
    
    private func applySnapshot(recipients: [User]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, User>()
        snapshot.appendSections([.recipients])
        snapshot.appendItems(recipients, toSection: .recipients)
        dataSource?.apply(snapshot, animatingDifferences: true)
    }
    
    @objc private func handleCloseTap() { onDismiss?() }
    
    @objc private func handleDownloadTap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        UIImageWriteToSavedPhotosAlbum(viewModel.asset.previewImage, self, #selector(imageSaved(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc private func imageSaved(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        let title = error == nil ? "Saved" : "Error"
        let message = error == nil ? "Photo saved to library." : error?.localizedDescription
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func handleSendTap() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        viewModel.send { [weak self] result in
            switch result {
            case .success(let moment):
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                self?.onMomentSent?(moment)
            case .failure:
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
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
    
    private static func makeCircleButton(symbol: String) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: symbol)
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let button = UIButton(configuration: config)
        button.tintColor = .white
        button.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 40),
            button.heightAnchor.constraint(equalToConstant: 40)
        ])
        return button
    }
}

extension PreviewViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
