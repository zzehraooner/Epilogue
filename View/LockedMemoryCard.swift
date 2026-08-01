import SwiftUI

struct LockedMemoryCard: View {
    let memory: Memory
    
    var timeRemaining: String {
        guard let unlockDate = memory.unlockDate else { return "" }
        let components = Calendar.current.dateComponents([.day, .hour], from: Date(), to: unlockDate)
        
        let days = components.day ?? 0
        let hours = components.hour ?? 0
        
        if days > 0 {
            return "\(days) Gün \(hours) Saat Kaldı"
        } else if hours > 0 {
            return "\(hours) Saat Kaldı"
        } else {
            return "Çok Yakında Açılacak"
        }
    }
    
    var body: some View {
        ZStack {
            // Arka Plan (Bulanık Görüntü)
            if let url = URL(string: memory.imageURL) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable()
                            .scaledToFill()
                    } else {
                        Color(.systemGray5)
                    }
                }
                .blur(radius: 20)
                .overlay(Color.black.opacity(0.4))
            }
            
            // Kilit İkonu ve Sayaç
            VStack(spacing: 16) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.white)
                    .shadow(radius: 4)
                
                Text("Zaman Kapsülü")
                    .font(.title3)
                    .bold()
                    .foregroundStyle(.white)
                
                Text(timeRemaining)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
            }
        }
        .frame(height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }
}
