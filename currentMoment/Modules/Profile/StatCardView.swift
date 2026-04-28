import UIKit

final class StatCardView: UIView {

    private struct Metrics {
        static let cornerRadius: CGFloat = 22
        static let horizontalInset: CGFloat = 8
        static let verticalInsetTop: CGFloat = 18
        static let verticalInsetBottom: CGFloat = 18
        static let stackSpacing: CGFloat = 6
    }

    private let valueLabel = UILabel()
    private let titleLabel = UILabel()
    private let stack = UIStackView()

    init(value: String, title: String) {
        super.init(frame: .zero)

        setupAppearance()
        setupLabels(value: value, title: title)
        setupStack()
        setupConstraints()
        isAccessibilityElement = false
        accessibilityElements = [valueLabel, titleLabel]
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupAppearance() {
        backgroundColor = CMColor.cardElevated
        layer.cornerRadius = Metrics.cornerRadius
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = CMColor.stroke.cgColor
        translatesAutoresizingMaskIntoConstraints = false
    }

    private func setupLabels(value: String, title: String) {
        valueLabel.font = CMTypography.title2
        valueLabel.textColor = CMColor.textPrimary
        valueLabel.textAlignment = .center
        valueLabel.text = value
        valueLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        titleLabel.font = CMTypography.footnote
        titleLabel.textColor = CMColor.textSecondary
        titleLabel.textAlignment = .center
        titleLabel.text = title
        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
    }

    private func setupStack() {
        stack.axis = .vertical
        stack.spacing = Metrics.stackSpacing
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(valueLabel)
        stack.addArrangedSubview(titleLabel)
        addSubview(stack)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: Metrics.verticalInsetTop),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Metrics.horizontalInset),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Metrics.horizontalInset),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Metrics.verticalInsetBottom)
        ])
    }

    func update(value: String, title: String) {
        valueLabel.text = value
        titleLabel.text = title
    }
}
