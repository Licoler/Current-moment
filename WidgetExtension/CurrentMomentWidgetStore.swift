import Foundation

struct CurrentMomentWidgetStore {
    func snapshots() -> [WidgetMomentSnapshot] {
        [
            WidgetMomentSnapshot(
                id: "1",
                momentId: "demo-1",
                username: "Lena",
                imageURL: "",
                thumbnailURL: nil,
                deepLink: "currentmoment://history/demo-1"
            ),
            WidgetMomentSnapshot(
                id: "2",
                momentId: "demo-2",
                username: "Mila",
                imageURL: "",
                thumbnailURL: nil,
                deepLink: "currentmoment://history/demo-2"
            ),
            WidgetMomentSnapshot(
                id: "3",
                momentId: "demo-3",
                username: "Sam",
                imageURL: "",
                thumbnailURL: nil,
                deepLink: "currentmoment://history/demo-3"
            ),
            WidgetMomentSnapshot(
                id: "4",
                momentId: "demo-4",
                username: "Noah",
                imageURL: "",
                thumbnailURL: nil,
                deepLink: "currentmoment://history/demo-4"
            )
        ]
    }
}
