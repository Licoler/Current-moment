import UIKit

final class IconCircleButton: UIButton {
    init(symbol: String, diameter: CGFloat = 44) {
        super.init(frame: .zero)
        
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: symbol)
        configuration.baseForegroundColor = CMColor.textPrimary
        configuration.contentInsets = .zero
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        self.configuration = configuration
        
        backgroundColor = CMColor.cardElevated.withAlphaComponent(0.92)
        layer.cornerRadius = diameter / 2
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = CMColor.stroke.cgColor
        
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: diameter),
            heightAnchor.constraint(equalToConstant: diameter)
        ])
        
        enableScaleFeedback()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
