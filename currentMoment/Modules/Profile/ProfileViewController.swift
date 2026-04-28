import Combine
import UIKit
import MessageUI

final class ProfileViewController: UIViewController, MFMailComposeViewControllerDelegate {

    private let viewModel: ProfileViewModel
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI

    private let backButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "chevron.left")
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        let button = UIButton(configuration: config)
        button.tintColor = .white
        button.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        button.layer.cornerRadius = 20
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 40),
            button.heightAnchor.constraint(equalToConstant: 40)
        ])
        return button
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Profile"
        label.font = CMTypography.title2
        label.textColor = CMColor.textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let avatarView = AvatarView()
    private let nameLabel = UILabel()
    private let usernameLabel = UILabel()
    private let editButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "Edit profile"
        config.baseForegroundColor = CMColor.textSecondary
        let button = UIButton(configuration: config)
        button.enableScaleFeedback()
        return button
    }()

    private let statsStack = UIStackView()
    private let photosStat = StatCardView(value: "0", title: "Photos sent")
    private let friendsStat = StatCardView(value: "0", title: "Friends")
    private let streakStat = StatCardView(value: "0", title: "Streak days")

    private lazy var notificationsRow = SettingRowView(
        symbol: "bell", title: "Notifications", subtitle: "Push alerts and delivery updates")
    private lazy var privacyRow = SettingRowView(
        symbol: "lock.shield", title: "Privacy", subtitle: "Control your circle and visibility")
    private lazy var supportRow = SettingRowView(
        symbol: "questionmark.circle", title: "Support", subtitle: "Get help and contact support")
    private lazy var logoutRow = SettingRowView(
        symbol: "rectangle.portrait.and.arrow.right", title: "Log out", subtitle: "End the current session", destructive: true)

    // MARK: - Callbacks

    var onBack: (() -> Void)?
    var onLoggedOut: (() -> Void)?

    // MARK: - Init

    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CMColor.background
        setupViews()
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    // MARK: - Setup

    private func setupViews() {
        view.addSubview(backButton)
        view.addSubview(titleLabel)
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        editButton.addTarget(self, action: #selector(handleEditProfile), for: .touchUpInside)

        notificationsRow.addTarget(self, action: #selector(handleNotifications), for: .touchUpInside)
        privacyRow.addTarget(self, action: #selector(handlePrivacy), for: .touchUpInside)
        supportRow.addTarget(self, action: #selector(handleSupport), for: .touchUpInside)
        logoutRow.addTarget(self, action: #selector(handleLogout), for: .touchUpInside)

        // Avatar, name, username
        let identityStack = UIStackView(arrangedSubviews: [avatarView, nameLabel, usernameLabel, editButton])
        identityStack.axis = .vertical
        identityStack.alignment = .center
        identityStack.spacing = 10

        // Stats
        statsStack.axis = .horizontal
        statsStack.spacing = 12
        statsStack.distribution = .fillEqually
        statsStack.addArrangedSubview(photosStat)
        statsStack.addArrangedSubview(friendsStat)
        statsStack.addArrangedSubview(streakStat)

        // Main stack
        contentStack.axis = .vertical
        contentStack.spacing = 24
        contentStack.addArrangedSubview(identityStack)
        contentStack.addArrangedSubview(statsStack)
        contentStack.addArrangedSubview(notificationsRow)
        contentStack.addArrangedSubview(privacyRow)
        contentStack.addArrangedSubview(supportRow)
        contentStack.addArrangedSubview(logoutRow)

        // Constraints
        [backButton, titleLabel, scrollView, contentStack, avatarView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),

            scrollView.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 18),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),

            avatarView.widthAnchor.constraint(equalToConstant: 120),
            avatarView.heightAnchor.constraint(equalToConstant: 120),
            photosStat.heightAnchor.constraint(equalToConstant: 90),
            friendsStat.heightAnchor.constraint(equalToConstant: 90),
            streakStat.heightAnchor.constraint(equalToConstant: 90)
        ])
    }

    private func bindViewModel() {
        viewModel.$user
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                guard let user else { return }
                self?.avatarView.configure(with: user, imagePipeline: .shared)
                self?.nameLabel.text = user.displayName
                self?.usernameLabel.text = "@\(user.username)"
            }
            .store(in: &cancellables)

        viewModel.$stats
            .receive(on: DispatchQueue.main)
            .sink { [weak self] stats in
                self?.photosStat.update(value: "\(stats.photosSent)", title: "Photos sent")
                self?.friendsStat.update(value: "\(stats.friendsCount)", title: "Friends")
                self?.streakStat.update(value: "\(stats.streakDays)", title: "Streak days")
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let message else { return }
                let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    @objc private func handleBack() {
        onBack?()
    }

    @objc private func handleEditProfile() {
        guard let user = viewModel.user else { return }
        let alert = UIAlertController(title: "Edit profile", message: nil, preferredStyle: .alert)
        alert.addTextField { field in
            field.placeholder = "Full name"
            field.text = user.fullName
            field.autocapitalizationType = .words
        }
        alert.addTextField { field in
            field.placeholder = "Username"
            field.text = user.username
            field.autocapitalizationType = .none
            field.autocorrectionType = .no
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self, weak alert] _ in
            guard let newName = alert?.textFields?[0].text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  let newUsername = alert?.textFields?[1].text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !newName.isEmpty, !newUsername.isEmpty else { return }
            self?.viewModel.saveProfile(fullName: newName, username: newUsername)
        })
        present(alert, animated: true)
    }

    @objc private func handleNotifications() {
        // Открываем системные настройки уведомлений для этого приложения
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    @objc private func handlePrivacy() {
        let alert = UIAlertController(
            title: "Privacy",
            message: "Only friends you've added can send you moments. You can remove anyone from your circle at any time.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Got it", style: .default))
        present(alert, animated: true)
    }

    @objc private func handleSupport() {
        // Пытаемся открыть почтовое приложение с готовым адресатом
        if MFMailComposeViewController.canSendMail() {
            let mailVC = MFMailComposeViewController()
            mailVC.mailComposeDelegate = self
            mailVC.setToRecipients(["support@currentmoment.app"])
            mailVC.setSubject("CurrentMoment Support")
            mailVC.setMessageBody("\n\n---\nApp version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? "")\nDevice: \(UIDevice.current.model)", isHTML: false)
            present(mailVC, animated: true)
        } else {
            // Если почта не настроена, открываем ссылку на сайте
            if let url = URL(string: "https://currentmoment.app/support") {
                UIApplication.shared.open(url)
            } else {
                let alert = UIAlertController(title: "Support", message: "Please contact us at support@currentmoment.app", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
            }
        }
    }

    @objc private func handleLogout() {
        let alert = UIAlertController(title: "Log out", message: "Are you sure you want to end the current session?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Log out", style: .destructive) { [weak self] _ in
            self?.viewModel.logout { [weak self] in
                self?.onLoggedOut?()
            }
        })
        present(alert, animated: true)
    }

    // MARK: - MFMailComposeViewControllerDelegate

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}
