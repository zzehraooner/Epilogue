import SwiftUI

struct MoodBoardView: View {
    let depo: Depo
    let memories: [Memory]
    @Environment(\.dismiss) private var dismiss
    @State private var generatedImage: Image?
    
    // Rastgele döndürme açıları ve pozisyonlar (sabit kalması için)
    @State private var rotations: [Double] = []
    @State private var offsetsX: [CGFloat] = []
    @State private var offsetsY: [CGFloat] = []
    
    var topMemories: [Memory] {
        // En son eklenen veya en çok beğenilen 4 anı
        Array(memories.prefix(4))
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if generatedImage == nil {
                    // Render edilecek alan
                    collageContent
                        .frame(width: 300, height: 500)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(radius: 10)
                        .padding()
                } else {
                    // Render edilmiş Image (Önizleme)
                    generatedImage?
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 500)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(radius: 10)
                        .padding()
                }
                
                Spacer()
                
                if let generatedImage = generatedImage {
                    ShareLink(
                        item: generatedImage,
                        preview: SharePreview("Stash Mood Board", image: generatedImage)
                    ) {
                        Label("Hikayede Paylaş", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                    }
                } else {
                    ProgressView("Kolaj Hazırlanıyor...")
                        .padding()
                }
            }
            .navigationTitle("Mood Board")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
            .onAppear {
                setupRandoms()
                Task {
                    await renderImage()
                }
            }
        }
    }
    
    private func setupRandoms() {
        for _ in 0..<topMemories.count {
            rotations.append(Double.random(in: -15...15))
            offsetsX.append(CGFloat.random(in: -30...30))
            offsetsY.append(CGFloat.random(in: -30...30))
        }
    }
    
    private var collageContent: some View {
        ZStack {
            // Arka Plan
            LinearGradient(
                colors: [Color(hex: "FF9A9E"), Color(hex: "FECFEF")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                Text(depo.name)
                    .font(.system(size: 32, weight: .black, design: .serif))
                    .foregroundStyle(.white)
                    .padding(.top, 40)
                    .shadow(radius: 5)
                
                Text("Anılarımız (\(memories.count))")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))
                
                Spacer()
                
                ZStack {
                    ForEach(Array(topMemories.enumerated()), id: \.element.id) { index, memory in
                        if index < rotations.count {
                            AsyncImage(url: URL(string: memory.imageURL)) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 140, height: 180)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.white, lineWidth: 4)
                                        )
                                        .shadow(color: .black.opacity(0.2), radius: 5, x: 2, y: 5)
                                        .rotationEffect(.degrees(rotations[index]))
                                        .offset(x: offsetsX[index], y: offsetsY[index])
                                } else {
                                    Color.white.frame(width: 140, height: 180)
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .frame(width: 300, height: 500)
    }
    
    @MainActor
    private func renderImage() async {
        // Wait for AsyncImage downloads
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        let renderer = ImageRenderer(content: collageContent)
        renderer.scale = UIScreen.main.scale
        
        if let uiImage = renderer.uiImage {
            self.generatedImage = Image(uiImage: uiImage)
        }
    }
}
