import Foundation

enum AppError: LocalizedError, Equatable {
    case firebaseNotConfigured
    case authenticationFailed
    case missingCurrentUser
    case invalidUsername
    case noRecipientsSelected
    case cameraUnavailable
    case generic(String)
    
    var errorDescription: String? {
        switch self {
        case .firebaseNotConfigured:
            return "Firebase is not configured. Follow SETUP.md and add GoogleService-Info.plist plus Firebase packages."
        case .authenticationFailed:
            return "Authentication failed. Try again."
        case .missingCurrentUser:
            return "Current user is missing."
        case .invalidUsername:
            return "Enter a valid username."
        case .noRecipientsSelected:
            return "Select at least one friend before sending."
        case .cameraUnavailable:
            return "The camera is unavailable on this device."
        case .generic(let message):
            return message
        }
    }
}
