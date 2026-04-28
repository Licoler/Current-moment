import Foundation

#if canImport(WidgetKit)
import WidgetKit
#endif

protocol CurrentMomentWidgetServiceProtocol: AnyObject {
    func syncSnapshots(moments: [Moment], users: [User], currentUser: User?) async
}

final class CurrentMomentWidgetService: CurrentMomentWidgetServiceProtocol {
    static let widgetKind = "CurrentMomentWidget"
    
    func syncSnapshots(moments: [Moment], users: [User], currentUser: User?) async {
#if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: Self.widgetKind)
#endif
    }
}
