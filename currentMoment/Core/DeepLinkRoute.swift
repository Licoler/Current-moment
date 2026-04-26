import Foundation

enum DeepLinkRoute: Hashable {
    case history
    case moment(id: String)

    static func parse(url: URL) -> DeepLinkRoute? {
        guard url.scheme == "currentmoment" || url.scheme == "locketclone" else {
            return nil
        }

        let pathComponents = url.pathComponents.filter { $0 != "/" }
        if url.host == "history" {
            if let last = pathComponents.last, !last.isEmpty {
                return .moment(id: last)
            }
            return .history
        }

        if url.host == "moment", let last = pathComponents.last, !last.isEmpty {
            return .moment(id: last)
        }

        return nil
    }
}
