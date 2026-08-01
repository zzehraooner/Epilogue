import SwiftUI

/// Kitap Kapağı
struct CoverPageTemplate: View {
    let depoName: String
    let memoryCount: Int
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "book.closed.fill")
                .font(.system(size: 80))
                .foregroundStyle(.black.opacity(0.8))
            
            Text(depoName)
                .font(.system(size: 36, weight: .bold, design: .serif))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Text("Anı Albümü")
                .font(.system(size: 24, weight: .light, design: .serif))
                .foregroundStyle(.gray)
            
            Rectangle()
                .fill(.black)
                .frame(width: 60, height: 2)
                .padding(.vertical, 20)
            
            Text("\(memoryCount) Anı")
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundStyle(.gray)
            
            Spacer()
            
            Text("Stash ile oluşturuldu")
                .font(.caption)
                .foregroundStyle(.gray)
                .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

/// Arka Kapak
struct BackCoverTemplate: View {
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "leaf.fill")
                .font(.system(size: 40))
                .foregroundStyle(.gray.opacity(0.3))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}

/// Polaroid Tarzı Sayfa Şablonu
struct PolaroidPageTemplate: View {
    let memory: Memory
    let uiImage: UIImage?
    
    var body: some View {
        VStack {
            Spacer()
            
            // Polaroid Çerçevesi
            VStack(spacing: 0) {
                if let uiImage = uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 320, height: 320)
                        .clipped()
                        .padding([.top, .leading, .trailing], 16)
                } else {
                    Rectangle()
                        .fill(Color(white: 0.95))
                        .frame(width: 320, height: 320)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundStyle(.gray)
                        }
                        .padding([.top, .leading, .trailing], 16)
                }
                
                // Kelimeler ve Tarih
                VStack(spacing: 8) {
                    Text("\(memory.wordOne) • \(memory.wordTwo) • \(memory.wordThree)")
                        .font(.custom("Marker Felt", size: 22)) // El yazısı benzeri font
                        .foregroundStyle(.black)
                        .multilineTextAlignment(.center)
                        
                    Text(memory.date.formatted(date: .long, time: .omitted))
                        .font(.system(size: 14, weight: .medium, design: .serif))
                        .foregroundStyle(.gray)
                }
                .frame(width: 320, height: 100)
                .background(Color.white)
            }
            .background(Color.white)
            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
            
            if !memory.note.isEmpty {
                Text(memory.note)
                    .font(.system(size: 16, weight: .regular, design: .serif))
                    .foregroundStyle(.black.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 40)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(white: 0.98)) // Hafif kirli beyaz arka plan
    }
}

/// Minimalist Tarz Sayfa Şablonu
struct MinimalistPageTemplate: View {
    let memory: Memory
    let uiImage: UIImage?
    
    var body: some View {
        VStack(spacing: 30) {
            HStack {
                Text(memory.date.formatted(date: .long, time: .omitted).uppercased())
                    .font(.system(size: 12, weight: .light, design: .default))
                    .tracking(2)
                    .foregroundStyle(.gray)
                Spacer()
                if let location = memory.locationName {
                    Text(location.uppercased())
                        .font(.system(size: 12, weight: .light, design: .default))
                        .tracking(2)
                        .foregroundStyle(.gray)
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 40)
            
            if let uiImage = uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 300)
                    .padding(.horizontal, 40)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(maxWidth: .infinity, maxHeight: 300)
                    .padding(.horizontal, 40)
            }
            
            VStack(spacing: 12) {
                Text("\(memory.wordOne) / \(memory.wordTwo) / \(memory.wordThree)")
                    .font(.system(size: 18, weight: .regular, design: .serif))
                    .italic()
                
                if !memory.note.isEmpty {
                    Text(memory.note)
                        .font(.system(size: 14, weight: .light, design: .serif))
                        .lineSpacing(6)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.black.opacity(0.8))
                }
            }
            .padding(.horizontal, 40)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
}
