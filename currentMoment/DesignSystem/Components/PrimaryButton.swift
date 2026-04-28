import UIKit

final class PrimaryButton: UIButton {
    init(title: String, imageSystemName: String? = nil) {
        super.init(frame: .zero)
        
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.image = imageSystemName.flatMap(UIImage.init(systemName:))
        configuration.imagePadding = 8
        configuration.baseBackgroundColor = CMColor.accent
        configuration.baseForegroundColor = CMColor.background
        configuration.cornerStyle = .capsule
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = CMTypography.bodySemibold
            return outgoing
        }
        self.configuration = configuration
        
        enableScaleFeedback()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
