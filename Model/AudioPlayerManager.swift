import Foundation
import AVFoundation

@Observable
class AudioPlayerManager {
    private var player: AVPlayer?
    private var timeObserver: Any?
    var isPlaying = false
    var progress: Double = 0.0
    var duration: Double = 0.0
    
    func playAudio(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        if player == nil || (player?.currentItem?.asset as? AVURLAsset)?.url != url {
            player = AVPlayer(url: url)
            setupTimeObserver()
        }
        
        player?.play()
        isPlaying = true
        
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { [weak self] _ in
            self?.isPlaying = false
            self?.progress = 1.0
            self?.player?.seek(to: .zero)
        }
    }
    
    func pauseAudio() {
        player?.pause()
        isPlaying = false
    }
    
    private func setupTimeObserver() {
        guard let player = player else { return }
        
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self, let item = player.currentItem else { return }
            
            let duration = item.duration.seconds
            if !duration.isNaN {
                self.duration = duration
                self.progress = time.seconds / duration
            }
        }
    }
    
    deinit {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
    }
}
