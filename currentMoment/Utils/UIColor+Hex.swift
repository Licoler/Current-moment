import UIKit

extension UIColor {
    convenience init?(hex: String, alpha: CGFloat = 1) {
        let cleanedHex = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        
        guard cleanedHex.count == 6,
              let value = Int(cleanedHex, radix: 16) else {
            return nil
        }
        
        let red = CGFloat((value >> 16) & 0xFF) / 255
        let green = CGFloat((value >> 8) & 0xFF) / 255
        let blue = CGFloat(value & 0xFF) / 255
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    func mixed(with color: UIColor, ratio: CGFloat) -> UIColor {
        let ratio = min(max(ratio, 0), 1)
        
        var redA: CGFloat = 0
        var greenA: CGFloat = 0
        var blueA: CGFloat = 0
        var alphaA: CGFloat = 0
        var redB: CGFloat = 0
        var greenB: CGFloat = 0
        var blueB: CGFloat = 0
        var alphaB: CGFloat = 0
        
        guard getRed(&redA, green: &greenA, blue: &blueA, alpha: &alphaA),
              color.getRed(&redB, green: &greenB, blue: &blueB, alpha: &alphaB) else {
            return self
        }
        
        return UIColor(
            red: redA + ((redB - redA) * ratio),
            green: greenA + ((greenB - greenA) * ratio),
            blue: blueA + ((blueB - blueA) * ratio),
            alpha: alphaA + ((alphaB - alphaA) * ratio)
        )
    }
    
    func darkened(by amount: CGFloat) -> UIColor {
        mixed(with: .black, ratio: amount)
    }
    
    func lightened(by amount: CGFloat) -> UIColor {
        mixed(with: .white, ratio: amount)
    }
}
