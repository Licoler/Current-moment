import AVFoundation
import Combine
import UIKit

@MainActor
final class CameraViewModel {
    
    @Published private(set) var cameraAvailability: CameraSessionController.Availability = .unavailable
    @Published private(set) var statusMessage: String?
    
    var captureSession: AVCaptureSession { sessionController.captureSession }
    var onMomentCaptured: ((CapturedMomentAsset) -> Void)?
    
    private let repository: CurrentMomentRepositoryProtocol
    private let sessionController = CameraSessionController()
    private var cancellables = Set<AnyCancellable>()
    
    init(repository: CurrentMomentRepositoryProtocol) {
        self.repository = repository
    }
    
    func prepareAndStart() {
        sessionController.onPhotoCaptured = { [weak self] image in
            self?.handleCapturedImage(image)
        }
        
        sessionController.prepare { [weak self] availability in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.cameraAvailability = availability
                self.statusMessage = availability == .available ? nil : availability.statusMessage
                if availability == .available {
                    self.startSession()
                }
            }
        }
    }
    
    func startSession() {
        guard cameraAvailability == .available else { return }
        sessionController.startRunning()
    }
    
    func stopSession() {
        sessionController.stopRunning()
    }
    
    func captureMoment() {
        guard cameraAvailability == .available else {
            let demoImage = DemoCaptureImageFactory.makeImage()
            handleCapturedImage(demoImage)
            return
        }
        sessionController.capturePhoto()
    }
    
    func switchCamera() {
        sessionController.switchCamera()
    }
    
    private func handleCapturedImage(_ image: UIImage) {
        guard let asset = CapturedMomentAsset.make(from: image) else {
            statusMessage = AppError.cameraUnavailable.localizedDescription
            return
        }
        onMomentCaptured?(asset)
    }
}
