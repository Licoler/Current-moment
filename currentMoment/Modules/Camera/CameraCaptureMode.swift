import Foundation

enum CameraCaptureMode: Int, CaseIterable {
    case photo

    var title: String {
        switch self {
        case .photo: return "Photo"
        }
    }
}
