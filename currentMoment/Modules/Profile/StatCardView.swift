import UIKit

final class StatCardView: UIView {

    private let valueLabel = UILabel()
    private let titleLabel = UILabel()

    init(value: String, title: String) {
        super.init(frame: .zero)

        backgroundColor    = CMColor.cardElevated
        layer.cornerRadius = 22
        layer.cornerCurve  = .continuous
        layer.borderWidth  = 1
        layer.borderColor  = CMColor.stroke.cgColor

        valueLabel.font          = CMTypography.title2
        valueLabel.textColor     = CMColor.textPrimary
        valueLabel.textAlignment = .center
        valueLabel.text          = value

        titleLabel.font          = CMTypography.footnote
        titleLabel.textColor     = CMColor.textSecondary
        titleLabel.textAlignment = .center
        titleLabel.text          = title

        let stack = UIStackView(arrangedSubviews: [valueLabel, titleLabel])
        stack.axis      = .vertical
        stack.spacing   = 6
        stack.alignment = .fill

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -18)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func update(value: String, title: String) {
        valueLabel.text = value
        titleLabel.text = title
    }
}
