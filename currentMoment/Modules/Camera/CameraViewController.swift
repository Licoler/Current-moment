import AVFoundation
import Combine
import UIKit

final class CameraViewController: UIViewController {
    
    private let viewModel: CameraViewModel
    private var cancellables = Set<AnyCancellable>()
    private var isFlashOn = false
    
    // MARK: - UI
    
    private let previewView = CameraPreviewView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    // Верхние кнопки
    private let friendsButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "person.2")
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        let button = UIButton(configuration: config)
        button.tintColor = .white
        button.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        button.layer.cornerRadius = 22
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 44),
            button.heightAnchor.constraint(equalToConstant: 44)
        ])
        return button
    }()
    
    private let profileButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "person.crop.circle")
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        let button = UIButton(configuration: config)
        button.tintColor = .white
        button.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        button.layer.cornerRadius = 22
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 44),
            button.heightAnchor.constraint(equalToConstant: 44)
        ])
        return button
    }()
    
    private let appTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "CurrentMoment"
        label.font = CMTypography.headline
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Кнопка History (под верхней панелью)
    private let historyButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "History"
        config.image = UIImage(systemName: "chevron.right")
        config.imagePlacement = .trailing
        config.imagePadding = 6
        config.baseForegroundColor = .white
        let button = UIButton(configuration: config)
        button.titleLabel?.font = CMTypography.bodySemibold
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // Нижние кнопки камеры
    private let flashButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "bolt.slash.fill")
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        let button = UIButton(configuration: config)
        button.tintColor = .white
        button.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        button.layer.cornerRadius = 28
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 56),
            button.heightAnchor.constraint(equalToConstant: 56)
        ])
        return button
    }()
    
    private let flipButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "arrow.triangle.2.circlepath.camera")
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        let button = UIButton(configuration: config)
        button.tintColor = .white
        button.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        button.layer.cornerRadius = 28
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 56),
            button.heightAnchor.constraint(equalToConstant: 56)
        ])
        return button
    }()
    
    private let shutterButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .white
        button.layer.cornerRadius = 44
        button.layer.borderWidth = 4
        button.layer.borderColor = UIColor.white.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 88),
            button.heightAnchor.constraint(equalToConstant: 88)
        ])
        return button
    }()
    
    private let cameraUnavailableIconView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "camera"))
        iv.tintColor = CMColor.textTertiary
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    private let cameraUnavailableLabel: UILabel = {
        let label = UILabel()
        label.font = CMTypography.body
        label.textColor = CMColor.textSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Callbacks
    
    var onFriendsButtonTap: (() -> Void)?
    var onProfileButtonTap: (() -> Void)?
    var onHistoryButtonTap: (() -> Void)?
    var onPreviewRequested: ((CapturedMomentAsset) -> Void)?
    
    // MARK: - Init
    
    init(viewModel: CameraViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        setupViews()
        setupConstraints()
        bindViewModel()
        
        previewView.session = viewModel.captureSession
        viewModel.prepareAndStart()
        viewModel.onMomentCaptured = { [weak self] asset in
            self?.onPreviewRequested?(asset)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if viewModel.cameraAvailability == .available {
            viewModel.startSession()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.stopSession()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewView.layer.cornerRadius = 24
        previewView.clipsToBounds = true
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        previewView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewView)
        view.addSubview(loadingIndicator)
        view.addSubview(cameraUnavailableIconView)
        view.addSubview(cameraUnavailableLabel)
        
        [friendsButton, profileButton, appTitleLabel, historyButton,
         flashButton, flipButton, shutterButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        friendsButton.addTarget(self, action: #selector(handleFriendsTap), for: .touchUpInside)
        profileButton.addTarget(self, action: #selector(handleProfileTap), for: .touchUpInside)
        historyButton.addTarget(self, action: #selector(handleHistoryTap), for: .touchUpInside)
        flashButton.addTarget(self, action: #selector(handleFlashTap), for: .touchUpInside)
        flipButton.addTarget(self, action: #selector(handleFlipTap), for: .touchUpInside)
        shutterButton.addTarget(self, action: #selector(handleShutterTap), for: .touchUpInside)
    }
    
    private func setupConstraints() {
        let sidePadding: CGFloat = 20
        
        NSLayoutConstraint.activate([
            previewView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            previewView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            previewView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -sidePadding * 2),
            previewView.heightAnchor.constraint(equalTo: previewView.widthAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // Верхняя панель
            friendsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            friendsButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            appTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            appTitleLabel.centerYAnchor.constraint(equalTo: friendsButton.centerYAnchor),
            
            profileButton.centerYAnchor.constraint(equalTo: friendsButton.centerYAnchor),
            profileButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // History кнопка под верхней панелью, над камерой
            historyButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            historyButton.bottomAnchor.constraint(equalTo: previewView.topAnchor, constant: -16),
            
            // Нижние кнопки под камерой
            shutterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shutterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32),
            
            flashButton.centerYAnchor.constraint(equalTo: shutterButton.centerYAnchor),
            flashButton.trailingAnchor.constraint(equalTo: shutterButton.leadingAnchor, constant: -32),
            
            flipButton.centerYAnchor.constraint(equalTo: shutterButton.centerYAnchor),
            flipButton.leadingAnchor.constraint(equalTo: shutterButton.trailingAnchor, constant: 32),
            
            cameraUnavailableIconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cameraUnavailableIconView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -28),
            cameraUnavailableIconView.widthAnchor.constraint(equalToConstant: 60),
            cameraUnavailableIconView.heightAnchor.constraint(equalToConstant: 60),
            
            cameraUnavailableLabel.topAnchor.constraint(equalTo: cameraUnavailableIconView.bottomAnchor, constant: 12),
            cameraUnavailableLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cameraUnavailableLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            cameraUnavailableLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40)
        ])
    }
    
    private func bindViewModel() {
        viewModel.$cameraAvailability
            .receive(on: DispatchQueue.main)
            .sink { [weak self] availability in
                let isAvailable = availability == .available
                self?.cameraUnavailableIconView.isHidden = isAvailable
                self?.cameraUnavailableLabel.isHidden = isAvailable
                if isAvailable {
                    self?.loadingIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    @objc private func handleFlashTap() {
        isFlashOn.toggle()
        let imageName = isFlashOn ? "bolt.fill" : "bolt.slash.fill"
        flashButton.configuration?.image = UIImage(systemName: imageName)
        viewModel.setFlashMode(isFlashOn ? .on : .off)
    }
    
    @objc private func handleFlipTap() {
        viewModel.switchCamera()
    }
    
    @objc private func handleShutterTap() {
        UIView.animate(withDuration: 0.12, animations: {
            self.shutterButton.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
        }, completion: { _ in
            UIView.animate(withDuration: 0.22, delay: 0, usingSpringWithDamping: 0.72, initialSpringVelocity: 0.3) {
                self.shutterButton.transform = .identity
            }
        })
        viewModel.captureMoment()
    }
    
    @objc private func handleFriendsTap() {
        onFriendsButtonTap?()
    }
    
    @objc private func handleProfileTap() {
        onProfileButtonTap?()
    }
    
    @objc private func handleHistoryTap() {
        onHistoryButtonTap?()
    }
}
