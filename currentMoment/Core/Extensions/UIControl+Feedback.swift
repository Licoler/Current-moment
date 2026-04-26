import UIKit

extension UIControl {
    func enableScaleFeedback() {
        addAction(UIAction { [weak self] _ in
            guard let self else { return }
            UIView.animate(withDuration: 0.16, delay: 0, usingSpringWithDamping: 0.72, initialSpringVelocity: 0.2) {
                self.transform = .identity
            }
        }, for: [.touchUpInside, .touchCancel, .touchDragExit])

        addAction(UIAction { [weak self] _ in
            guard let self else { return }
            UIView.animate(withDuration: 0.14) {
                self.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
            }
        }, for: [.touchDown, .touchDragEnter])
    }
}
