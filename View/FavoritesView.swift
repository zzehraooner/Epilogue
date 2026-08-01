//
//  FavoritesView.swift
//  Epilogue
//
//  Created by Zehra Öner on 21.07.2026.
//

import SwiftUI
import FirebaseFirestore

struct FavoritesView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var memories: [Memory] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let db = Firestore.firestore()
    private let gridColumns = [GridItem(.adaptive(minimum: 160), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    ProgressView()
                        .padding(.top, 60)
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .padding()
                } else if memories.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "star.slash")
                            .font(.system(size: 48, weight: .thin))
                            .foregroundStyle(.secondary)
                        Text("Henüz favori anı yok")
                            .font(.headline)
                        Text("Beğendiğiniz anılar burada görünecek")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                } else {
                    LazyVGrid(columns: gridColumns, spacing: 12) {
                        ForEach(memories) { memory in
                            MemoryCard(memory: memory)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Favorilerim")
            .onAppear {
                fetchFavorites()
            }
        }
    }
    
    private func fetchFavorites() {
        guard let userId = authViewModel.currentUser?.id else { return }
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let snapshot = try await db.collectionGroup("memories")
                    .whereField("favoritedBy", arrayContains: userId)
                    .getDocuments()
                
                await MainActor.run {
                    memories = snapshot.documents.compactMap { try? $0.data(as: Memory.self) }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Favoriler yüklenemedi: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}
