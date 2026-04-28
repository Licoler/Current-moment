import Combine
import UIKit

final class HistoryViewController: UIViewController {

    private let viewModel: HistoryViewModel
    private var cancellables: Set<AnyCancellable> = []
    private var pendingScrollMomentID: String?
    private var dataSource: UICollectionViewDiffableDataSource<Int, Moment>?

    // MARK: - UI

    private let backButton = IconCircleButton(symbol: "chevron.left")
    private let titleLabel = UILabel()

    // Empty state
    private let emptyIconView  = UIImageView(image: UIImage(systemName: "photo.stack"))
    private let emptyTitleLabel    = UILabel()
    private let emptySubtitleLabel = UILabel()
    private let emptyStackView     = UIStackView()

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: Self.makeLayout())
        cv.backgroundColor             = .clear
        cv.alwaysBounceVertical        = true
        cv.showsVerticalScrollIndicator = false
        cv.register(MomentGridCell.self, forCellWithReuseIdentifier: MomentGridCell.reuseIdentifier)
        return cv
    }()

    // MARK: - Callbacks

    var onBack: (() -> Void)?
    var onMomentSelected: ((Moment) -> Void)?

    // MARK: - Init

    init(viewModel: HistoryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CMColor.background
        setupViews()
        configureDataSource()
        bindViewModel()
    }

    // MARK: - Public

    func scrollToMoment(with id: String) {
        pendingScrollMomentID = id
    }

    // MARK: - Setup

    private func setupViews() {
        titleLabel.text      = "History"
        titleLabel.font      = CMTypography.title2
        titleLabel.textColor = CMColor.textPrimary

        backButton.addTarget(self, action: #selector(handleBackTap), for: .touchUpInside)

        // Empty state
        emptyIconView.tintColor = CMColor.textTertiary
        emptyIconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 44, weight: .light)

        emptyTitleLabel.text          = "No moments yet"
        emptyTitleLabel.font          = CMTypography.title2
        emptyTitleLabel.textColor     = CMColor.textPrimary
        emptyTitleLabel.textAlignment = .center

        emptySubtitleLabel.text          = "Capture a moment and send it to your friends"
        emptySubtitleLabel.font          = CMTypography.body
        emptySubtitleLabel.textColor     = CMColor.textSecondary
        emptySubtitleLabel.textAlignment = .center
        emptySubtitleLabel.numberOfLines = 0

        emptyStackView.axis      = .vertical
        emptyStackView.alignment = .center
        emptyStackView.spacing   = 12
        emptyStackView.addArrangedSubview(emptyIconView)
        emptyStackView.setCustomSpacing(20, after: emptyIconView)
        emptyStackView.addArrangedSubview(emptyTitleLabel)
        emptyStackView.addArrangedSubview(emptySubtitleLabel)
        emptyStackView.isHidden = true

        [backButton, titleLabel, collectionView, emptyStackView].forEach {
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
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Empty state по центру
            emptyStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 20),
            emptyStackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            emptyStackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40)
        ])
    }

    // MARK: - Data source

    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Int, Moment>(collectionView: collectionView) { collectionView, indexPath, moment in
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MomentGridCell.reuseIdentifier,
                for: indexPath
            ) as! MomentGridCell
            cell.configure(with: moment)
            return cell
        }
        collectionView.dataSource = dataSource
        collectionView.delegate   = self
    }

    // MARK: - Bind

    private func bindViewModel() {
        viewModel.$moments
            .receive(on: DispatchQueue.main)
            .sink { [weak self] moments in
                guard let self else { return }
                var snapshot = NSDiffableDataSourceSnapshot<Int, Moment>()
                snapshot.appendSections([0])
                snapshot.appendItems(moments, toSection: 0)
                self.dataSource?.apply(snapshot, animatingDifferences: true)
                self.emptyStackView.isHidden = !moments.isEmpty
                self.collectionView.isHidden = moments.isEmpty
                self.attemptPendingScroll()
            }
            .store(in: &cancellables)
    }

    private func attemptPendingScroll() {
        guard
            let targetID  = pendingScrollMomentID,
            let moment    = viewModel.moment(with: targetID),
            let indexPath = dataSource?.indexPath(for: moment)
        else { return }
        collectionView.layoutIfNeeded()
        collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)
        pendingScrollMomentID = nil
    }

    @objc private func handleBackTap() { onBack?() }

    // MARK: - Layout

    private static func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { _, environment in
            let width    = environment.container.effectiveContentSize.width
            let columns: CGFloat = width > 520 ? 3 : 2
            let fraction = 1 / columns

            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(fraction),
                heightDimension: .fractionalWidth(fraction * 1.28)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 5, bottom: 6, trailing: 5)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .fractionalWidth(fraction * 1.28)
            )
            let group   = NSCollectionLayoutGroup.horizontal(
                layoutSize: groupSize,
                subitems: Array(repeating: item, count: Int(columns))
            )
            let section = NSCollectionLayoutSection(group: group)
            return section
        }
    }
}

// MARK: - UICollectionViewDelegate

extension HistoryViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        guard let moment = dataSource?.itemIdentifier(for: indexPath) else { return }
        onMomentSelected?(moment)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        viewModel.loadMoreIfNeeded(currentIndex: indexPath.item)

        // Entrance animation
        cell.alpha     = 0
        cell.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        UIView.animate(withDuration: 0.28, delay: 0, options: .curveEaseOut) {
            cell.alpha     = 1
            cell.transform = .identity
        }
    }
}
