import SwiftUI
import AVFoundation

struct AudioPlayerControl: View {
    let urlString: String
    @State private var playerManager = AudioPlayerManager()
    
    var body: some View {
        HStack {
            Button {
                if playerManager.isPlaying {
                    playerManager.pauseAudio()
                } else {
                    playerManager.playAudio(from: urlString)
                }
            } label: {
                Image(systemName: playerManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.accentColor)
            }
            
            VStack(alignment: .leading) {
                Text("Sesli Not")
                    .font(.headline)
                
                ProgressView(value: playerManager.progress)
                    .tint(.accentColor)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
