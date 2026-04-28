import AVFoundation
import UIKit

final class CameraSessionController: NSObject {
    
    enum Availability: Equatable {
        case available
        case simulator
        case denied
        case restricted
        case unavailable
        
        var statusMessage: String {
            switch self {
            case .available:   return "Camera ready."
            case .simulator:   return "Simulator mode. Demo frame will be used."
            case .denied:      return "Camera access denied. Enable in Settings."
            case .restricted:  return "Camera access restricted."
            case .unavailable: return "No camera source available."
            }
        }
    }
    
    let captureSession = AVCaptureSession()
    var onPhotoCaptured: ((UIImage) -> Void)?
    private(set) var availability: Availability = .unavailable
    private(set) var isCapturingPhoto = false
    
    private let sessionQueue = DispatchQueue(label: "app.camera.session", qos: .userInitiated)
    private let photoOutput = AVCapturePhotoOutput()
    private var activeInput: AVCaptureDeviceInput?
    private var isConfigured = false
    private(set) var cameraPosition: AVCaptureDevice.Position = .front
    private var currentFlashMode: AVCaptureDevice.FlashMode = .off
    
    override init() {
        super.init()
        captureSession.sessionPreset = .high
        captureSession.automaticallyConfiguresApplicationAudioSession = false
        captureSession.automaticallyConfiguresCaptureDeviceForWideColor = false
    }
    
    func setFlashMode(_ mode: AVCaptureDevice.FlashMode) {
        currentFlashMode = mode
    }
    
    func prepare(completion: @escaping (Availability) -> Void) {
        #if targetEnvironment(simulator)
        availability = .simulator
        completion(.simulator)
        #else
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            configureSession(completion: completion)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.configureSession(completion: completion)
                } else {
                    self?.availability = .denied
                    DispatchQueue.main.async { completion(.denied) }
                }
            }
        case .denied:
            availability = .denied
            completion(.denied)
        case .restricted:
            availability = .restricted
            completion(.restricted)
        @unknown default:
            availability = .unavailable
            completion(.unavailable)
        }
        #endif
    }
    
    private func configureSession(completion: @escaping (Availability) -> Void) {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard !self.isConfigured else {
                self.availability = .available
                DispatchQueue.main.async { completion(.available) }
                return
            }
            
            self.captureSession.beginConfiguration()
            defer { self.captureSession.commitConfiguration() }
            
            guard let device = self.bestCamera(for: self.cameraPosition),
                  let input = try? AVCaptureDeviceInput(device: device),
                  self.captureSession.canAddInput(input) else {
                self.availability = .unavailable
                DispatchQueue.main.async { completion(.unavailable) }
                return
            }
            self.captureSession.addInput(input)
            self.activeInput = input
            
            guard self.captureSession.canAddOutput(self.photoOutput) else {
                self.availability = .unavailable
                DispatchQueue.main.async { completion(.unavailable) }
                return
            }
            self.captureSession.addOutput(self.photoOutput)
            
            if #available(iOS 16.0, *) {
                let dimensions = self.activeInput?.device.activeFormat.supportedMaxPhotoDimensions
                if let lastDim = dimensions?.last {
                    self.photoOutput.maxPhotoDimensions = lastDim
                }
            } else {
                self.photoOutput.isHighResolutionCaptureEnabled = true
            }
            
            self.isConfigured = true
            self.availability = .available
            DispatchQueue.main.async { completion(.available) }
        }
    }
    
    func startRunning() {
        guard availability == .available else { return }
        sessionQueue.async { [weak self] in
            guard let self, !self.captureSession.isRunning else { return }
            self.captureSession.startRunning()
        }
    }
    
    func stopRunning() {
        sessionQueue.async { [weak self] in
            guard let self, self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
        }
    }
    
    func capturePhoto() {
        guard !isCapturingPhoto, availability == .available else { return }
        isCapturingPhoto = true
        let settings = AVCapturePhotoSettings()
        settings.flashMode = currentFlashMode
        if #available(iOS 16.0, *) {
            let dims = photoOutput.maxPhotoDimensions
            if dims.width > 0 && dims.height > 0 {
                settings.maxPhotoDimensions = dims
            }
        } else {
            settings.isHighResolutionPhotoEnabled = true
        }
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func switchCamera() {
        guard availability == .available else { return }
        let oldPosition = cameraPosition
        cameraPosition = cameraPosition == .front ? .back : .front
        
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard let newDevice = self.bestCamera(for: self.cameraPosition),
                  let newInput = try? AVCaptureDeviceInput(device: newDevice) else {
                self.cameraPosition = oldPosition
                return
            }
            
            self.captureSession.beginConfiguration()
            if let oldInput = self.activeInput {
                self.captureSession.removeInput(oldInput)
            }
            if self.captureSession.canAddInput(newInput) {
                self.captureSession.addInput(newInput)
                self.activeInput = newInput
            } else {
                if let oldInput = self.activeInput {
                    self.captureSession.addInput(oldInput)
                }
            }
            if #available(iOS 16.0, *) {
                let dimensions = self.activeInput?.device.activeFormat.supportedMaxPhotoDimensions
                if let lastDim = dimensions?.last {
                    self.photoOutput.maxPhotoDimensions = lastDim
                }
            }
            self.captureSession.commitConfiguration()
        }
    }
    
    private func bestCamera(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
    }
}

extension CameraSessionController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        defer { isCapturingPhoto = false }
        guard error == nil, let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else { return }
        let finalImage: UIImage = (cameraPosition == .front) ? flipHorizontallyAndNormalize(image) : image
        DispatchQueue.main.async { self.onPhotoCaptured?(finalImage) }
    }
    
    private func flipHorizontallyAndNormalize(_ image: UIImage) -> UIImage {
        let normalized: UIImage
        if image.imageOrientation == .up {
            normalized = image
        } else {
            UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
            image.draw(in: CGRect(origin: .zero, size: image.size))
            normalized = UIGraphicsGetImageFromCurrentImageContext() ?? image
            UIGraphicsEndImageContext()
        }
        guard let cgImage = normalized.cgImage else { return image }
        let width = cgImage.width, height = cgImage.height
        guard let context = CGContext(data: nil,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: cgImage.bitsPerComponent,
                                      bytesPerRow: 0,
                                      space: cgImage.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: cgImage.bitmapInfo.rawValue) else { return image }
        context.translateBy(x: CGFloat(width), y: 0)
        context.scaleBy(x: -1.0, y: 1.0)
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let flipped = context.makeImage() else { return image }
        return UIImage(cgImage: flipped, scale: normalized.scale, orientation: .up)
    }
}
