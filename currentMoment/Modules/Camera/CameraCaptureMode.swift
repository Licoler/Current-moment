import Foundation

enum CameraCaptureMode: Int, CaseIterable {
    case photo
    case live

    var title: String {
        switch self {
        case .photo: return "Photo"
        case .live:  return "Live"
        }
    }
}
