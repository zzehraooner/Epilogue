//
//  DepoListView.swift
//  Epilogue
//
//  Created by Zehra Öner on 20.07.2026.
//

import SwiftUI

/// Kullanıcının üyesi olduğu tüm depoları gösteren ana ekran.
/// Canlı gradient kartlar, sağ alt köşede "+" ile yeni depo /
/// davet koduyla katılma seçenekleri.
struct DepoListView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var depoViewModel = DepoViewModel()
    @State private var showingActionSheet = false
    @State private var showingCreateSheet = false
    @State private var showingJoinSheet = false

    private let gridColumns = [GridItem(.adaptive(minimum: 160), spacing: 16)]

    var body: some View {
        NavigationStack {
            ScrollView {
                if depoViewModel.depos.isEmpty && !depoViewModel.isLoading {
                    emptyState
                } else {
                    LazyVGrid(columns: gridColumns, spacing: 16) {
                        ForEach(depoViewModel.depos) { depo in
                            NavigationLink {
                                DepoDetailView(depo: depo, depoViewModel: depoViewModel)
                            } label: {
                                DepoCard(depo: depo)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Depolarım")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingCreateSheet = true
                        } label: {
                            Label("Yeni Depo Oluştur", systemImage: "plus.rectangle.on.folder")
                        }
                        Button {
                            showingJoinSheet = true
                        } label: {
                            Label("Davet Koduyla Katıl", systemImage: "person.badge.plus")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }

            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateDepoSheet(depoViewModel: depoViewModel)
            }
            .sheet(isPresented: $showingJoinSheet) {
                JoinDepoSheet(depoViewModel: depoViewModel)
            }

            .onAppear {
                if let userId = authViewModel.currentUser?.id {
                    depoViewModel.startListening(userId: userId)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 10)
                
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(
                        LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            .padding(.bottom, 8)
            
            VStack(spacing: 8) {
                Text("Depo Bulunamadı")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(.primary)
                
                Text("Anılarını güvende tutacağın ilk deponu oluştur veya davet koduyla sevdiklerinin deposuna katıl.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button {
                showingCreateSheet = true
            } label: {
                Text("İlk Deponu Oluştur")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .padding(.horizontal, 40)
            .padding(.top, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 80)
    }
}

/// Tek bir depo kartı — canlı gradient arka plan, üzerinde depo adı
/// ve üye sayısı.
struct DepoCard: View {
    let depo: Depo

    /// Depo id'sine göre sabit bir gradient renk çifti seçer,
    /// böylece her depo görsel olarak farklı ama tutarlı görünür.
    private var gradientColors: [Color] {
        let palette: [[String]] = [
            ["FF6B6B", "FFD93D"],
            ["4361EE", "9B5DE5"],
            ["00C9A7", "4361EE"],
            ["F72585", "7209B7"]
        ]
        let index = abs(depo.id.hashValue) % palette.count
        return palette[index].map { Color(hex: $0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Spacer()
            Image(systemName: "shippingbox.fill")
                .font(.title2)
                .foregroundStyle(.white)
            Text(depo.name)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2)
            Text("\(depo.memberIds.count) üye")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(16)
        .frame(height: 150, alignment: .leading)
        .frame(maxWidth: .infinity)
        .background {
            if let coverURL = depo.coverImageURL, !coverURL.isEmpty {
                AsyncImage(url: URL(string: coverURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .overlay(Color.black.opacity(0.35))
                    default:
                        LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    }
                }
            } else {
                LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        // Daha belirgin ve zarif bir gölge
        .shadow(color: gradientColors[0].opacity(0.4), radius: 15, x: 0, y: 8)
        // İnce bir çerçeve (Glassmorphism hissiyatı için)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    }
}

/// Basıldığında hafifçe küçülen modern buton stili
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    DepoListView()
        .environment(AuthViewModel())
}
