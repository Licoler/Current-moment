import Combine
import UIKit

final class ProfileViewController: UIViewController {

    private let viewModel: ProfileViewModel
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - UI

    private let backButton    = IconCircleButton(symbol: "chevron.left")
    private let titleLabel    = UILabel()
    private let scrollView    = UIScrollView()
    private let contentStack  = UIStackView()
    private let avatarView    = AvatarView()
    private let nameLabel     = UILabel()
    private let usernameLabel = UILabel()
    private let editButton    = UIButton(type: .system)
    private let sentCard      = StatCardView(value: "0", title: "Photos sent")
    private let friendsCard   = StatCardView(value: "0", title: "Friends")
    private let streakCard    = StatCardView(value: "0", title: "Streak days")

    private lazy var notificationsRow = SettingRowView(
        symbol: "bell", title: "Notifications", subtitle: "Push alerts and delivery updates")
    private lazy var privacyRow = SettingRowView(
        symbol: "lock.shield", title: "Privacy", subtitle: "Control your circle and visibility")
    private lazy var supportRow = SettingRowView(
        symbol: "questionmark.circle", title: "Support", subtitle: "Get help and contact support")
    private lazy var logoutRow  = SettingRowView(
        symbol: "rectangle.portrait.and.arrow.right", title: "Log out",
        subtitle: "End the current session", destructive: true)

    var onBack: (() -> Void)?
    var onLoggedOut: (() -> Void)?

    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CMColor.background
        setupViews()
        bindViewModel()
    }

    private func setupViews() {
        titleLabel.text      = "Profile"
        titleLabel.font      = CMTypography.title2
        titleLabel.textColor = CMColor.textPrimary

        nameLabel.font          = CMTypography.title
        nameLabel.textColor     = CMColor.textPrimary
        nameLabel.textAlignment = .center

        usernameLabel.font          = CMTypography.body
        usernameLabel.textColor     = CMColor.textSecondary
        usernameLabel.textAlignment = .center

        var editConfig = UIButton.Configuration.plain()
        editConfig.title               = "Edit profile"
        editConfig.baseForegroundColor = CMColor.textSecondary
        editButton.configuration       = editConfig
        editButton.enableScaleFeedback()

        backButton.addTarget(self,       action: #selector(handleBackTap),      for: .touchUpInside)
        editButton.addTarget(self,       action: #selector(handleEditTap),      for: .touchUpInside)
        notificationsRow.addTarget(self, action: #selector(handleNotificationsTap), for: .touchUpInside)
        privacyRow.addTarget(self,       action: #selector(handlePrivacyTap),   for: .touchUpInside)
        supportRow.addTarget(self,       action: #selector(handleSupportTap),   for: .touchUpInside)
        logoutRow.addTarget(self,        action: #selector(handleLogoutTap),    for: .touchUpInside)

        contentStack.axis    = .vertical
        contentStack.spacing = 14

        let statsRow = UIStackView(arrangedSubviews: [sentCard, friendsCard, streakCard])
        statsRow.axis         = .horizontal
        statsRow.spacing      = 12
        statsRow.distribution = .fillEqually

        let identityStack = UIStackView(arrangedSubviews: [avatarView, nameLabel, usernameLabel, editButton])
        identityStack.axis      = .vertical
        identityStack.alignment = .center
        identityStack.spacing   = 10

        contentStack.addArrangedSubview(identityStack)
        contentStack.addArrangedSubview(statsRow)
        contentStack.addArrangedSubview(notificationsRow)
        contentStack.addArrangedSubview(privacyRow)
        contentStack.addArrangedSubview(supportRow)
        contentStack.addArrangedSubview(logoutRow)

        view.addSubview(backButton)
        view.addSubview(titleLabel)
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

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
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),

            avatarView.widthAnchor.constraint(equalToConstant: 120),
            avatarView.heightAnchor.constraint(equalToConstant: 120),
            sentCard.heightAnchor.constraint(equalToConstant: 110),
            notificationsRow.heightAnchor.constraint(equalToConstant: 84),
            privacyRow.heightAnchor.constraint(equalToConstant: 84),
            supportRow.heightAnchor.constraint(equalToConstant: 84),
            logoutRow.heightAnchor.constraint(equalToConstant: 84)
        ])
    }

    private func bindViewModel() {
        viewModel.$user
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                guard let user else { return }
                self?.avatarView.configure(with: user, imagePipeline: .shared)
                self?.nameLabel.text     = user.displayName
                self?.usernameLabel.text = "@\(user.username)"
            }
            .store(in: &cancellables)

        viewModel.$stats
            .receive(on: DispatchQueue.main)
            .sink { [weak self] stats in
                self?.sentCard.update(value: "\(stats.photosSent)",    title: "Photos sent")
                self?.friendsCard.update(value: "\(stats.friendsCount)", title: "Friends")
                self?.streakCard.update(value: "\(stats.streakDays)",  title: "Streak days")
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let message else { return }
                let alert = UIAlertController(title: "Profile", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    @objc private func handleBackTap() { onBack?() }

    @objc private func handleEditTap() {
        guard let user = viewModel.user else { return }
        let alert = UIAlertController(title: "Edit profile", message: nil, preferredStyle: .alert)
        alert.addTextField { field in
            field.placeholder = "Full name"
            field.text        = user.fullName
            field.autocapitalizationType = .words
        }
        alert.addTextField { field in
            field.placeholder = "Username"
            field.text        = user.username
            field.autocorrectionType = .no
            field.autocapitalizationType = .none
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self, weak alert] _ in
            let fullName = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespaces) ?? ""
            let username = alert?.textFields?.last?.text?.trimmingCharacters(in: .whitespaces) ?? ""
            guard !fullName.isEmpty, !username.isEmpty else { return }
            self?.viewModel.saveProfile(fullName: fullName, username: username)
        })
        present(alert, animated: true)
    }

    @objc private func handleNotificationsTap() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    @objc private func handlePrivacyTap() {
        let alert = UIAlertController(
            title: "Privacy",
            message: "Only friends you've added can send you moments. You can remove anyone from your circle at any time.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Got it", style: .default))
        present(alert, animated: true)
    }

    @objc private func handleSupportTap() {
        let alert = UIAlertController(
            title: "Support",
            message: "For help, contact us at support@currentmoment.app",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func handleLogoutTap() {
        let alert = UIAlertController(
            title: "Log out",
            message: "Are you sure you want to end the current session?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Log out", style: .destructive) { [weak self] _ in
            self?.viewModel.logout { [weak self] in self?.onLoggedOut?() }
        })
        present(alert, animated: true)
    }
}
