import UIKit
import AVFoundation

final class CameraPreviewView: UIView {
    
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    private var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
    
    var session: AVCaptureSession? {
        get { previewLayer.session }
        set { previewLayer.session = newValue }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 24
        clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
        previewLayer.videoGravity = .resizeAspectFill
    }
}
