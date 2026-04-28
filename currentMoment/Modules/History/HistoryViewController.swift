import UIKit
import Combine

final class HistoryViewController: UIViewController {
    
    private let viewModel: HistoryViewModel
    private var cancellables = Set<AnyCancellable>()
    private var dataSource: UICollectionViewDiffableDataSource<Int, Moment>?
    private var pendingScrollMomentID: String?
    
    // Кастомная кнопка назад (на случай, если навбар всё ещё скрыт)
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
        label.text = "History"
        label.font = CMTypography.title2
        label.textColor = CMColor.textPrimary
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .black
        cv.register(HistoryMomentCell.self, forCellWithReuseIdentifier: HistoryMomentCell.reuseIdentifier)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.delegate = self
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
    
    var onBack: (() -> Void)?
    var onMomentSelected: ((Moment) -> Void)?
    
    init(viewModel: HistoryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupViews()
        bindViewModel()
        configureDataSource()
        
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        title = "History"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(handleBack)
        )
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    private func setupViews() {
        view.addSubview(collectionView)
        view.addSubview(emptyLabel)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
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
    
    @objc private func handleBack() {
        onBack?()
    }
}

extension HistoryViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let usableWidth = collectionView.bounds.width - 32
        let spacing: CGFloat = 10
        let columns = max(2, Int((usableWidth + spacing) / 100))
        let totalSpacing = CGFloat(columns - 1) * spacing
        let width = (usableWidth - totalSpacing) / CGFloat(columns)
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsets(top: 24, left: 0, bottom: 40, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let moment = dataSource?.itemIdentifier(for: indexPath) else { return }
        onMomentSelected?(moment)
    }
}

final class HistoryMomentCell: UICollectionViewCell {
    static let reuseIdentifier = "HistoryMomentCell"
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
        contentView.layer.cornerRadius = 22
        contentView.layer.cornerCurve = .continuous
        contentView.clipsToBounds = true
        contentView.backgroundColor = .darkGray
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(with moment: Moment) {
        if let url = URL(string: moment.imageURL), url.scheme?.hasPrefix("http") == true {
            Task {
                if let (data, _) = try? await URLSession.shared.data(from: url),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        self.imageView.image = image
                    }
                }
            }
        } else {
            imageView.image = nil
        }
    }
}
