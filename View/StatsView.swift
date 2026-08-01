import SwiftUI
import Charts

struct StatsView: View {
    let memories: [Memory]
    
    // Anıları aylara göre gruplamak için
    private var memoriesByMonth: [(month: String, count: Int)] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        
        var counts: [String: Int] = [:]
        for memory in memories {
            let month = formatter.string(from: memory.date)
            counts[month, default: 0] += 1
        }
        
        // Sıralama
        return counts.map { (month: $0.key, count: $0.value) }
            .sorted { a, b in
                guard let dateA = formatter.date(from: a.month),
                      let dateB = formatter.date(from: b.month) else { return false }
                return dateA < dateB
            }
    }
    
    // En aktif üye
    private var mostActiveMemberId: String? {
        var counts: [String: Int] = [:]
        for memory in memories {
            counts[memory.createdBy, default: 0] += 1
        }
        return counts.max { $0.value < $1.value }?.key
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Toplam Anı
                StatCard(title: "Toplam Anı", value: "\(memories.count)", icon: "photo.stack")
                
                // İlk Anı Tarihi
                if let firstMemory = memories.min(by: { $0.date < $1.date }) {
                    StatCard(
                        title: "İlk Anı",
                        value: firstMemory.date.formatted(date: .long, time: .omitted),
                        icon: "calendar"
                    )
                }
                
                // Aylara Göre Anılar Grafiği
                if !memoriesByMonth.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Aylara Göre Anılar")
                            .font(.headline)
                        
                        Chart {
                            ForEach(memoriesByMonth, id: \.month) { item in
                                BarMark(
                                    x: .value("Ay", item.month),
                                    y: .value("Anı Sayısı", item.count)
                                )
                                .foregroundStyle(.blue.gradient)
                                .cornerRadius(4)
                            }
                        }
                        .frame(height: 200)
                    }
                    .padding()
                    .background(
                        Color(.secondarySystemBackground),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                }
                
                // En Aktif Üye
                if let activeId = mostActiveMemberId {
                    StatCard(
                        title: "En Aktif Üye",
                        value: "Üye (\(activeId.prefix(6)))",
                        icon: "person.fill.badge.plus"
                    )
                }
            }
            .padding()
        }
        .navigationTitle("İstatistikler")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title2)
                    .bold()
            }
            Spacer()
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(.blue.opacity(0.8))
        }
        .padding()
        .background(
            Color(.secondarySystemBackground),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }
}
