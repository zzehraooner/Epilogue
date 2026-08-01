import SwiftUI

struct DepoPlaylistView: View {
    let depo: Depo
    let memories: [Memory]
    
    // Yalnızca müzik eklenmiş anılar
    var musicMemories: [Memory] {
        memories.filter { $0.previewAudioURL != nil && $0.songName != nil }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 60))
                        .foregroundStyle(.pink)
                        .padding()
                        .background(Circle().fill(Color.pink.opacity(0.1)))
                    
                    Text("\(depo.name) Çalma Listesi")
                        .font(.title2.bold())
                    
                    Text("\(musicMemories.count) Şarkı")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                if musicMemories.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "music.mic")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Bu depoda henüz müzikli anı yok.")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(musicMemories) { memory in
                            PlaylistRow(memory: memory)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Çalma Listesi")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
}

private struct PlaylistRow: View {
    let memory: Memory
    
    var body: some View {
        HStack(spacing: 16) {
            // Memory image as album cover
            if !memory.imageURL.isEmpty, let url = URL(string: memory.imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color(.secondarySystemBackground)
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: "music.note")
                            .foregroundStyle(.tertiary)
                    }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(memory.songName ?? "Bilinmeyen Şarkı")
                    .font(.headline)
                    .lineLimit(1)
                
                Text(memory.wordsDisplay)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Audio player mini button or control
            if let urlString = memory.previewAudioURL {
                AudioPlayerControl(urlString: urlString)
                    .frame(width: 44, height: 44)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}
