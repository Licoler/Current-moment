import UIKit

final class ShutterButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        layer.cornerRadius = 44
        layer.borderWidth = 4
        layer.borderColor = UIColor.white.cgColor
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 88),
            heightAnchor.constraint(equalToConstant: 88)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
    func animateCapturePulse() {
        UIView.animate(withDuration: 0.12) {
            self.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
        } completion: { _ in
            UIView.animate(withDuration: 0.22, delay: 0, usingSpringWithDamping: 0.72, initialSpringVelocity: 0.3) {
                self.transform = .identity
            }
        }
    }
}
