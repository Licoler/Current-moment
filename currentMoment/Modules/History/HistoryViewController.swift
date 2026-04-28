import UIKit
import Combine

final class HistoryViewController: UIViewController {
    
    private let viewModel: HistoryViewModel
    private var cancellables = Set<AnyCancellable>()
    private var dataSource: UICollectionViewDiffableDataSource<Int, Moment>?
    private var pendingScrollMomentID: String?
    
    // MARK: - UI
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = LayoutConstants.itemSpacing
        layout.minimumLineSpacing = LayoutConstants.itemSpacing
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .black
        cv.register(HistoryMomentCell.self, forCellWithReuseIdentifier: HistoryMomentCell.reuseIdentifier)
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "No moments yet.\nSend your first photo!"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = CMTypography.body
        label.textColor = CMColor.textSecondary
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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
        view.backgroundColor = .black
        setupViews()
        setupNavigation()
        bindViewModel()
    }
    
    // MARK: - Public
    
    func scrollToMoment(with id: String) {
        pendingScrollMomentID = id
        attemptPendingScroll()
    }
    
    private func attemptPendingScroll() {
        guard let targetID = pendingScrollMomentID,
              let moment = viewModel.moment(with: targetID),
              let indexPath = dataSource?.indexPath(for: moment) else { return }
        collectionView.layoutIfNeeded()
        collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: true)
        pendingScrollMomentID = nil
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        view.addSubview(collectionView)
        view.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: LayoutConstants.sideInset),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -LayoutConstants.sideInset),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        collectionView.delegate = self
        configureDataSource()
    }
    
    private func setupNavigation() {
        title = "History"
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(handleBack)
        )
    }
    
    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Int, Moment>(collectionView: collectionView) { cv, indexPath, moment in
            let cell = cv.dequeueReusableCell(withReuseIdentifier: HistoryMomentCell.reuseIdentifier, for: indexPath) as! HistoryMomentCell
            cell.configure(with: moment)
            return cell
        }
    }
    
    private func bindViewModel() {
        viewModel.$moments
            .receive(on: DispatchQueue.main)
            .sink { [weak self] moments in
                self?.applySnapshot(moments: moments)
                self?.emptyLabel.isHidden = !moments.isEmpty
                self?.attemptPendingScroll()
            }
            .store(in: &cancellables)
    }
    
    private func applySnapshot(moments: [Moment]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Moment>()
        snapshot.appendSections([0])
        snapshot.appendItems(moments, toSection: 0)
        dataSource?.apply(snapshot, animatingDifferences: true)
    }
    
    @objc private func handleBack() {
        onBack?()
    }
}

// MARK: - Layout Constants
private enum LayoutConstants {
    static let itemSpacing: CGFloat = 12
    static let sideInset: CGFloat = 16
    static let minCellWidth: CGFloat = 100
}

// MARK: - UICollectionViewDelegateFlowLayout
extension HistoryViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let usableWidth = collectionView.bounds.width - LayoutConstants.sideInset * 2
        let totalSpacing = LayoutConstants.itemSpacing
        let columns = max(2, Int((usableWidth + totalSpacing) / (LayoutConstants.minCellWidth + totalSpacing)))
        let totalSpacingWidth = CGFloat(columns - 1) * LayoutConstants.itemSpacing
        let width = (usableWidth - totalSpacingWidth) / CGFloat(columns)
        return CGSize(width: width, height: width) // квадрат
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsets(top: 24, left: 0, bottom: 40, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let moment = dataSource?.itemIdentifier(for: indexPath) else { return }
        onMomentSelected?(moment)
    }
}

// MARK: - Custom Cell
final class HistoryMomentCell: UICollectionViewCell {
    static let reuseIdentifier = "HistoryMomentCell"
    
    private let containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 22
        view.layer.cornerCurve = .continuous
        view.clipsToBounds = true
        view.backgroundColor = .systemPurple
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let initialsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(containerView)
        containerView.addSubview(imageView)
        containerView.addSubview(initialsLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            initialsLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            initialsLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(with moment: Moment) {
        // Инициалы из senderName
        let components = moment.senderName.split(separator: " ")
        let initials = components.compactMap { $0.first }.map(String.init).joined().uppercased()
        initialsLabel.text = initials.isEmpty ? "?" : initials
        
        // Цвет из senderId
        let hash = abs(moment.senderId.hashValue)
        let r = CGFloat((hash >> 16) & 0xFF) / 255.0
        let g = CGFloat((hash >> 8) & 0xFF) / 255.0
        let b = CGFloat(hash & 0xFF) / 255.0
        containerView.backgroundColor = UIColor(red: r, green: g, blue: b, alpha: 1)
        
        // Фото
        if let url = URL(string: moment.imageURL), url.scheme?.hasPrefix("http") == true {
            initialsLabel.isHidden = true
            Task {
                if let (data, _) = try? await URLSession.shared.data(from: url),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        self.imageView.image = image
                    }
                }
            }
        } else {
            initialsLabel.isHidden = false
            imageView.image = nil
        }
    }
}
