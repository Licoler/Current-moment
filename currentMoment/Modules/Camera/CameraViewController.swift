import AVFoundation
import Combine
import UIKit

final class CameraViewController: UIViewController {
    
    private let viewModel: CameraViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI
    private let previewContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.layer.cornerRadius = 24
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private let previewView = CameraPreviewView()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private let friendsButton = makeCircleButton(symbol: "person.2")
    private let profileButton = makeCircleButton(symbol: "person.crop.circle")
    private let appTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "CurrentMoment"
        label.font = CMTypography.headline
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    private let shutterButton = ShutterButton()
    private let flipButton = makeCircleButton(symbol: "arrow.triangle.2.circlepath.camera")
    private let historyButton = makeCircleButton(symbol: "clock.arrow.circlepath")
    
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
    
    var onFriendsButtonTap: (() -> Void)?
    var onProfileButtonTap: (() -> Void)?
    var onHistoryButtonTap: (() -> Void)?
    var onPreviewRequested: ((CapturedMomentAsset) -> Void)?
    
    init(viewModel: CameraViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        setupViews()
        setupConstraints()
        bindViewModel()
        
        // 1. Сначала подготавливаем камеру
        viewModel.prepareAndStart()

        // 2. Когда будет получен кадр, передаём его — также ре-энейблим шуттер
        viewModel.onMomentCaptured = { [weak self] asset in
            DispatchQueue.main.async {
                self?.shutterButton.isEnabled = true
                self?.onPreviewRequested?(asset)
            }
        }
    }
    
    // Start the live session when view is visible and stop when it's going away.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if viewModel.cameraAvailability == .available {
            viewModel.startSession()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.stopSession()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Принудительно обновляем frame слоя – на всякий случай
        previewView.setNeedsLayout()
        previewView.layoutIfNeeded()
    }
    
    private func setupViews() {
        view.addSubview(previewContainer)
        previewContainer.addSubview(previewView)
        
        view.addSubview(loadingIndicator)
        view.addSubview(cameraUnavailableIconView)
        view.addSubview(cameraUnavailableLabel)
        
        [friendsButton, profileButton, appTitleLabel, historyButton, shutterButton, flipButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        // Настройка previewView: связываем сессию
        previewView.session = viewModel.captureSession
        
        // Кнопки
        friendsButton.addTarget(self, action: #selector(handleFriendsTap), for: .touchUpInside)
        profileButton.addTarget(self, action: #selector(handleProfileTap), for: .touchUpInside)
        historyButton.addTarget(self, action: #selector(handleHistoryTap), for: .touchUpInside)
        flipButton.addTarget(self, action: #selector(handleFlipTap), for: .touchUpInside)
        shutterButton.addTarget(self, action: #selector(handleShutterTap), for: .touchUpInside)
    }
    
    private func setupConstraints() {
        let horizontalPadding: CGFloat = 20
        
        NSLayoutConstraint.activate([
            previewContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            previewContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            previewContainer.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -horizontalPadding * 2),
            previewContainer.heightAnchor.constraint(equalTo: previewContainer.widthAnchor),
            
            previewView.topAnchor.constraint(equalTo: previewContainer.topAnchor),
            previewView.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor),
            previewView.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            friendsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            friendsButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            
            appTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            appTitleLabel.centerYAnchor.constraint(equalTo: friendsButton.centerYAnchor),
            
            profileButton.centerYAnchor.constraint(equalTo: friendsButton.centerYAnchor),
            profileButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            
            shutterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shutterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -28),
            
            historyButton.centerYAnchor.constraint(equalTo: shutterButton.centerYAnchor),
            historyButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 44),
            
            flipButton.centerYAnchor.constraint(equalTo: shutterButton.centerYAnchor),
            flipButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -44),
            
            cameraUnavailableIconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cameraUnavailableIconView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -28),
            cameraUnavailableIconView.widthAnchor.constraint(equalToConstant: 60),
            cameraUnavailableIconView.heightAnchor.constraint(equalToConstant: 60),
            
            cameraUnavailableLabel.topAnchor.constraint(equalTo: cameraUnavailableIconView.bottomAnchor, constant: 12),
            cameraUnavailableLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cameraUnavailableLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 40),
            cameraUnavailableLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -40)
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
    
    @objc private func handleFriendsTap()   { onFriendsButtonTap?() }
    @objc private func handleProfileTap()   { onProfileButtonTap?() }
    @objc private func handleHistoryTap()   { onHistoryButtonTap?() }
    @objc private func handleFlipTap()      { viewModel.switchCamera() }
    @objc private func handleShutterTap()   {
        // Prevent rapid double-taps — disable until we receive the captured moment callback
        shutterButton.isEnabled = false
        shutterButton.animateCapturePulse()
        viewModel.captureMoment()
    }
    
    private static func makeCircleButton(symbol: String) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: symbol)
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        let button = UIButton(configuration: config)
        button.tintColor = .white
        button.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        button.layer.cornerRadius = 22
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 44),
            button.heightAnchor.constraint(equalToConstant: 44)
        ])
        return button
    }
}
