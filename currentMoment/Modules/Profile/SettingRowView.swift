import UIKit

final class SettingRowView: UIButton {
    
    init(symbol: String, title: String, subtitle: String, destructive: Bool = false) {
        super.init(frame: .zero)
        
        backgroundColor = CMColor.cardElevated
        layer.cornerRadius = 22
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = destructive
        ? CMColor.destructive.withAlphaComponent(0.25).cgColor
        : CMColor.stroke.cgColor
        enableScaleFeedback()
        
        let iconView = UIImageView(image: UIImage(systemName: symbol))
        iconView.tintColor = destructive ? CMColor.destructive : CMColor.textPrimary
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        iconView.setContentHuggingPriority(.required, for: .horizontal)
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font  = CMTypography.bodySemibold
        titleLabel.textColor = destructive ? CMColor.destructive : CMColor.textPrimary
        
        let subtitleLabel = UILabel()
        subtitleLabel.text  = subtitle
        subtitleLabel.font  = CMTypography.footnote
        subtitleLabel.textColor = CMColor.textSecondary
        
        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        
        let chevronSymbol = destructive ? "arrow.right.square" : "chevron.right"
        let chevron = UIImageView(image: UIImage(systemName: chevronSymbol))
        chevron.tintColor = destructive ? CMColor.destructive : CMColor.textTertiary
        chevron.setContentHuggingPriority(.required, for: .horizontal)
        
        let rowStack = UIStackView(arrangedSubviews: [iconView, textStack, UIView(), chevron])
        rowStack.axis = .horizontal
        rowStack.alignment = .center
        rowStack.spacing = 14
        
        addSubview(rowStack)
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            rowStack.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            rowStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            rowStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            rowStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18)
        ])
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
