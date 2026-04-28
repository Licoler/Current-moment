import Combine
import UIKit

// MARK: - AppShareOption
enum AppShareOption: String, CaseIterable {
    case telegram = "Telegram"
    case whatsapp = "WhatsApp"
    case instagramDMs = "Instagram DMs"
    case instagramStory = "Instagram Story"
    case messages = "Messages"
    case other = "Other apps"
    
    var iconName: String {
        switch self {
        case .telegram: return "paperplane"
        case .whatsapp: return "message"
        case .instagramDMs: return "camera"
        case .instagramStory: return "plus.square"
        case .messages: return "bubble.left"
        case .other: return "square.and.arrow.up"
        }
    }
    
    var urlScheme: String? {
        switch self {
        case .telegram: return "tg://msg?text="
        case .whatsapp: return "whatsapp://send?text="
        case .instagramDMs: return "instagram://direct?text="
        case .instagramStory: return nil          // требует особого подхода
        case .messages: return "sms:&body="
        case .other: return nil
        }
    }
}

final class FriendsViewController: UIViewController {

    private enum Section: Int, CaseIterable {
        case friends
        case share
    }
    
    private enum Item: Hashable {
        case friend(User)
        case shareApp(AppShareOption)
    }

    private let viewModel: FriendsViewModel
    private var cancellables = Set<AnyCancellable>()
    private var dataSource: UITableViewDiffableDataSource<Section, Item>?

    // UI
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
        label.text = "Friends"
        label.font = CMTypography.title2
        label.textColor = CMColor.textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let searchField: UITextField = {
        let field = UITextField()
        field.attributedPlaceholder = NSAttributedString(
            string: "Search friends",
            attributes: [.foregroundColor: CMColor.textTertiary]
        )
        field.font = CMTypography.body
        field.textColor = CMColor.textPrimary
        field.backgroundColor = CMColor.cardElevated
        field.layer.cornerRadius = 18
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()
    
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.register(FriendTableViewCell.self, forCellReuseIdentifier: FriendTableViewCell.reuseIdentifier)
        tv.register(ShareAppCell.self, forCellReuseIdentifier: ShareAppCell.reuseIdentifier)
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 80
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    var onBack: (() -> Void)?

    init(viewModel: FriendsViewModel) {
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
        
        searchField.addAction(UIAction { [weak self] _ in
            self?.viewModel.updateSearchText(self?.searchField.text ?? "")
        }, for: .editingChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    private func setupViews() {
        view.addSubview(backButton)
        view.addSubview(titleLabel)
        view.addSubview(searchField)
        view.addSubview(tableView)
        
        backButton.addTarget(self, action: #selector(handleBackTap), for: .touchUpInside)
        
        let searchContainer = UIView(frame: CGRect(x: 0, y: 0, width: 34, height: 44))
        let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        searchIcon.tintColor = CMColor.textTertiary
        searchIcon.frame = CGRect(x: 10, y: 12, width: 18, height: 18)
        searchContainer.addSubview(searchIcon)
        searchField.leftView = searchContainer
        searchField.leftViewMode = .always
        
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            
            searchField.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 18),
            searchField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchField.heightAnchor.constraint(equalToConstant: 54),
            
            tableView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 14),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource<Section, Item>(tableView: tableView) { [weak self] tv, indexPath, item in
            switch item {
            case .friend(let user):
                let cell = tv.dequeueReusableCell(withIdentifier: FriendTableViewCell.reuseIdentifier, for: indexPath) as! FriendTableViewCell
                cell.configure(with: user, isFriend: true) { u in
                    self?.viewModel.removeFriend(u)
                }
                return cell
            case .shareApp(let app):
                let cell = tv.dequeueReusableCell(withIdentifier: ShareAppCell.reuseIdentifier, for: indexPath) as! ShareAppCell
                cell.configure(with: app) { selectedApp in
                    self?.viewModel.shareLink(through: selectedApp)
                }
                return cell
            }
        }
        tableView.dataSource = dataSource
        tableView.delegate = self
    }

    private func bindViewModel() {
        viewModel.$friends
            .receive(on: DispatchQueue.main)
            .sink { [weak self] friends in
                self?.applySnapshot(friends: friends)
            }
            .store(in: &cancellables)
        
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { message in
                guard let message else { return }
                let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }
            .store(in: &cancellables)
    }
    
    private func applySnapshot(friends: [User]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.friends, .share])
        
        let friendItems = friends.map { Item.friend($0) }
        snapshot.appendItems(friendItems, toSection: .friends)
        
        let shareItems = AppShareOption.allCases.map { Item.shareApp($0) }
        snapshot.appendItems(shareItems, toSection: .share)
        
        dataSource?.apply(snapshot, animatingDifferences: true)
    }

    @objc private func handleBackTap() {
        onBack?()
    }
}

// MARK: - UITableViewDelegate
extension FriendsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let sec = Section(rawValue: section) else { return nil }
        let label = UILabel()
        label.font = CMTypography.headline
        label.textColor = CMColor.textSecondary
        label.text = sec == .friends ? "Your Friends" : "Share your CurrentMoment link"
        let container = UIView()
        container.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])
        return container
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        42
    }
}

// MARK: - Share App Cell (вся строка кликабельна)
final class ShareAppCell: UITableViewCell {
    static let reuseIdentifier = "ShareAppCell"
    private var currentApp: AppShareOption?
    private var onShare: ((AppShareOption) -> Void)?
    
    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.tintColor = CMColor.textPrimary
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = CMTypography.bodySemibold
        label.textColor = CMColor.textPrimary
        return label
    }()
    private let chevronView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "chevron.right"))
        iv.tintColor = CMColor.textTertiary
        return iv
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        
        let stack = UIStackView(arrangedSubviews: [iconView, titleLabel, UIView(), chevronView])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),
            chevronView.widthAnchor.constraint(equalToConstant: 14),
            chevronView.heightAnchor.constraint(equalToConstant: 14)
        ])
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleShare))
        contentView.addGestureRecognizer(tap)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(with app: AppShareOption, onShare: @escaping (AppShareOption) -> Void) {
        currentApp = app
        self.onShare = onShare
        titleLabel.text = app.rawValue
        iconView.image = UIImage(systemName: app.iconName)
        if app.iconName == "paperplane" {
            iconView.image = UIImage(systemName: "paperplane")?.withRenderingMode(.alwaysTemplate)
        }
    }
    
    @objc private func handleShare() {
        guard let app = currentApp else { return }
        onShare?(app)
    }
}
