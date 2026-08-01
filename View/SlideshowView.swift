//
//  SlideshowView.swift
//  Epilogue
//
//  Created by Zehra Öner on 21.07.2026.
//

import SwiftUI
import Combine

struct SlideshowView: View {
    let memories: [Memory]
    
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex = 0
    @State private var isPlaying = true
    @State private var showPauseIcon = false
    @State private var videoExporter = VideoExportManager()
    @State private var showingShareSheet = false
    @State private var showingExportProgress = false
    
    // Her 4 saniyede bir tetiklenen zamanlayıcı
    let timer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if memories.isEmpty {
                Text("Gösterilecek anı yok.")
                    .foregroundColor(.white)
            } else {
                TabView(selection: $currentIndex) {
                    ForEach(memories.indices, id: \.self) { index in
                        let memory = memories[index]
                        
                        ZStack(alignment: .bottom) {
                            // Arka Plan Resmi
                            AsyncImage(url: URL(string: memory.imageURL)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .tint(.white)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .clipped()
                                case .failure(_):
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                        .font(.largeTitle)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .ignoresSafeArea()
                            
                            // Metin Okunabilirliği İçin Alt Kısımda Degrade (Gradient)
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.8)],
                                startPoint: .center,
                                endPoint: .bottom
                            )
                            .ignoresSafeArea()
                            
                            // Anı Bilgileri Metni
                            VStack(alignment: .leading, spacing: 8) {
                                let wordsDisplay = [memory.wordOne, memory.wordTwo, memory.wordThree]
                                    .compactMap { $0 }
                                    .filter { !$0.isEmpty }
                                    .joined(separator: " - ")
                                
                                Text(wordsDisplay)
                                    .font(.title)
                                    .bold()
                                    .foregroundColor(.white)
                                
                                let note = memory.note
                                if !note.isEmpty {
                                    Text(note)
                                        .font(.body)
                                        .foregroundColor(.white)
                                        .lineLimit(3)
                                }
                                
                                // Tarih gösterimi - date özelliği Date tipindeyse
                                Text(memory.date, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .ignoresSafeArea()
                
                // Oynat/Duraklat (Play/Pause) İçin Dokunma Alanı
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isPlaying.toggle()
                        withAnimation {
                            showPauseIcon = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            withAnimation {
                                showPauseIcon = false
                            }
                        }
                    }
                
                // Oynat/Duraklat İkon Göstergesi
                if showPauseIcon {
                    Image(systemName: isPlaying ? "play.fill" : "pause.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.7))
                        .transition(.scale.combined(with: .opacity))
                }
                
                // Kapatma Butonu
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            showingExportProgress = true
                            Task {
                                await videoExporter.exportSlideshow(memories: memories)
                                if videoExporter.exportedURL != nil {
                                    showingShareSheet = true
                                }
                                showingExportProgress = false
                            }
                        } label: {
                            Image(systemName: "square.and.arrow.up.circle.fill")
                                .font(.title)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.white.opacity(0.8))
                                .padding()
                        }
                    }
                    Spacer()
                }
            }
        }
        .onReceive(timer) { _ in
            if isPlaying && !memories.isEmpty {
                withAnimation {
                    currentIndex = (currentIndex + 1) % memories.count
                }
            }
        }
        .overlay {
            if showingExportProgress {
                ZStack {
                    Color.black.opacity(0.6).ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView(value: videoExporter.progress)
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .scaleEffect(1.5)
                        Text("Video oluşturuluyor... %\(Int(videoExporter.progress * 100))")
                            .foregroundStyle(.white)
                            .font(.subheadline)
                    }
                    .padding(40)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = videoExporter.exportedURL {
                ShareSheetView(items: [url])
            }
        }
    }
}

struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
