import UIKit

/// Генерирует фиктивное изображение для симулятора и случаев без камеры.
enum DemoCaptureImageFactory {

    static func makeImage(size: CGSize = CGSize(width: 960, height: 1280)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let bounds = CGRect(origin: .zero, size: size)

            // Фоновый градиент
            let gradientColors = [
                UIColor(hex: "#0F172A") ?? .black,
                UIColor(hex: "#1D4ED8") ?? .systemBlue,
                UIColor(hex: "#FB7185") ?? .systemPink
            ]

            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let cgColors   = gradientColors.map(\.cgColor) as CFArray

            if let gradient = CGGradient(colorsSpace: colorSpace, colors: cgColors, locations: [0, 0.55, 1]) {
                context.cgContext.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 0),
                    end:   CGPoint(x: size.width, y: size.height),
                    options: []
                )
            }

            // Декоративные окружности
            UIColor.white.withAlphaComponent(0.12).setFill()
            context.cgContext.fillEllipse(in: CGRect(x: 56,  y: 140, width: 280, height: 280))
            context.cgContext.fillEllipse(in: CGRect(x: 420, y: 720, width: 360, height: 360))

            // Типографика
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left

            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 74, weight: .bold),
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraphStyle
            ]
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 32, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.82),
                .paragraphStyle: paragraphStyle
            ]
            let captionAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 28, weight: .regular),
                .foregroundColor: UIColor.white.withAlphaComponent(0.74),
                .paragraphStyle: paragraphStyle
            ]

            let horizontalInset: CGFloat = 72
            let contentWidth = bounds.width - horizontalInset * 2

            ("CurrentMoment" as NSString).draw(
                in: CGRect(x: horizontalInset, y: 120, width: contentWidth, height: 88),
                withAttributes: titleAttributes
            )
            ("Demo capture" as NSString).draw(
                in: CGRect(x: horizontalInset, y: 640, width: contentWidth, height: 42),
                withAttributes: subtitleAttributes
            )
            ("Use a real device to attach the live camera preview." as NSString).draw(
                in: CGRect(x: horizontalInset, y: 700, width: contentWidth, height: 80),
                withAttributes: captionAttributes
            )
        }
    }
}
