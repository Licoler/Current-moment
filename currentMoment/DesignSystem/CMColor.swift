import UIKit

enum CMColor {
    static let background = UIColor(hex: "#000000") ?? .black
    static let card = UIColor(hex: "#111111") ?? UIColor(white: 0.07, alpha: 1)
    static let cardElevated = UIColor(hex: "#1C1C1E") ?? UIColor(white: 0.12, alpha: 1)
    static let stroke = UIColor.white.withAlphaComponent(0.08)
    static let overlay = UIColor.black.withAlphaComponent(0.48)
    static let textPrimary = UIColor.white
    static let textSecondary = UIColor.white.withAlphaComponent(0.68)
    static let textTertiary = UIColor.white.withAlphaComponent(0.42)
    static let accent = UIColor.white
    static let destructive = UIColor.systemRed
}
