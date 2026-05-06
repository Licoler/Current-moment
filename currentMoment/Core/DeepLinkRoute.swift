import Foundation

enum DeepLinkRoute: Hashable {
    case history
    case moment(id: String)

    static func parse(url: URL) -> DeepLinkRoute? {
        guard url.scheme == "currentmoment" || url.scheme == "locketclone" else {
            return nil
        }

        let components = url.pathComponents.filter { $0 != "/" }

        if url.host == "history" {
            if let id = components.last {
                return .moment(id: id)
            }
            return .history
        }

        if url.host == "moment", let id = components.last {
            return .moment(id: id)
        }

        return nil
    }
}
