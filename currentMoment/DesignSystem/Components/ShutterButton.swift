import UIKit

final class ShutterButton: UIButton {
    private let outerRing = UIView()
    private let innerFill = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 82),
            heightAnchor.constraint(equalToConstant: 82)
        ])

        outerRing.layer.cornerRadius = 41
        outerRing.layer.borderWidth = 4
        outerRing.layer.borderColor = UIColor.white.withAlphaComponent(0.9).cgColor
        outerRing.isUserInteractionEnabled = false

        innerFill.backgroundColor = UIColor.white
        innerFill.layer.cornerRadius = 31
        innerFill.isUserInteractionEnabled = false

        addSubview(outerRing)
        addSubview(innerFill)
        outerRing.pinEdges(to: self)
        innerFill.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            innerFill.centerXAnchor.constraint(equalTo: centerXAnchor),
            innerFill.centerYAnchor.constraint(equalTo: centerYAnchor),
            innerFill.widthAnchor.constraint(equalToConstant: 62),
            innerFill.heightAnchor.constraint(equalToConstant: 62)
        ])

        enableScaleFeedback()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func animateCapturePulse() {
        UIView.animate(withDuration: 0.12, animations: {
            self.innerFill.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
            self.outerRing.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }, completion: { _ in
            UIView.animate(withDuration: 0.22, delay: 0, usingSpringWithDamping: 0.72, initialSpringVelocity: 0.3) {
                self.innerFill.transform = .identity
                self.outerRing.transform = .identity
            }
        })
    }
}
