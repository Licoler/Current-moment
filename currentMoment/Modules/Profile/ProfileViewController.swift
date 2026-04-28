import Combine
import UIKit

final class ProfileViewController: UIViewController {

    private enum Section {
        case main
    }

    private let viewModel: ProfileViewModel
    private var cancellables: Set<AnyCancellable> = []

    // UI
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, Moment.ID>!
    private let headerView = ProfileHeaderView()
    private let activity = UIActivityIndicatorView(style: .large)

    var onBack: (() -> Void)?
    var onLoggedOut: (() -> Void)?

    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CMColor.background
        setupCollectionView()
        setupLayout()
        bindViewModel()
        headerView.onEditTap = { [weak self] in self?.presentEdit() }
    }

    private func setupCollectionView() {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, env -> NSCollectionLayoutSection? in
            // header + grid
            let fraction: CGFloat = 1/3
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = .init(top: 2, leading: 2, bottom: 2, trailing: 2)

            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalWidth(fraction))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item, item, item])

            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 30, trailing: 12)

            // Supplementary header
            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(320))
            let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
            section.boundarySupplementaryItems = [header]
            return section
        }

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(ProfileGridCell.self, forCellWithReuseIdentifier: ProfileGridCell.reuseIdentifier)
        collectionView.register(ProfileHeaderContainer.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ProfileHeaderContainer.reuseIdentifier)
        collectionView.delegate = self
        view.addSubview(collectionView)

        activity.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activity)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            activity.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activity.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        configureDataSource()
    }

    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, Moment.ID>(collectionView: collectionView) { collectionView, indexPath, id in
            guard let moment = self.viewModel.momentsSent.first(where: { $0.id == id }) else { return UICollectionViewCell() }
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProfileGridCell.reuseIdentifier, for: indexPath) as? ProfileGridCell else { return UICollectionViewCell() }
            cell.configure(with: moment)
            return cell
        }

        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard let self, kind == UICollectionView.elementKindSectionHeader else { return nil }
            guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ProfileHeaderContainer.reuseIdentifier, for: indexPath) as? ProfileHeaderContainer else { return nil }
            header.configure(with: self.headerView)
            return header
        }
    }

    private func setupLayout() {
        // initial empty snapshot
        var snapshot = NSDiffableDataSourceSnapshot<Section, Moment.ID>()
        snapshot.appendSections([.main])
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    private func bindViewModel() {
        viewModel.$user
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.headerView.configure(with: user, stats: self?.viewModel.stats)
            }
            .store(in: &cancellables)

        viewModel.$stats
            .receive(on: DispatchQueue.main)
            .sink { [weak self] stats in
                self?.headerView.configure(with: self?.viewModel.user, stats: stats)
            }
            .store(in: &cancellables)

        viewModel.$isLoadingMoments
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                if loading {
                    self?.activity.startAnimating()
                } else {
                    self?.activity.stopAnimating()
                }
            }
            .store(in: &cancellables)

        viewModel.$momentsSent
            .receive(on: DispatchQueue.main)
            .sink { [weak self] moments in
                self?.applySnapshot(moments: moments)
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                let alert = UIAlertController(title: "Profile", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            }
            .store(in: &cancellables)
    }

    private func applySnapshot(moments: [Moment]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Moment.ID>()
        snapshot.appendSections([.main])
        snapshot.appendItems(moments.map { $0.id }, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func presentEdit() {
        let edit = EditProfileViewController(viewModel: viewModel)
        let nav = UINavigationController(rootViewController: edit)
        navigationController?.present(nav, animated: true)
    }

    private func handleLogout() {
        let alert = UIAlertController(title: "Log out", message: "Are you sure you want to end the current session?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Log out", style: .destructive) { [weak self] _ in
            self?.viewModel.logout { [weak self] in self?.onLoggedOut?() }
        })
        present(alert, animated: true)
    }
}

// MARK: - Collection supplementary container
private final class ProfileHeaderContainer: UICollectionReusableView {
    static let reuseIdentifier = "ProfileHeaderContainer"
    private var header: ProfileHeaderView?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with headerView: ProfileHeaderView) {
        subviews.forEach { $0.removeFromSuperview() }
        self.header = headerView
        headerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(headerView)
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: topAnchor),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            headerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

extension ProfileViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let id = dataSource.itemIdentifier(for: indexPath)
        guard let id, let moment = viewModel.momentsSent.first(where: { $0.id == id }) else { return }
        // open detail (existing coordinator should handle navigation via callback) - for now present detail controller if exists
        let vc = MomentDetailViewController(moment: moment, imagePipeline: .shared)
        navigationController?.pushViewController(vc, animated: true)
    }
}
