import UIKit

final class CardContainerView: UIView {
    init(cornerRadius: CGFloat = 24, alpha: CGFloat = 1) {
        super.init(frame: .zero)
        backgroundColor = CMColor.cardElevated.withAlphaComponent(alpha)
        layer.cornerRadius = cornerRadius
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = CMColor.stroke.cgColor
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
