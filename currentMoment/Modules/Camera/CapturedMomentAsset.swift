import UIKit

struct CapturedMomentAsset {
    let previewImage: UIImage
    let imageData: Data
    let thumbnailData: Data
    let isLivePhoto: Bool

    static func make(from image: UIImage, targetSize: CGSize = CGSize(width: 1024, height: 1024)) -> CapturedMomentAsset? {
        let scaledImage = image.resizedAndCropped(to: targetSize)
        guard let imageData = scaledImage.jpegData(compressionQuality: 0.92),
              let thumbnailImage = scaledImage.preparingThumbnail(of: CGSize(width: 420, height: 420)),
              let thumbnailData = thumbnailImage.jpegData(compressionQuality: 0.76) else { return nil }
        return CapturedMomentAsset(previewImage: scaledImage, imageData: imageData, thumbnailData: thumbnailData, isLivePhoto: false)
    }
}

extension UIImage {
    func resizedAndCropped(to targetSize: CGSize) -> UIImage {
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let scale = max(widthRatio, heightRatio)
        let scaledSize = CGSize(width: size.width * scale, height: size.height * scale)
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0)
        let x = (targetSize.width - scaledSize.width) / 2
        let y = (targetSize.height - scaledSize.height) / 2
        draw(in: CGRect(origin: CGPoint(x: x, y: y), size: scaledSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? self
    }
}
