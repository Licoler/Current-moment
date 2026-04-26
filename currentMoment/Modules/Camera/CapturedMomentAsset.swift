import UIKit

struct CapturedMomentAsset {
    let previewImage: UIImage
    let imageData: Data
    let thumbnailData: Data
    let isLivePhoto: Bool

    static func make(
        from image: UIImage,
        isLivePhoto: Bool,
        targetSize: CGSize = CGSize(width: 1024, height: 1024)
    ) -> CapturedMomentAsset? {
        let scaledImage = image.resizedAndCropped(to: targetSize)
        guard let imageData = scaledImage.jpegData(compressionQuality: 0.92),
              let thumbnailImage = scaledImage.preparingThumbnail(of: CGSize(width: 420, height: 420)),
              let thumbnailData = thumbnailImage.jpegData(compressionQuality: 0.76)
        else { return nil }

        return CapturedMomentAsset(
            previewImage: scaledImage,
            imageData: imageData,
            thumbnailData: thumbnailData,
            isLivePhoto: isLivePhoto
        )
    }
}

extension UIImage {
    func resizedAndCropped(to targetSize: CGSize) -> UIImage {
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let scale = max(widthRatio, heightRatio) // покрываем квадрат
        let scaledSize = CGSize(width: size.width * scale, height: size.height * scale)
        let cropRect = CGRect(
            x: (scaledSize.width - targetSize.width) / 2,
            y: (scaledSize.height - targetSize.height) / 2,
            width: targetSize.width,
            height: targetSize.height
        )

        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0)
        defer { UIGraphicsEndImageContext() }

        draw(in: CGRect(origin: .zero, size: scaledSize))
        let croppedImage = UIGraphicsGetImageFromCurrentImageContext()?.cgImage?.cropping(to: cropRect)
        if let cgImage = croppedImage {
            return UIImage(cgImage: cgImage, scale: 0, orientation: imageOrientation)
        }
        return self
    }
}
