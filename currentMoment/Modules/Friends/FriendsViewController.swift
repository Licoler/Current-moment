import Combine
import UIKit

final class FriendsViewController: UIViewController {

    private enum Section: Int, CaseIterable {
        case friends, suggestions
        var title: String { self == .friends ? "Friends" : "Suggested" }
    }
    private enum Item: Hashable {
        case friend(User), suggestion(User)
    }

    private let viewModel: FriendsViewModel
    private var cancellables: Set<AnyCancellable> = []
    private var dataSource: UITableViewDiffableDataSource<Section, Item>?

    private let backButton  = IconCircleButton(symbol: "chevron.left")
    private let addButton   = IconCircleButton(symbol: "person.badge.plus")
    private let titleLabel  = UILabel()
    private let searchField = UITextField()
    private let tableView   = UITableView(frame: .zero, style: .plain)

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
    }

    private func setupViews() {
        titleLabel.text = "Friends"
        titleLabel.font = CMTypography.title2
        titleLabel.textColor = CMColor.textPrimary

        searchField.attributedPlaceholder = NSAttributedString(
            string: "Search users",
            attributes: [.foregroundColor: CMColor.textTertiary]
        )
        searchField.font = CMTypography.body
        searchField.textColor = CMColor.textPrimary
        searchField.backgroundColor = CMColor.cardElevated
        searchField.layer.cornerRadius = 18
        searchField.setSearchLeftView()
        searchField.addAction(UIAction { [weak self] _ in
            self?.viewModel.updateSearchText(self?.searchField.text ?? "")
        }, for: .editingChanged)

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.register(FriendTableViewCell.self, forCellReuseIdentifier: FriendTableViewCell.reuseIdentifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80

        backButton.addTarget(self, action: #selector(handleBackTap), for: .touchUpInside)
        addButton.addTarget(self, action: #selector(handleAddTap), for: .touchUpInside)

        [backButton, addButton, titleLabel, searchField, tableView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            addButton.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),

            searchField.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 18),
            searchField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchField.heightAnchor.constraint(equalToConstant: 54),

            tableView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 14),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)   // ← прижато к низу экрана
        ])
    }

    private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource<Section, Item>(tableView: tableView) { tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(withIdentifier: FriendTableViewCell.reuseIdentifier, for: indexPath) as! FriendTableViewCell
            switch item {
            case .friend(let user):
                cell.configure(with: user, isFriend: true) { [weak self] u in self?.viewModel.removeFriend(u) }
            case .suggestion(let user):
                cell.configure(with: user, isFriend: false) { [weak self] u in self?.viewModel.addFriend(u) }
            }
            return cell
        }
        tableView.dataSource = dataSource
        tableView.delegate = self
    }

    private func bindViewModel() {
        Publishers.CombineLatest(viewModel.$friends, viewModel.$suggestions)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] friends, suggestions in
                var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
                snapshot.appendSections([.friends, .suggestions])
                snapshot.appendItems(friends.map(Item.friend), toSection: .friends)
                snapshot.appendItems(suggestions.map(Item.suggestion), toSection: .suggestions)
                self?.dataSource?.apply(snapshot, animatingDifferences: true)
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let message else { return }
                let alert = UIAlertController(title: "Friends", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            }
            .store(in: &cancellables)
    }

    @objc private func handleBackTap() { onBack?() }
    @objc private func handleAddTap()  { searchField.becomeFirstResponder() }
}

extension FriendsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let section = Section(rawValue: section) else { return nil }
        let label = UILabel()
        label.font = CMTypography.headline
        label.textColor = CMColor.textSecondary
        label.text = section.title
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
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 42 }
}

private extension UITextField {
    func setSearchLeftView() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 34, height: 44))
        let imageView = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        imageView.tintColor = CMColor.textTertiary
        imageView.frame = CGRect(x: 10, y: 12, width: 18, height: 18)
        container.addSubview(imageView)
        leftView = container
        leftViewMode = .always
    }
}
