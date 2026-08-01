import SwiftUI

struct YearInReviewView: View {
    @Environment(\.dismiss) var dismiss
    let memories: [Memory]
    
    @State private var introCount: Int = 0
    @State private var currentPage = 0
    
    private var totalCount: Int { memories.count }

    private var mostActiveMonth: (month: String, count: Int)? {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        formatter.locale = Locale(identifier: "tr_TR")
        var counts: [String: Int] = [:]
        for m in memories {
            counts[formatter.string(from: m.date), default: 0] += 1
        }
        return counts.max { $0.value < $1.value }.map { (month: $0.key, count: $0.value) }
    }

    private var topWords: [(word: String, count: Int)] {
        var counts: [String: Int] = [:]
        for m in memories {
            for w in [m.wordOne, m.wordTwo, m.wordThree] where !w.trimmingCharacters(in: .whitespaces).isEmpty {
                counts[w.lowercased(), default: 0] += 1
            }
        }
        return counts.sorted { $0.value > $1.value }.prefix(3).map { (word: $0.key, count: $0.value) }
    }

    private var mostLikedMemory: Memory? {
        memories.max { a, b in
            let aCount = (a.favoritedBy?.count ?? 0) + (a.reactions?.values.reduce(0) { $0 + $1.count } ?? 0)
            let bCount = (b.favoritedBy?.count ?? 0) + (b.reactions?.values.reduce(0) { $0 + $1.count } ?? 0)
            return aCount < bCount
        }
    }

    private var daysSinceFirst: Int {
        guard let first = memories.min(by: { $0.date < $1.date }) else { return 0 }
        return Calendar.current.dateComponents([.day], from: first.date, to: .now).day ?? 0
    }
    
    private var mostActiveDepo: (depoId: String, count: Int)? {
        var counts: [String: Int] = [:]
        for m in memories {
            counts[m.depoId, default: 0] += 1
        }
        return counts.max { $0.value < $1.value }.map { (depoId: $0.key, count: $0.value) }
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            TabView(selection: $currentPage) {
                // Page 1: Intro
                ZStack {
                    LinearGradient(colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Text("🎉 2026 Yılında...")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("\(introCount)")
                            .font(.system(size: 80, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("anı biriktirdin")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    .transition(.opacity)
                }
                .tag(0)
                .onAppear {
                    animateCount()
                }
                
                // Page 2: Most Active Month
                ZStack {
                    LinearGradient(colors: [Color(hex: "4A00E0"), Color(hex: "8E2DE2")], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Text("En Aktif Ayın")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        if let month = mostActiveMonth {
                            Text(month.month.capitalized)
                                .font(.system(size: 60, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("\(month.count) anı")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.8))
                        } else {
                            Text("Veri yok")
                                .foregroundColor(.white)
                        }
                    }
                    .transition(.opacity)
                }
                .tag(1)
                
                // Page 3: Most Used Words
                ZStack {
                    LinearGradient(colors: [Color(hex: "00C9FF"), Color(hex: "92FE9D")], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 30) {
                        Text("En Çok Kullandığın Kelimeler")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        VStack(spacing: 15) {
                            let words = topWords
                            if words.count > 0 {
                                Text(words[0].word)
                                    .font(.system(size: 60, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            if words.count > 1 {
                                Text(words[1].word)
                                    .font(.system(size: 45, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            if words.count > 2 {
                                Text(words[2].word)
                                    .font(.system(size: 35, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                    .transition(.opacity)
                }
                .tag(2)
                
                // Page 4: Most Active Depo
                ZStack {
                    LinearGradient(colors: [Color(hex: "FC466B"), Color(hex: "3F5EFB")], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Text("En Çok Paylaşım Yaptığın Depo")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        if let depo = mostActiveDepo {
                            let shortId = String(depo.depoId.prefix(8))
                            Text(shortId)
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("\(depo.count) anı")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.8))
                        } else {
                            Text("Veri yok")
                                .foregroundColor(.white)
                        }
                    }
                    .transition(.opacity)
                }
                .tag(3)
                
                // Page 5: Most Liked Memory
                ZStack {
                    LinearGradient(colors: [Color(hex: "11998E"), Color(hex: "38EF7D")], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Text("En Çok Etkileşim Alan Anın")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        if let memory = mostLikedMemory {
                            if let url = URL(string: memory.imageURL) {
                                AsyncImage(url: url) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    Color.white.opacity(0.3)
                                }
                                .frame(width: 250, height: 250)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .shadow(radius: 10)
                            }
                            
                            HStack(spacing: 10) {
                                Text(memory.wordOne)
                                Text(memory.wordTwo)
                                Text(memory.wordThree)
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(10)
                        } else {
                            Text("Veri yok")
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .transition(.opacity)
                }
                .tag(4)
                
                // Page 6: Summary
                ZStack {
                    LinearGradient(colors: [Color(hex: "2C3E50"), Color(hex: "4CA1AF")], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 30) {
                        Text("İlk anından bugüne")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("\(daysSinceFirst) gün")
                            .font(.system(size: 70, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("geçti.")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Button(action: {
                            // Share action if needed
                        }) {
                            Label("Paylaş", systemImage: "square.and.arrow.up")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(width: 200)
                                .background(Color.white.opacity(0.3))
                                .cornerRadius(15)
                        }
                        .padding(.top, 40)
                    }
                    .transition(.opacity)
                }
                .tag(5)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeIn, value: currentPage)
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white.opacity(0.8))
                    .padding()
            }
        }
    }
    
    private func animateCount() {
        let step = max(1, totalCount / 30)
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if introCount < totalCount {
                introCount += step
                if introCount > totalCount {
                    introCount = totalCount
                }
            } else {
                timer.invalidate()
            }
        }
    }
}
