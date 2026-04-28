import SwiftUI
import UIKit
import WidgetKit

struct CurrentMomentEntry: TimelineEntry {
    let date: Date
    let snapshots: [WidgetMomentSnapshot]
}

struct CurrentMomentProvider: TimelineProvider {
    private let store = CurrentMomentWidgetStore()
    
    func placeholder(in context: Context) -> CurrentMomentEntry {
        CurrentMomentEntry(
            date: .now,
            snapshots: [
                WidgetMomentSnapshot(id: "1", momentId: "1", username: "Lena", imageURL: "", thumbnailURL: nil, deepLink: "currentmoment://history/1"),
                WidgetMomentSnapshot(id: "2", momentId: "2", username: "Mila", imageURL: "", thumbnailURL: nil, deepLink: "currentmoment://history/2"),
                WidgetMomentSnapshot(id: "3", momentId: "3", username: "Sam", imageURL: "", thumbnailURL: nil, deepLink: "currentmoment://history/3"),
                WidgetMomentSnapshot(id: "4", momentId: "4", username: "Noah", imageURL: "", thumbnailURL: nil, deepLink: "currentmoment://history/4")
            ]
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (CurrentMomentEntry) -> Void) {
        completion(CurrentMomentEntry(date: .now, snapshots: store.snapshots()))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<CurrentMomentEntry>) -> Void) {
        let entry = CurrentMomentEntry(date: .now, snapshots: store.snapshots())
        let timeline = Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(15 * 60)))
        completion(timeline)
    }
}

struct CurrentMomentCircleWidgetView: View {
    let entry: CurrentMomentEntry
    
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    var body: some View {
        ZStack {
            Color.black
            
            if entry.snapshots.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                    Text("CurrentMoment")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("New moments appear here.")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.62))
                }
            } else {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(entry.snapshots.prefix(4)) { snapshot in
                        if let url = URL(string: snapshot.deepLink) {
                            Link(destination: url) {
                                WidgetTile(snapshot: snapshot)
                            }
                        } else {
                            WidgetTile(snapshot: snapshot)
                        }
                    }
                }
                .padding(12)
            }
        }
        .containerBackground(.black, for: .widget)
    }
}

private struct WidgetTile: View {
    let snapshot: WidgetMomentSnapshot
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                if let image = resolveImage() {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    LinearGradient(
                        colors: [Color(red: 0.67, green: 0.33, blue: 0.97), Color(red: 0.95, green: 0.29, blue: 0.57)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
                
                LinearGradient(
                    colors: [.clear, .black.opacity(0.78)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                
                Text(snapshot.username)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(8)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .aspectRatio(1.02, contentMode: .fit)
    }
    
    private func resolveImage() -> UIImage? {
        let path = snapshot.thumbnailURL ?? snapshot.imageURL
        if let remoteURL = URL(string: path), remoteURL.scheme?.hasPrefix("http") == true {
            return nil
        }
        return UIImage(contentsOfFile: path)
    }
}

struct CurrentMomentCircleWidget: Widget {
    let kind: String = "CurrentMomentWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CurrentMomentProvider()) { entry in
            CurrentMomentCircleWidgetView(entry: entry)
        }
        .configurationDisplayName("CurrentMoment")
        .description("Latest moments from your closest friends.")
        .supportedFamilies([.systemMedium])
    }
}
