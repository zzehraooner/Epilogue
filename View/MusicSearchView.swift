import SwiftUI
import AVFoundation

struct iTunesResult: Codable {
    let results: [iTunesSong]
}

struct iTunesSong: Codable, Identifiable {
    let trackId: Int
    let trackName: String
    let artistName: String
    let previewUrl: String?
    let artworkUrl100: String?
    
    var id: Int { trackId }
}

struct MusicSearchView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var searchResults: [iTunesSong] = []
    @State private var isSearching = false
    
    // Player for preview
    @State private var audioPlayer: AVPlayer?
    @State private var playingTrackId: Int?
    
    var onSelect: (String, String) -> Void // (songName, previewUrl)
    
    var body: some View {
        NavigationStack {
            List(searchResults) { song in
                HStack {
                    if let artworkUrl = song.artworkUrl100, let url = URL(string: artworkUrl) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFit()
                        } placeholder: {
                            Color.gray
                        }
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    VStack(alignment: .leading) {
                        Text(song.trackName)
                            .font(.headline)
                        Text(song.artistName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if let preview = song.previewUrl {
                        Button {
                            togglePlay(previewUrl: preview, trackId: song.trackId)
                        } label: {
                            Image(systemName: playingTrackId == song.trackId ? "pause.circle.fill" : "play.circle.fill")
                                .font(.title)
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    audioPlayer?.pause()
                    if let preview = song.previewUrl {
                        onSelect("\(song.artistName) - \(song.trackName)", preview)
                        dismiss()
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Şarkı veya Sanatçı Ara")
            .onChange(of: searchText) { oldValue, newValue in
                Task {
                    await search(query: newValue)
                }
            }
            .navigationTitle("Müzik Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        audioPlayer?.pause()
                        dismiss()
                    }
                }
            }
            .overlay {
                if isSearching && searchResults.isEmpty {
                    ProgressView()
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    Text("Sonuç bulunamadı")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    @MainActor
    private func search(query: String) async {
        guard query.count > 2 else {
            searchResults = []
            return
        }
        
        isSearching = true
        defer { isSearching = false }
        
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://itunes.apple.com/search?term=\(encodedQuery)&entity=song&limit=25"
        
        guard let url = URL(string: urlString) else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let result = try JSONDecoder().decode(iTunesResult.self, from: data)
            self.searchResults = result.results
        } catch {
            print("iTunes Search error: \(error)")
        }
    }
    
    private func togglePlay(previewUrl: String, trackId: Int) {
        if playingTrackId == trackId {
            audioPlayer?.pause()
            playingTrackId = nil
        } else {
            guard let url = URL(string: previewUrl) else { return }
            audioPlayer = AVPlayer(url: url)
            audioPlayer?.play()
            playingTrackId = trackId
        }
    }
}
