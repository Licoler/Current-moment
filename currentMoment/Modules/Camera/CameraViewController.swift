import AVFoundation
import Combine
import UIKit

final class CameraViewController: UIViewController {

    private let viewModel: CameraViewModel
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI

    private let previewView  = CameraPreviewView()
    private let overlayView  = UIView()
    private var topGradientLayer:    CAGradientLayer?
    private var bottomGradientLayer: CAGradientLayer?

    private let loadingIndicator          = UIActivityIndicatorView(style: .large)
    private let cameraUnavailableIconView = UIImageView(image: UIImage(systemName: "camera"))
    private let cameraUnavailableLabel    = UILabel()

    private let friendsButton  = CameraViewController.makeCircleButton(symbol: "person.2")
    private let profileButton  = CameraViewController.makeCircleButton(symbol: "person.crop.circle")
    private let appTitleLabel  = UILabel()
    private let shutterButton  = ShutterButton()
    private let flipButton     = CameraViewController.makeCircleButton(symbol: "arrow.triangle.2.circlepath.camera")
    private let historyButton  = CameraViewController.makeCircleButton(symbol: "clock.arrow.circlepath")

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
        setupSubviews()
        setupConstraints()
        bindViewModel()

        viewModel.prepareAndStart()
        viewModel.onMomentCaptured = { [weak self] asset in
            self?.onPreviewRequested?(asset)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.stopSession()
    }

    // Градиенты обновляем здесь — только тут bounds точные
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        topGradientLayer?.frame    = CGRect(x: 0, y: 0,
                                            width:  view.bounds.width,
                                            height: 180)
        bottomGradientLayer?.frame = CGRect(x: 0,
                                            y:      view.bounds.height - 240,
                                            width:  view.bounds.width,
                                            height: 240)
    }

    // MARK: - Setup subviews

    private func setupSubviews() {
        // Preview — весь экран, под notch и home indicator
        previewView.translatesAutoresizingMaskIntoConstraints = false
        previewView.capturePreviewLayer.session      = viewModel.captureSession
        previewView.capturePreviewLayer.videoGravity = .resizeAspectFill
        view.addSubview(previewView)

        // Overlay
        overlayView.backgroundColor = .clear
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayView)

        // Верхний градиент — frame выставится в viewDidLayoutSubviews
        let topGrad   = makeGradient(from: UIColor.black.withAlphaComponent(0.7), to: .clear)
        let botGrad   = makeGradient(from: .clear, to: UIColor.black.withAlphaComponent(0.8))
        overlayView.layer.addSublayer(topGrad)
        overlayView.layer.addSublayer(botGrad)
        topGradientLayer    = topGrad
        bottomGradientLayer = botGrad

        // Loading
        loadingIndicator.color = .white
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.startAnimating()
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        overlayView.addSubview(loadingIndicator)

        // Title
        appTitleLabel.text      = "CurrentMoment"
        appTitleLabel.font      = CMTypography.headline
        appTitleLabel.textColor = .white
        appTitleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Unavailable state
        cameraUnavailableIconView.tintColor = CMColor.textTertiary
        cameraUnavailableIconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 48)
        cameraUnavailableIconView.isHidden  = true
        cameraUnavailableIconView.translatesAutoresizingMaskIntoConstraints = false

        cameraUnavailableLabel.font          = CMTypography.body
        cameraUnavailableLabel.textColor     = CMColor.textSecondary
        cameraUnavailableLabel.textAlignment = .center
        cameraUnavailableLabel.numberOfLines = 0
        cameraUnavailableLabel.isHidden      = true
        cameraUnavailableLabel.translatesAutoresizingMaskIntoConstraints = false

        // Add all to overlay
        [friendsButton, profileButton, appTitleLabel,
         historyButton, shutterButton, flipButton,
         cameraUnavailableIconView, cameraUnavailableLabel].forEach { overlayView.addSubview($0) }

        // Actions
        shutterButton.addTarget(self, action: #selector(handleShutterTap),    for: .touchUpInside)
        flipButton.addTarget(self,    action: #selector(handleFlipTap),        for: .touchUpInside)
        friendsButton.addTarget(self, action: #selector(handleFriendsTap),    for: .touchUpInside)
        profileButton.addTarget(self, action: #selector(handleProfileTap),    for: .touchUpInside)
        historyButton.addTarget(self, action: #selector(handleHistoryTap),    for: .touchUpInside)
    }

    private func setupConstraints() {
        shutterButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Preview — весь экран
            previewView.topAnchor.constraint(equalTo: view.topAnchor),
            previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // Overlay — весь экран
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // Loading
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            // Top bar — под notch
            friendsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            friendsButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            appTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            appTitleLabel.centerYAnchor.constraint(equalTo: friendsButton.centerYAnchor),

            profileButton.centerYAnchor.constraint(equalTo: friendsButton.centerYAnchor),
            profileButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // Shutter
            shutterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shutterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -28),
            shutterButton.widthAnchor.constraint(equalToConstant: 82),
            shutterButton.heightAnchor.constraint(equalToConstant: 82),

            // History & Flip по бокам
            historyButton.centerYAnchor.constraint(equalTo: shutterButton.centerYAnchor),
            historyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 44),

            flipButton.centerYAnchor.constraint(equalTo: shutterButton.centerYAnchor),
            flipButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -44),

            // Unavailable
            cameraUnavailableIconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cameraUnavailableIconView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -28),
            cameraUnavailableLabel.topAnchor.constraint(equalTo: cameraUnavailableIconView.bottomAnchor, constant: 12),
            cameraUnavailableLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cameraUnavailableLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            cameraUnavailableLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40)
        ])
    }

    // MARK: - Bind

    private func bindViewModel() {
        viewModel.$cameraAvailability
            .receive(on: DispatchQueue.main)
            .sink { [weak self] availability in
                let ready = availability == .available || availability == .simulator
                self?.cameraUnavailableIconView.isHidden = ready
                self?.cameraUnavailableLabel.isHidden    = ready
                self?.cameraUnavailableLabel.text        = availability.statusMessage
                if availability != .unavailable {
                    self?.loadingIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    @objc private func handleFriendsTap()    { onFriendsButtonTap?() }
    @objc private func handleProfileTap()    { onProfileButtonTap?() }
    @objc private func handleHistoryTap()    { onHistoryButtonTap?() }

    @objc private func handleFlipTap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        viewModel.switchCamera()
    }

    @objc private func handleShutterTap() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        shutterButton.animateCapturePulse()
        viewModel.captureMoment()
    }

    // MARK: - Helpers

    private func makeGradient(from start: UIColor, to end: UIColor) -> CAGradientLayer {
        let layer       = CAGradientLayer()
        layer.colors    = [start.cgColor, end.cgColor]
        layer.locations = [0, 1]
        return layer
    }

    private static func makeCircleButton(symbol: String) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: symbol)
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        let button              = UIButton(configuration: config)
        button.tintColor        = .white
        button.backgroundColor  = UIColor.white.withAlphaComponent(0.15)
        button.layer.cornerRadius = 22
        button.clipsToBounds    = true
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 44),
            button.heightAnchor.constraint(equalToConstant: 44)
        ])
        return button
    }
}
