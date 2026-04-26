import Combine
import UIKit

final class HistoryViewController: UIViewController {

    private let viewModel: HistoryViewModel
    private var cancellables: Set<AnyCancellable> = []
    private var pendingScrollMomentID: String?
    private var dataSource: UICollectionViewDiffableDataSource<Int, Moment>?

    private let backButton  = IconCircleButton(symbol: "chevron.left")
    private let titleLabel  = UILabel()

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: Self.makeLayout())
        cv.backgroundColor = .clear
        cv.alwaysBounceVertical = true
        cv.showsVerticalScrollIndicator = false
        cv.register(MomentGridCell.self, forCellWithReuseIdentifier: MomentGridCell.reuseIdentifier)
        return cv
    }()

    var onBack: (() -> Void)?
    var onMomentSelected: ((Moment) -> Void)?

    init(viewModel: HistoryViewModel) {
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

    func scrollToMoment(with id: String) {
        pendingScrollMomentID = id
    }

    private func setupViews() {
        titleLabel.text = "History"
        titleLabel.font = CMTypography.title2
        titleLabel.textColor = CMColor.textPrimary

        backButton.addTarget(self, action: #selector(handleBackTap), for: .touchUpInside)

        [backButton, titleLabel, collectionView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),

            collectionView.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 18),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -14),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)   // ← исправлено
        ])
    }

    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Int, Moment>(collectionView: collectionView) { collectionView, indexPath, moment in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MomentGridCell.reuseIdentifier, for: indexPath) as! MomentGridCell
            cell.configure(with: moment)
            return cell
        }
        collectionView.dataSource = dataSource
        collectionView.delegate = self
    }

    private func bindViewModel() {
        viewModel.$moments
            .receive(on: DispatchQueue.main)
            .sink { [weak self] moments in
                var snapshot = NSDiffableDataSourceSnapshot<Int, Moment>()
                snapshot.appendSections([0])
                snapshot.appendItems(moments, toSection: 0)
                self?.dataSource?.apply(snapshot, animatingDifferences: true)
                self?.attemptPendingScroll()
            }
            .store(in: &cancellables)
    }

    private func attemptPendingScroll() {
        guard let targetID = pendingScrollMomentID,
              let moment = viewModel.moment(with: targetID),
              let indexPath = dataSource?.indexPath(for: moment) else { return }
        collectionView.layoutIfNeeded()
        collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)
        pendingScrollMomentID = nil
    }

    @objc private func handleBackTap() { onBack?() }

    private static func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { _, environment in
            let width = environment.container.effectiveContentSize.width
            let columns: CGFloat = width > 520 ? 3 : 2
            let fraction = 1 / columns
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(fraction),
                                                  heightDimension: .fractionalWidth(fraction * 1.28))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 6, bottom: 8, trailing: 6)
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                   heightDimension: .fractionalWidth(fraction * 1.28))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: Array(repeating: item, count: Int(columns)))
            let section = NSCollectionLayoutSection(group: group)
            return section
        }
    }
}

extension HistoryViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let moment = dataSource?.itemIdentifier(for: indexPath) else { return }
        onMomentSelected?(moment)
    }
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        viewModel.loadMoreIfNeeded(currentIndex: indexPath.item)
    }
}
