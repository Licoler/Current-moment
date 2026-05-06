import UIKit

final class AuthViewController: UIViewController {

    var viewModel: AuthViewModel!
    var onLoginSuccess: (() -> Void)?

    private enum Mode { case login, register }
    private var currentMode: Mode = .login

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let logoImageView = UIImageView()
    private let titleLabel = UILabel()
    private let modeSegmentedControl = UISegmentedControl(items: ["Sign In", "Sign Up"])
    private let fullNameField = UITextField()
    private let usernameField = UITextField()
    private let emailField = UITextField()
    private let passwordField = UITextField()
    private let actionButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let errorLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CMColor.background
        setupViews()
        setupConstraints()
        setupKeyboardHandling()
        updateUIForMode()
        actionButton.addTarget(self, action: #selector(primaryActionTapped), for: .touchUpInside)
        modeSegmentedControl.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
    }

    private func setupViews() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        logoImageView.image = UIImage(systemName: "camera.viewfinder")
        logoImageView.tintColor = .white
        logoImageView.contentMode = .scaleAspectFit

        titleLabel.text = "CurrentMoment"
        titleLabel.font = CMTypography.largeTitle
        titleLabel.textColor = CMColor.textPrimary
        titleLabel.textAlignment = .center

        modeSegmentedControl.selectedSegmentIndex = 0
        modeSegmentedControl.backgroundColor = CMColor.cardElevated
        modeSegmentedControl.selectedSegmentTintColor = .white
        modeSegmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
        modeSegmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)

        fullNameField.placeholder = "Full Name"
        fullNameField.font = CMTypography.body
        fullNameField.backgroundColor = CMColor.cardElevated
        fullNameField.layer.cornerRadius = 14
        fullNameField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        fullNameField.leftViewMode = .always
        fullNameField.autocapitalizationType = .words

        usernameField.placeholder = "Username"
        usernameField.font = CMTypography.body
        usernameField.backgroundColor = CMColor.cardElevated
        usernameField.layer.cornerRadius = 14
        usernameField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        usernameField.leftViewMode = .always
        usernameField.autocapitalizationType = .none

        emailField.placeholder = "Email (optional)"
        emailField.font = CMTypography.body
        emailField.backgroundColor = CMColor.cardElevated
        emailField.layer.cornerRadius = 14
        emailField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        emailField.leftViewMode = .always
        emailField.keyboardType = .emailAddress
        emailField.autocapitalizationType = .none

        passwordField.placeholder = "Password (min. 8 characters)"
        passwordField.font = CMTypography.body
        passwordField.backgroundColor = CMColor.cardElevated
        passwordField.layer.cornerRadius = 14
        passwordField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        passwordField.leftViewMode = .always
        passwordField.isSecureTextEntry = true

        actionButton.configuration = .filled()
        actionButton.configuration?.cornerStyle = .capsule
        actionButton.configuration?.baseBackgroundColor = .white
        actionButton.configuration?.baseForegroundColor = .black
        actionButton.titleLabel?.font = CMTypography.bodySemibold

        activityIndicator.hidesWhenStopped = true
        errorLabel.font = CMTypography.footnote
        errorLabel.textColor = CMColor.destructive
        errorLabel.numberOfLines = 0
        errorLabel.textAlignment = .center
        errorLabel.isHidden = true

        [logoImageView, titleLabel, modeSegmentedControl, fullNameField, usernameField, emailField, passwordField, actionButton, activityIndicator, errorLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
    }

    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            logoImageView.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 40),
            logoImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 80),
            logoImageView.heightAnchor.constraint(equalToConstant: 80),

            titleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 16),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            modeSegmentedControl.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 32),
            modeSegmentedControl.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            modeSegmentedControl.widthAnchor.constraint(equalToConstant: 240),
            modeSegmentedControl.heightAnchor.constraint(equalToConstant: 36),

            fullNameField.topAnchor.constraint(equalTo: modeSegmentedControl.bottomAnchor, constant: 28),
            fullNameField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            fullNameField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            fullNameField.heightAnchor.constraint(equalToConstant: 52),

            usernameField.topAnchor.constraint(equalTo: fullNameField.bottomAnchor, constant: 16),
            usernameField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            usernameField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            usernameField.heightAnchor.constraint(equalToConstant: 52),

            emailField.topAnchor.constraint(equalTo: usernameField.bottomAnchor, constant: 16),
            emailField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            emailField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            emailField.heightAnchor.constraint(equalToConstant: 52),

            passwordField.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 16),
            passwordField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            passwordField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            passwordField.heightAnchor.constraint(equalToConstant: 52),

            actionButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 32),
            actionButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            actionButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 200),
            actionButton.heightAnchor.constraint(equalToConstant: 52),

            activityIndicator.centerYAnchor.constraint(equalTo: actionButton.centerYAnchor),
            activityIndicator.trailingAnchor.constraint(equalTo: actionButton.leadingAnchor, constant: -12),

            errorLabel.topAnchor.constraint(equalTo: actionButton.bottomAnchor, constant: 20),
            errorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            errorLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            errorLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -40)
        ])
    }

    private func updateUIForMode() {
        let isLogin = currentMode == .login
        fullNameField.isHidden = isLogin
        emailField.isHidden = isLogin
        actionButton.setTitle(isLogin ? "Sign In" : "Create Account", for: .normal)
        errorLabel.isHidden = true

        if isLogin {
            let whiteColor = UIColor.white
            usernameField.textColor = whiteColor
            passwordField.textColor = whiteColor
            usernameField.tintColor = whiteColor
            passwordField.tintColor = whiteColor
            setPlaceholderColor(for: usernameField, color: whiteColor)
            setPlaceholderColor(for: passwordField, color: whiteColor)
        } else {
            usernameField.textColor = nil
            passwordField.textColor = nil
            usernameField.tintColor = nil
            passwordField.tintColor = nil
            let visibleGray = UIColor.lightGray
            setPlaceholderColor(for: usernameField, color: visibleGray)
            setPlaceholderColor(for: passwordField, color: visibleGray)
            setPlaceholderColor(for: fullNameField, color: visibleGray)
            setPlaceholderColor(for: emailField, color: visibleGray)
        }
    }

    private func setPlaceholderColor(for textField: UITextField, color: UIColor) {
        let placeholderText = textField.placeholder ?? ""
        let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: color, .font: textField.font ?? CMTypography.body]
        textField.attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: attributes)
    }

    @objc private func modeChanged() {
        currentMode = modeSegmentedControl.selectedSegmentIndex == 0 ? .login : .register
        updateUIForMode()
    }

    @objc private func primaryActionTapped() {
        let username = usernameField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let password = passwordField.text ?? ""

        if currentMode == .login {
            guard !username.isEmpty, !password.isEmpty else {
                showError("Please enter username and password")
                return
            }
            performLogin(username: username, password: password)
        } else {
            let fullName = fullNameField.text?.trimmingCharacters(in: .whitespaces) ?? ""
            let email = emailField.text?.trimmingCharacters(in: .whitespaces) ?? ""
            guard !fullName.isEmpty, !username.isEmpty, password.count >= 8 else {
                showError("Full name, username and password (min 8 chars) required")
                return
            }
            performRegistration(fullName: fullName, username: username, email: email, password: password)
        }
    }

    private func performLogin(username: String, password: String) {
        setLoading(true)
        Task {
            do {
                try await viewModel.login(username: username, password: password)
                await MainActor.run { self.onLoginSuccess?() }
            } catch {
                await MainActor.run { self.showError(error.localizedDescription); self.setLoading(false) }
            }
        }
    }

    private func performRegistration(fullName: String, username: String, email: String, password: String) {
        setLoading(true)
        Task {
            do {
                try await viewModel.register(username: username, email: email, password: password, fullName: fullName)
                await MainActor.run { self.onLoginSuccess?() }
            } catch {
                await MainActor.run { self.showError(error.localizedDescription); self.setLoading(false) }
            }
        }
    }

    private func setLoading(_ loading: Bool) {
        actionButton.isEnabled = !loading
        if loading { activityIndicator.startAnimating() } else { activityIndicator.stopAnimating() }
    }

    private func showError(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    // MARK: - Keyboard handling
    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let inset = keyboardFrame.height - view.safeAreaInsets.bottom
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: inset, right: 0)
        scrollView.scrollIndicatorInsets = scrollView.contentInset
        let activeField = currentMode == .login ? usernameField : fullNameField
        let rect = activeField.convert(activeField.bounds, to: scrollView)
        scrollView.scrollRectToVisible(rect, animated: true)
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
}
