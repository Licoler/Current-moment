import AVFoundation
import Combine
import UIKit

final class CameraViewController: UIViewController {

    private let viewModel: CameraViewModel
    private var cancellables: Set<AnyCancellable> = []

    private let previewView = CameraPreviewView()
    private let overlayView = UIView()
    private var topGradientLayer: CAGradientLayer?

    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    private let cameraUnavailableIconView = UIImageView(image: UIImage(systemName: "camera"))
    private let cameraUnavailableLabel    = UILabel()

    private let friendsButton   = IconCircleButton(symbol: "person.2")
    private let profileButton   = IconCircleButton(symbol: "person.crop.circle")
    private let appTitleLabel   = UILabel()

    private let historyPillButton = UIButton(type: .system)
    private let controlsCardView  = CardContainerView(cornerRadius: 28, alpha: 0.82)
    private let captureModeControl = UISegmentedControl(items: CameraCaptureMode.allCases.map(\.title))
    private let historyButton      = IconCircleButton(symbol: "clock.arrow.circlepath")
    private let shutterButton      = ShutterButton()
    private let flipCameraButton   = IconCircleButton(symbol: "arrow.triangle.2.circlepath.camera")

    var onFriendsButtonTap: (() -> Void)?
    var onProfileButtonTap: (() -> Void)?
    var onHistoryButtonTap: (() -> Void)?
    var onPreviewRequested: ((CapturedMomentAsset) -> Void)?

    init(viewModel: CameraViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CMColor.background
        setupSubviews()
        setupConstraints()
        bindViewModel()

        viewModel.prepareAndStart()   // ← единый метод подготовки и запуска
        viewModel.onMomentCaptured = { [weak self] asset in
            self?.onPreviewRequested?(asset)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // start уже вызван через prepareAndStart, дополнительно не нужен
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.stopSession()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        topGradientLayer?.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 220)
    }

    private func setupSubviews() {
        previewView.translatesAutoresizingMaskIntoConstraints = false
        previewView.capturePreviewLayer.session = viewModel.captureSession
        previewView.capturePreviewLayer.videoGravity = .resizeAspectFill
        view.addSubview(previewView)

        overlayView.backgroundColor = .clear
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayView)

        let gradient = CAGradientLayer()
        gradient.colors = [UIColor.black.withAlphaComponent(0.72).cgColor, UIColor.clear.cgColor]
        gradient.locations = [0, 1]
        overlayView.layer.addSublayer(gradient)
        topGradientLayer = gradient

        // Индикатор загрузки
        loadingIndicator.color = .white
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.startAnimating()
        overlayView.addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false

        appTitleLabel.text = "CurrentMoment"
        appTitleLabel.font = CMTypography.headline
        appTitleLabel.textColor = CMColor.textPrimary

        friendsButton.addTarget(self, action: #selector(handleFriendsTap), for: .touchUpInside)
        profileButton.addTarget(self, action: #selector(handleProfileTap), for: .touchUpInside)

        cameraUnavailableIconView.tintColor = CMColor.textTertiary
        cameraUnavailableIconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 48)
        cameraUnavailableIconView.isHidden = true

        cameraUnavailableLabel.font = CMTypography.body
        cameraUnavailableLabel.textColor = CMColor.textSecondary
        cameraUnavailableLabel.textAlignment = .center
        cameraUnavailableLabel.numberOfLines = 0
        cameraUnavailableLabel.isHidden = true

        var pillConfig = UIButton.Configuration.gray()
        pillConfig.title = "History"
        pillConfig.image = UIImage(systemName: "square.grid.2x2")
        pillConfig.imagePadding = 8
        pillConfig.baseForegroundColor = CMColor.textPrimary
        pillConfig.baseBackgroundColor = UIColor.white.withAlphaComponent(0.08)
        pillConfig.cornerStyle = .capsule
        historyPillButton.configuration = pillConfig
        historyPillButton.addTarget(self, action: #selector(handleHistoryTap), for: .touchUpInside)

        captureModeControl.selectedSegmentIndex = 0
        captureModeControl.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        captureModeControl.selectedSegmentTintColor = UIColor.white.withAlphaComponent(0.18)
        captureModeControl.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: CMTypography.footnote], for: .normal)
        captureModeControl.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: CMTypography.footnote], for: .selected)
        captureModeControl.addAction(UIAction { [weak self] _ in
            self?.viewModel.selectCaptureMode(at: self?.captureModeControl.selectedSegmentIndex ?? 0)
        }, for: .valueChanged)

        historyButton.addTarget(self, action: #selector(handleHistoryTap), for: .touchUpInside)
        flipCameraButton.addTarget(self, action: #selector(handleFlipCameraTap), for: .touchUpInside)
        shutterButton.addTarget(self, action: #selector(handleShutterTap), for: .touchUpInside)

        controlsCardView.addSubview(captureModeControl)
        controlsCardView.addSubview(historyButton)
        controlsCardView.addSubview(shutterButton)
        controlsCardView.addSubview(flipCameraButton)

        [friendsButton, appTitleLabel, profileButton, historyPillButton, controlsCardView,
         cameraUnavailableIconView, cameraUnavailableLabel].forEach {
            ($0 as UIView).translatesAutoresizingMaskIntoConstraints = false
            overlayView.addSubview($0 as UIView)
        }
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: view.topAnchor),
            previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            friendsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            friendsButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            appTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            appTitleLabel.centerYAnchor.constraint(equalTo: friendsButton.centerYAnchor),

            profileButton.centerYAnchor.constraint(equalTo: friendsButton.centerYAnchor),
            profileButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            historyPillButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            historyPillButton.bottomAnchor.constraint(equalTo: controlsCardView.topAnchor, constant: -18),

            controlsCardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
            controlsCardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
            controlsCardView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -18),

            captureModeControl.topAnchor.constraint(equalTo: controlsCardView.topAnchor, constant: 16),
            captureModeControl.centerXAnchor.constraint(equalTo: controlsCardView.centerXAnchor),
            captureModeControl.widthAnchor.constraint(equalToConstant: 168),

            shutterButton.centerXAnchor.constraint(equalTo: controlsCardView.centerXAnchor),
            shutterButton.topAnchor.constraint(equalTo: captureModeControl.bottomAnchor, constant: 18),
            shutterButton.bottomAnchor.constraint(equalTo: controlsCardView.bottomAnchor, constant: -16),

            historyButton.leadingAnchor.constraint(equalTo: controlsCardView.leadingAnchor, constant: 22),
            historyButton.centerYAnchor.constraint(equalTo: shutterButton.centerYAnchor),

            flipCameraButton.trailingAnchor.constraint(equalTo: controlsCardView.trailingAnchor, constant: -22),
            flipCameraButton.centerYAnchor.constraint(equalTo: shutterButton.centerYAnchor),

            cameraUnavailableIconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cameraUnavailableIconView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -28),

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
                let cameraReady = availability == .available
                self?.cameraUnavailableIconView.isHidden = cameraReady
                self?.cameraUnavailableLabel.isHidden    = cameraReady
                if cameraReady {
                    self?.loadingIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)

        viewModel.$statusMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.cameraUnavailableLabel.text = message
            }
            .store(in: &cancellables)
    }

    @objc private func handleFriendsTap()   { onFriendsButtonTap?() }
    @objc private func handleProfileTap()   { onProfileButtonTap?() }
    @objc private func handleHistoryTap()   { onHistoryButtonTap?() }
    @objc private func handleFlipCameraTap(){ viewModel.switchCamera() }
    @objc private func handleShutterTap()   {
        shutterButton.animateCapturePulse()
        viewModel.captureMoment()
    }
}
