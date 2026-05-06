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
            case .available: return "Camera ready."
            case .simulator: return "Simulator mode. Demo frame will be used."
            case .denied: return "Camera access denied. Enable in Settings."
            case .restricted: return "Camera access restricted."
            case .unavailable: return "No camera source available."
            }
        }
    }
    
    let captureSession = AVCaptureSession()
    var onPhotoCaptured: ((UIImage) -> Void)?
    
    var availabilityChanged: ((Availability) -> Void)?
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
        addSessionNotifications()
    }
    
    deinit {
        removeSessionNotifications()
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
            DispatchQueue.main.async {
                completion(.available)
                self.availabilityChanged?(.available)
            }
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
        if let error = error {

#if DEBUG
            print("[CameraSessionController] photo capture error: \(error)")
#endif
            return
        }
        guard let data = photo.fileDataRepresentation() else { return }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            guard let image = UIImage(data: data) else { return }
            let finalImage: UIImage = (self.cameraPosition == .front) ? self.flipHorizontallyAndNormalize(image) : image
            DispatchQueue.main.async { self.onPhotoCaptured?(finalImage) }
        }
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

// MARK: - Session notifications
extension CameraSessionController {
    private func addSessionNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionWasInterrupted(_:)),
                                               name: AVCaptureSession.wasInterruptedNotification,
                                               object: captureSession)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionInterruptionEnded(_:)),
                                               name: AVCaptureSession.interruptionEndedNotification,
                                               object: captureSession)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sessionRuntimeError(_:)),
                                               name: AVCaptureSession.runtimeErrorNotification,
                                               object: captureSession)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidEnterBackground(_:)),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillEnterForeground(_:)),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }
    
    private func removeSessionNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func sessionWasInterrupted(_ notification: Notification) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
#if DEBUG
            print("[CameraSessionController] session was interrupted")
#endif
            self.availability = .unavailable
            DispatchQueue.main.async { self.availabilityChanged?(.unavailable) }
        }
    }
    
    @objc private func sessionInterruptionEnded(_ notification: Notification) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
#if DEBUG
            print("[CameraSessionController] session interruption ended")
#endif
            if self.isConfigured {
                self.availability = .available
                DispatchQueue.main.async { self.availabilityChanged?(.available) }
                if !self.captureSession.isRunning {
                    self.captureSession.startRunning()
                }
            }
        }
    }
    
    @objc private func sessionRuntimeError(_ notification: Notification) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            let error = notification.userInfo?[AVCaptureSessionErrorKey] as? NSError
#if DEBUG
            print("[CameraSessionController] runtime error: \(String(describing: error))")
#endif
            self.availability = .unavailable
            DispatchQueue.main.async { self.availabilityChanged?(.unavailable) }
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self else { return }
                self.sessionQueue.async {
                    if self.isConfigured && !self.captureSession.isRunning {
                        self.captureSession.startRunning()
                        self.availability = .available
                        DispatchQueue.main.async { self.availabilityChanged?(.available) }
                    }
                }
            }
        }
    }
    
    @objc private func applicationDidEnterBackground(_ notification: Notification) {
        stopRunning()
    }
    
    @objc private func applicationWillEnterForeground(_ notification: Notification) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            if self.isConfigured {
                self.captureSession.startRunning()
            }
        }
    }
}

