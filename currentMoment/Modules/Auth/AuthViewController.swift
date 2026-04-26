import Combine
import UIKit

final class AuthViewController: UIViewController {

    private let viewModel: AuthViewModel
    private var cancellables: Set<AnyCancellable> = []

    private let titleLabel        = UILabel()
    private let subtitleLabel     = UILabel()
    private let cardView          = CardContainerView(cornerRadius: 28, alpha: 0.96)
    private let stackView         = UIStackView()
    private let demoButton        = PrimaryButton(title: "Continue with Demo")
    private let guestButton       = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let errorLabel        = UILabel()

    init(viewModel: AuthViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CMColor.background
        setupViews()
        bindViewModel()
    }

    private func setupViews() {
        // ── Labels ──────────────────────────────────────────────────────────
        titleLabel.text          = "CurrentMoment"
        titleLabel.font          = CMTypography.largeTitle
        titleLabel.textColor     = CMColor.textPrimary
        titleLabel.textAlignment = .center

        subtitleLabel.text          = "UIKit demo build with Firebase-ready auth and no paid Apple capabilities."
        subtitleLabel.font          = CMTypography.body
        subtitleLabel.textColor     = CMColor.textSecondary
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        // ── Stack ────────────────────────────────────────────────────────────
        stackView.axis      = .vertical
        stackView.spacing   = 16
        stackView.alignment = .fill

        // ── Demo button ──────────────────────────────────────────────────────
        demoButton.addTarget(self, action: #selector(handleDemoTap), for: .touchUpInside)

        // ── Guest button ─────────────────────────────────────────────────────
        var guestConfig = UIButton.Configuration.plain()
        guestConfig.title                = "Anonymous session"
        guestConfig.baseForegroundColor  = CMColor.textSecondary
        guestConfig.contentInsets        = NSDirectionalEdgeInsets(top: 12, leading: 18, bottom: 12, trailing: 18)
        guestButton.configuration        = guestConfig
        guestButton.addTarget(self, action: #selector(handleGuestTap), for: .touchUpInside)
        guestButton.enableScaleFeedback()

        // ── Activity + error ─────────────────────────────────────────────────
        activityIndicator.hidesWhenStopped = true

        errorLabel.font          = CMTypography.footnote
        errorLabel.textColor     = CMColor.destructive
        errorLabel.numberOfLines = 0
        errorLabel.textAlignment = .center
        errorLabel.isHidden      = true

        // ── Assemble title stack ─────────────────────────────────────────────
        let titleStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        titleStack.axis    = .vertical
        titleStack.spacing = 12

        // ── Assemble card ────────────────────────────────────────────────────
        stackView.addArrangedSubview(titleStack)
        stackView.addArrangedSubview(demoButton)
        stackView.addArrangedSubview(activityIndicator)
        stackView.addArrangedSubview(guestButton)
        stackView.addArrangedSubview(errorLabel)

        cardView.addSubview(stackView)

        view.addSubview(cardView)

        cardView.translatesAutoresizingMaskIntoConstraints  = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        demoButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // stackView fills cardView with padding
            stackView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 28),
            stackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),
            stackView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -24),

            // cardView centred on full view (not safeArea)
            cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            cardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            demoButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    private func bindViewModel() {
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.demoButton.isEnabled  = !isLoading
                self?.guestButton.isEnabled = !isLoading
                isLoading ? self?.activityIndicator.startAnimating() : self?.activityIndicator.stopAnimating()
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.errorLabel.text    = message
                self?.errorLabel.isHidden = message == nil
            }
            .store(in: &cancellables)
    }

    @objc private func handleDemoTap()  { viewModel.continueWithDemo() }
    @objc private func handleGuestTap() { viewModel.continueAsGuest() }
}
