import SwiftUI
import FirebaseFirestore

struct OnThisDayView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var memories: [Memory] = []
    @State private var isLoading = true
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Anılar aranıyor...")
                } else if memories.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 56))
                            .foregroundStyle(.tertiary)
                        Text("Bugüne ait geçmiş anı bulunamadı")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Anılar biriktikçe burada seni güzel sürprizler bekleyecek!")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Header
                            VStack(spacing: 8) {
                                Text("📸")
                                    .font(.system(size: 48))
                                Text("Bugün Geçmişte")
                                    .font(.title.bold())
                                Text(Date.now.formatted(.dateTime.day().month(.wide)))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 20)
                            
                            ForEach(memories) { memory in
                                let yearsAgo = Calendar.current.dateComponents([.year], from: memory.date, to: .now).year ?? 0
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("\(yearsAgo) yıl önce")
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 4)
                                        .background(Color.blue, in: Capsule())
                                    
                                    AsyncImage(url: URL(string: memory.imageURL)) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image.resizable().scaledToFill()
                                        default:
                                            Color.gray
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 250)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    
                                    Text(memory.wordsDisplay)
                                        .font(.headline)
                                    
                                    if !memory.note.isEmpty {
                                        Text(memory.note)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .padding(.horizontal)
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Bugün")
            .task {
                await fetchOnThisDayMemories()
            }
        }
    }
    
    private func fetchOnThisDayMemories() async {
        guard let userId = authViewModel.currentUser?.id else {
            isLoading = false
            return
        }
        
        let today = Calendar.current.dateComponents([.month, .day], from: .now)
        guard let month = today.month, let day = today.day else {
            isLoading = false
            return
        }
        
        // Fetch all user's memories using collectionGroup
        do {
            let snapshot = try await db.collectionGroup("memories")
                .whereField("createdBy", isEqualTo: userId)
                .getDocuments()
            
            let allMemories = snapshot.documents.compactMap { try? $0.data(as: Memory.self) }
            
            // Filter for same month and day but different year
            let currentYear = Calendar.current.component(.year, from: .now)
            self.memories = allMemories.filter { memory in
                let components = Calendar.current.dateComponents([.month, .day, .year], from: memory.date)
                return components.month == month && components.day == day && components.year != currentYear
            }.sorted { $0.date > $1.date }
            
        } catch {
            print("On This Day fetch error: \(error)")
        }
        
        isLoading = false
    }
}
