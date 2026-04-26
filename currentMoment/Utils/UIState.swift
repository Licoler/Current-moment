import Foundation

struct AlertState: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
}
