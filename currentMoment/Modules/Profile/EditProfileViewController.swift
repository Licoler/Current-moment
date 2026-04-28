import UIKit
import Combine

final class EditProfileViewController: UIViewController {
    
    private let viewModel: ProfileViewModel
    private var cancellables: Set<AnyCancellable> = []
    
    private let avatarView = AvatarView()
    private let fullNameField = UITextField()
    private let usernameField = UITextField()
    private let saveButton = UIButton(type: .system)
    private let stack = UIStackView()
    private let activity = UIActivityIndicatorView(style: .medium)
    
    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CMColor.background
        setupViews()
        bind()
    }
    
    private func setupViews() {
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(avatarView)
        NSLayoutConstraint.activate([
            avatarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            avatarView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 100),
            avatarView.heightAnchor.constraint(equalToConstant: 100)
        ])
        
        fullNameField.placeholder = "Full name"
        fullNameField.font = CMTypography.body
        fullNameField.borderStyle = .roundedRect
        fullNameField.translatesAutoresizingMaskIntoConstraints = false
        
        usernameField.placeholder = "Username"
        usernameField.font = CMTypography.body
        usernameField.borderStyle = .roundedRect
        usernameField.autocapitalizationType = .none
        usernameField.autocorrectionType = .no
        usernameField.translatesAutoresizingMaskIntoConstraints = false
        
        saveButton.setTitle("Save", for: .normal)
        saveButton.titleLabel?.font = CMTypography.bodySemibold
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(fullNameField)
        stack.addArrangedSubview(usernameField)
        stack.addArrangedSubview(saveButton)
        view.addSubview(stack)
        
        activity.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activity)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            saveButton.heightAnchor.constraint(equalToConstant: 44),
            activity.centerYAnchor.constraint(equalTo: saveButton.centerYAnchor),
            activity.trailingAnchor.constraint(equalTo: saveButton.leadingAnchor, constant: -12)
        ])
        
        if let user = viewModel.user {
            avatarView.configure(with: user, imagePipeline: .shared)
            fullNameField.text = user.fullName
            usernameField.text = user.username
        }
    }
    
    private func bind() {
        viewModel.$isSaving
            .receive(on: DispatchQueue.main)
            .sink { [weak self] saving in
                self?.saveButton.isEnabled = !saving
                if saving { self?.activity.startAnimating() } else { self?.activity.stopAnimating() }
            }
            .store(in: &cancellables)
        
        viewModel.$errorMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] msg in
                let alert = UIAlertController(title: "Error", message: msg, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            }
            .store(in: &cancellables)
    }
    
    @objc private func saveTapped() {
        let fullName = fullNameField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let username = usernameField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        guard !fullName.isEmpty, !username.isEmpty else {
            let alert = UIAlertController(title: "Invalid", message: "Please enter name and username.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        viewModel.saveProfile(fullName: fullName, username: username)
        dismiss(animated: true)
    }
}
