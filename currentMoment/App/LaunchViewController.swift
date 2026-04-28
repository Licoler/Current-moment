import UIKit

final class LaunchViewController: UIViewController {
    
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = CMColor.background
        setupViews()
    }
    
    private func setupViews() {
        titleLabel.text = "CurrentMoment"
        titleLabel.font = CMTypography.largeTitle
        titleLabel.textColor     = CMColor.textPrimary
        titleLabel.textAlignment = .center
        
        subtitleLabel.text = "Private social moments."
        subtitleLabel.font = CMTypography.body
        subtitleLabel.textColor = CMColor.textSecondary
        subtitleLabel.textAlignment = .center
        
        activityIndicator.color = CMColor.textPrimary
        activityIndicator.startAnimating()
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, activityIndicator])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32)
        ])
    }
}
