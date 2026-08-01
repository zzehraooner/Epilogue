import WidgetKit
import SwiftUI

// MARK: - Data Model for Widget
struct WidgetMemory {
    let imageURL: String
    let wordOne: String
    let wordTwo: String
    let wordThree: String
    let date: Date
    
    var wordsDisplay: String {
        [wordOne, wordTwo, wordThree]
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .joined(separator: " · ")
    }
    
    static let placeholder = WidgetMemory(
        imageURL: "",
        wordOne: "Anı",
        wordTwo: "Deposu",
        wordThree: "",
        date: .now
    )
}

// MARK: - Timeline Provider
struct StashTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> StashWidgetEntry {
        StashWidgetEntry(date: .now, memory: .placeholder)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (StashWidgetEntry) -> Void) {
        completion(StashWidgetEntry(date: .now, memory: .placeholder))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<StashWidgetEntry>) -> Void) {
        var memory: WidgetMemory = .placeholder
        
        if let defaults = UserDefaults(suiteName: "group.com.stash"),
           let dict = defaults.dictionary(forKey: "latestMemory") {
            
            memory = WidgetMemory(
                imageURL: dict["imageURL"] as? String ?? "",
                wordOne: dict["wordOne"] as? String ?? "Anı",
                wordTwo: dict["wordTwo"] as? String ?? "",
                wordThree: dict["wordThree"] as? String ?? "",
                date: Date(timeIntervalSince1970: dict["date"] as? TimeInterval ?? Date().timeIntervalSince1970)
            )
        }
        
        let entry = StashWidgetEntry(date: .now, memory: memory)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Timeline Entry
struct StashWidgetEntry: TimelineEntry {
    let date: Date
    let memory: WidgetMemory
}

// MARK: - Small Widget View
struct StashWidgetSmallView: View {
    let entry: StashWidgetEntry
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.purple, Color.blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.caption)
                    Text("Stash")
                        .font(.caption.bold())
                }
                .foregroundStyle(.white.opacity(0.8))
                
                Spacer()
                
                Text(entry.memory.wordsDisplay)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                
                Text(entry.memory.date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding()
        }
    }
}

// MARK: - Medium Widget View
struct StashWidgetMediumView: View {
    let entry: StashWidgetEntry
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.purple, Color.blue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            HStack(spacing: 16) {
                // Photo placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay {
                        Image(systemName: "photo.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.caption)
                        Text("Stash")
                            .font(.caption.bold())
                    }
                    .foregroundStyle(.white.opacity(0.8))
                    
                    Text(entry.memory.wordsDisplay)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    
                    Text(entry.memory.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - Widget Configuration
struct StashWidget: Widget {
    let kind: String = "StashWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StashTimelineProvider()) { entry in
            if #available(iOS 17.0, *) {
                StashWidgetSmallView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                StashWidgetSmallView(entry: entry)
            }
        }
        .configurationDisplayName("Stash Anı")
        .description("Rastgele bir anınızı ana ekranınızda görün.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget Bundle (Entry Point)
// @main
struct StashWidgetBundle: WidgetBundle {
    var body: some Widget {
        StashWidget()
    }
}
