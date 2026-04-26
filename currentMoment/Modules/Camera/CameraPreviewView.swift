import AVFoundation
import UIKit

/// Полноэкранный превью-слой камеры.
/// layerClass переопределён так, чтобы backing layer был AVCaptureVideoPreviewLayer —
/// тогда его frame всегда совпадает с bounds вью и не нужно отдельно обновлять.
final class CameraPreviewView: UIView {

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var capturePreviewLayer: AVCaptureVideoPreviewLayer {
        // Приведение всегда безопасно: layerClass гарантирует тип.
        layer as! AVCaptureVideoPreviewLayer
    }
}
