import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let urlString: String
    @State private var player: AVPlayer?
    
    var body: some View {
        Group {
            if let player = player {
                VideoPlayer(player: player)
                    .onDisappear {
                        player.pause()
                    }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.1))
            }
        }
        .onAppear {
            if let url = URL(string: urlString) {
                player = AVPlayer(url: url)
            }
        }
    }
}
