import AVFoundation
import Combine
import UIKit

@MainActor
final class CameraViewModel {

    @Published private(set) var cameraAvailability: CameraSessionController.Availability = .unavailable
    @Published private(set) var selectedCaptureMode: CameraCaptureMode = .photo
    @Published private(set) var statusMessage: String?

    var captureSession: AVCaptureSession { sessionController.captureSession }
    var onMomentCaptured: ((CapturedMomentAsset) -> Void)?

    private let repository: CurrentMomentRepositoryProtocol
    private let sessionController = CameraSessionController()
    private var cancellables = Set<AnyCancellable>()

    init(repository: CurrentMomentRepositoryProtocol) {
        self.repository = repository
    }

    func prepareSession() {
        sessionController.onPhotoCaptured = { [weak self] image in
            self?.handleCapturedImage(image)
        }

        sessionController.prepare { [weak self] availability in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.cameraAvailability = availability
                self.statusMessage = availability == .available ? nil : availability.statusMessage
            }
        }
    }

    func startSession() {
        sessionController.startRunning()
    }

    func stopSession() {
        sessionController.stopRunning()
    }

    func captureMoment() {
        if cameraAvailability == .available {
            sessionController.capturePhoto()
        } else {
            let demoImage = DemoCaptureImageFactory.makeImage()
            handleCapturedImage(demoImage)
        }
    }

    func switchCamera() {
        sessionController.switchCamera()
    }

    func selectCaptureMode(at index: Int) {
        selectedCaptureMode = CameraCaptureMode(rawValue: index) ?? .photo
    }

    func prepareAndStart() {
        prepareSession()
        $cameraAvailability
            .filter { $0 == .available }
            .first()
            .sink { [weak self] _ in
                self?.startSession()
            }
            .store(in: &cancellables)
    }

    private func handleCapturedImage(_ image: UIImage) {
        guard let asset = CapturedMomentAsset.make(
            from: image,
            isLivePhoto: selectedCaptureMode == .live
        ) else {
            statusMessage = AppError.cameraUnavailable.localizedDescription
            return
        }
        onMomentCaptured?(asset)
    }
}
