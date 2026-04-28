import UIKit
import Photos

final class MomentDetailViewController: UIViewController {

    private let moment: Moment
    private let imagePipeline: ImagePipeline

    // MARK: - UI

    private let backButton = IconCircleButton(symbol: "chevron.left")
    private let shareButton = IconCircleButton(symbol: "square.and.arrow.up")
    private let deleteButton = IconCircleButton(symbol: "trash")
    private let saveButton = IconCircleButton(symbol: "arrow.down.to.line")

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let imageView = UIImageView()
    private let senderLabel = UILabel()
    private let dateLabel = UILabel()
    private let captionCard = UIView()
    private let captionLabel = UILabel()

    private let replyContainer: UIView = {
        let view = UIView()
        view.backgroundColor = CMColor.cardElevated
        view.layer.cornerRadius = 22
        view.layer.cornerCurve = .continuous
        return view
    }()
    private let replyTextView: UITextView = {
        let tv = UITextView()
        tv.backgroundColor = .clear
        tv.font = CMTypography.body
        tv.textColor = CMColor.textPrimary
        tv.tintColor = CMColor.textPrimary
        tv.textContainerInset = UIEdgeInsets(top: 14, left: 0, bottom: 14, right: 0)
        tv.isScrollEnabled = false
        return tv
    }()
    private let replyPlaceholder: UILabel = {
        let label = UILabel()
        label.text = "Write a reply…"
        label.font = CMTypography.body
        label.textColor = CMColor.textTertiary
        return label
    }()
    private let replySendButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Send"
        config.cornerStyle = .capsule
        config.baseBackgroundColor = .white
        config.baseForegroundColor = .black
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        let button = UIButton(configuration: config)
        button.titleLabel?.font = CMTypography.footnote
        return button
    }()

    private let actionButtonsStack = UIStackView()

    var onBack: (() -> Void)?
    var onDelete: (() -> Void)?   // после удаления вернуться назад

    init(moment: Moment, imagePipeline: ImagePipeline) {
        self.moment = moment
        self.imagePipeline = imagePipeline
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CMColor.background
        setupViews()
        loadImage()
        setupKeyboardHandling()
        setupTapToDismissKeyboard()
        updateContent()
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
        // Image view
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 28
        imageView.layer.cornerCurve = .continuous
        imageView.backgroundColor = CMColor.cardElevated

        // Sender label
        senderLabel.font = CMTypography.title2
        senderLabel.textColor = CMColor.textPrimary

        // Date label
        dateLabel.font = CMTypography.footnote
        dateLabel.textColor = CMColor.textSecondary

        // Caption card (display only if exists)
        captionCard.backgroundColor = CMColor.cardElevated
        captionCard.layer.cornerRadius = 20
        captionCard.layer.cornerCurve = .continuous
        captionLabel.font = CMTypography.body
        captionLabel.textColor = CMColor.textPrimary
        captionLabel.numberOfLines = 0
        captionCard.addSubview(captionLabel)
        captionLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            captionLabel.topAnchor.constraint(equalTo: captionCard.topAnchor, constant: 16),
            captionLabel.leadingAnchor.constraint(equalTo: captionCard.leadingAnchor, constant: 16),
            captionLabel.trailingAnchor.constraint(equalTo: captionCard.trailingAnchor, constant: -16),
            captionLabel.bottomAnchor.constraint(equalTo: captionCard.bottomAnchor, constant: -16)
        ])

        // Reply area
        replyContainer.addSubview(replyTextView)
        replyContainer.addSubview(replyPlaceholder)
        replyContainer.addSubview(replySendButton)
        replyTextView.delegate = self
        replySendButton.addTarget(self, action: #selector(sendReply), for: .touchUpInside)

        let metaStack = UIStackView(arrangedSubviews: [senderLabel, dateLabel])
        metaStack.axis = .vertical
        metaStack.spacing = 4

        // Action buttons (share, save, delete)
        shareButton.addTarget(self, action: #selector(shareMoment), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveToGallery), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(deleteMoment), for: .touchUpInside)
        actionButtonsStack.axis = .horizontal
        actionButtonsStack.spacing = 16
        actionButtonsStack.distribution = .fillEqually
        [shareButton, saveButton, deleteButton].forEach { actionButtonsStack.addArrangedSubview($0) }

        // Content stack
        contentStack.axis = .vertical
        contentStack.spacing = 18
        contentStack.addArrangedSubview(imageView)
        contentStack.addArrangedSubview(metaStack)
        if !moment.caption.isEmpty {
            contentStack.addArrangedSubview(captionCard)
        }
        contentStack.addArrangedSubview(replyContainer)
        contentStack.addArrangedSubview(actionButtonsStack)

        scrollView.addSubview(contentStack)
        view.addSubview(backButton)
        view.addSubview(scrollView)

        [backButton, scrollView, contentStack, imageView, replyTextView, replyPlaceholder, replySendButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        backButton.addTarget(self, action: #selector(handleBackTap), for: .touchUpInside)

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            scrollView.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),

            imageView.widthAnchor.constraint(equalTo: contentStack.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),

            replyContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),
            replyTextView.topAnchor.constraint(equalTo: replyContainer.topAnchor),
            replyTextView.bottomAnchor.constraint(equalTo: replyContainer.bottomAnchor),
            replyTextView.leadingAnchor.constraint(equalTo: replyContainer.leadingAnchor, constant: 16),
            replyTextView.trailingAnchor.constraint(equalTo: replySendButton.leadingAnchor, constant: -12),

            replySendButton.centerYAnchor.constraint(equalTo: replyContainer.centerYAnchor),
            replySendButton.trailingAnchor.constraint(equalTo: replyContainer.trailingAnchor, constant: -16),
            replySendButton.heightAnchor.constraint(equalToConstant: 32),

            replyPlaceholder.leadingAnchor.constraint(equalTo: replyContainer.leadingAnchor, constant: 20),
            replyPlaceholder.topAnchor.constraint(equalTo: replyContainer.topAnchor, constant: 18),

            actionButtonsStack.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    private func updateContent() {
        let currentUserID = (UIApplication.shared.delegate as? AppDelegate)?.container.repository.currentUser()?.id
        let isOwnMoment = moment.senderId == currentUserID
        senderLabel.text = isOwnMoment ? "You" : moment.senderName
        dateLabel.text = moment.createdAt.dayMonthDescription()
        captionLabel.text = moment.caption
        captionCard.isHidden = moment.caption.isEmpty
    }

    private func loadImage() {
        Task { [weak self] in
            let image = await self?.imagePipeline.image(for: self?.moment.imageURL)
            await MainActor.run { self?.imageView.image = image }
        }
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

        let replyRect = replyContainer.convert(replyContainer.bounds, to: scrollView)
        scrollView.scrollRectToVisible(replyRect, animated: true)
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

    @objc private func handleBackTap() {
        onBack?()
    }

    @objc private func shareMoment() {
        guard let image = imageView.image else { return }
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        present(activityVC, animated: true)
    }

    @objc private func saveToGallery() {
        guard let image = imageView.image else { return }
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, error in
                DispatchQueue.main.async {
                    let title = success ? "Saved" : "Error"
                    let message = success ? "Photo saved to library." : error?.localizedDescription
                    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    @objc private func deleteMoment() {
        let alert = UIAlertController(title: "Delete moment", message: "Are you sure you want to delete this moment?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            // Здесь вызвать удаление из репозитория
            guard let repo = (UIApplication.shared.delegate as? AppDelegate)?.container.repository else { return }
            Task {
                // Предполагается, что в репозитории есть метод deleteMoment
                // Пока просто симулируем
                // try? await repo.deleteMoment(self?.moment.id)
                await MainActor.run {
                    self?.onDelete?()
                    self?.onBack?()
                }
            }
        })
        present(alert, animated: true)
    }

    @objc private func sendReply() {
        let text = replyTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        // Здесь отправить ответ (реализуйте логику отправки сообщения)
        // После отправки очистить поле
        replyTextView.text = ""
        replyPlaceholder.isHidden = false
        view.endEditing(true)

        // Показать подтверждение
        let alert = UIAlertController(title: "Reply sent", message: "Your reply has been sent.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
        // В реальном проекте вызвать метод репозитория для отправки сообщения
    }
}

extension MomentDetailViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        replyPlaceholder.isHidden = !textView.text.isEmpty
    }
}
