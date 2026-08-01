import SwiftUI

struct Badge {
    let id: String
    let title: String
    let icon: String
    let color: Color
    let description: String
}

let availableBadges: [Badge] = [
    Badge(id: "first_memory", title: "İlk Anı", icon: "sparkles", color: .yellow, description: "Depoya ilk anıyı ekledin!"),
    Badge(id: "music_lover", title: "Müzik Aşığı", icon: "music.note", color: .pink, description: "Anılarına müzik eklemeyi seviyorsun."),
    Badge(id: "traveler", title: "Gezgin", icon: "map", color: .blue, description: "Farklı konumlarda anılar biriktirdin."),
    Badge(id: "social_butterfly", title: "Sosyal Kelebek", icon: "heart", color: .red, description: "Sesli tepkiler ve emojilerle çok aktifsin.")
]

struct BadgesView: View {
    let userBadges: [String]?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Başarımlar ve Rozetler")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(availableBadges, id: \.id) { badge in
                        let hasBadge = userBadges?.contains(badge.id) ?? false
                        
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(hasBadge ? badge.color.opacity(0.2) : Color(.systemGray6))
                                    .frame(width: 70, height: 70)
                                
                                Image(systemName: badge.icon)
                                    .font(.system(size: 30))
                                    .foregroundStyle(hasBadge ? badge.color : .gray)
                            }
                            
                            Text(badge.title)
                                .font(.caption.bold())
                                .foregroundStyle(hasBadge ? .primary : .secondary)
                                .multilineTextAlignment(.center)
                                .frame(width: 80)
                        }
                        .opacity(hasBadge ? 1.0 : 0.5)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
}
