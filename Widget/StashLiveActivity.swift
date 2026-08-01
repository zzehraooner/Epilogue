import ActivityKit
import WidgetKit
import SwiftUI

struct StashLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StashActivityAttributes.self) { context in
            // Kilit ekranı (Lock Screen) görünümü
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "shippingbox.fill")
                        .foregroundStyle(.white)
                    Text("Stash: \(context.attributes.depoName)")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(context.state.memoryCount) Anı")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white.opacity(0.8))
                }
                
                Text("Son Eklenen:")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                
                Text(context.state.latestMemoryName)
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }
            .padding()
            .background(Color.blue) // activityBackgroundTintColor in Info.plist is better, but doing it here too.
        } dynamicIsland: { context in
            DynamicIsland {
                // Genişletilmiş görünüm
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Image(systemName: "shippingbox.fill")
                            .foregroundStyle(.blue)
                        Text(context.attributes.depoName)
                            .font(.headline)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.memoryCount) Anı")
                        .font(.subheadline.bold())
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Son: \(context.state.latestMemoryName)")
                        .font(.caption)
                }
            } compactLeading: {
                Image(systemName: "shippingbox.fill")
                    .foregroundStyle(.blue)
            } compactTrailing: {
                Text("\(context.state.memoryCount)")
                    .foregroundStyle(.blue)
            } minimal: {
                Image(systemName: "shippingbox.fill")
                    .foregroundStyle(.blue)
            }
        }
    }
}
