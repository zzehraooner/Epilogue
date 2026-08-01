//
//  MemoryDetailView.swift
//  Epilogue
//
//  Created by Zehra Öner on 20.07.2026.
//

import SwiftUI

/// Tek bir anının tam ekran görünümü.
/// Fotoğrafı olabildiğince büyük gösterir, altında kelimeler,
/// tarih ve varsa not yer alır. Üst sağdaki menüden düzenleme
/// ve silme işlemleri yapılabilir.
struct MemoryDetailView: View {
    let memory: Memory
    @Bindable var viewModel: MemoryViewModel
    let depo: Depo
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var showingVoiceRecorder = false
    @State private var commentText = ""

    /// Silme yetkisi: anıyı oluşturan veya depo sahibi silebilir.
    private var canDelete: Bool {
        guard let userId = authViewModel.currentUser?.id else { return false }
        return memory.createdBy == userId || depo.ownerId == userId
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Fotoğraf
                if let videoURL = memory.videoURL, let url = URL(string: videoURL) {
                    VideoPlayerView(urlString: videoURL)
                        .frame(maxWidth: .infinity)
                        .frame(height: 350)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: 8)
                        .padding(.horizontal, 20)
                } else if !memory.imageURL.isEmpty, let url = URL(string: memory.imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: 8)
                        case .failure:
                            imageFallback(icon: "exclamationmark.triangle")
                        case .empty:
                            imageFallback(icon: "photo")
                                .overlay { ProgressView() }
                        @unknown default:
                            imageFallback(icon: "photo")
                        }
                    }
                    .padding(.horizontal, 20)
                }

                if let audioURL = memory.audioURL {
                    AudioPlayerControl(urlString: audioURL)
                        .padding(.horizontal, 20)
                }
                
                // MARK: - Müzik
                if let songName = memory.songName, let previewURL = memory.previewAudioURL {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "music.note.list")
                                .foregroundStyle(.pink)
                            Text(songName)
                                .font(.subheadline.bold())
                        }
                        AudioPlayerControl(urlString: previewURL)
                    }
                    .padding(.horizontal, 20)
                }

                // MARK: - Kelimeler & Tarih
                VStack(spacing: 8) {
                    Text(memory.wordsDisplay)
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .multilineTextAlignment(.center)

                    Text(memory.date.formatted(date: .long, time: .omitted))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24)

                // MARK: - Not
                if !memory.note.trimmingCharacters(in: .whitespaces).isEmpty {
                    Text(memory.note)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                }

                // MARK: - Reactions
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        let emojis = ["❤️", "😂", "😍", "😢", "🔥"]
                        ForEach(emojis, id: \.self) { emoji in
                            let count = memory.reactions?[emoji]?.count ?? 0
                            let hasReacted = memory.reactions?[emoji]?.contains(authViewModel.currentUser?.id ?? "") ?? false

                            Button {
                                if let userId = authViewModel.currentUser?.id {
                                    Task {
                                        await viewModel.toggleReaction(memory: memory, userId: userId, emoji: emoji)
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(emoji)
                                    if count > 0 {
                                        Text("\(count)")
                                            .font(.subheadline.bold())
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(hasReacted ? Color.accentColor.opacity(0.2) : Color(.secondarySystemBackground))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Button {
                            showingVoiceRecorder = true
                        } label: {
                            Image(systemName: "mic.badge.plus")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.top, 8)
                
                if let voiceReactions = memory.voiceReactions, !voiceReactions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sesli Tepkiler")
                            .font(.subheadline.bold())
                            .padding(.horizontal, 24)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(Array(voiceReactions.keys), id: \.self) { userId in
                                    if let urlString = voiceReactions[userId] {
                                        AudioPlayerControl(urlString: urlString)
                                            .frame(width: 150)
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                }
                
                // MARK: - Yorumlar
                VStack(alignment: .leading, spacing: 12) {
                    Text("Yorumlar")
                        .font(.headline)
                        .padding(.horizontal, 24)
                    
                    ForEach(viewModel.comments) { comment in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "person.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(comment.displayName)
                                        .font(.subheadline.bold())
                                    Spacer()
                                    Text(comment.createdAt, style: .relative)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                                Text(comment.text)
                                    .font(.subheadline)
                            }
                            
                            if comment.userId == authViewModel.currentUser?.id {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.deleteComment(memory: memory, commentId: comment.id)
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.red)
                                }
                                .padding(.leading, 8)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 4)
                    }
                    
                    // Comment input
                    HStack {
                        TextField("Yorum yaz...", text: $commentText)
                            .textFieldStyle(.roundedBorder)
                        
                        Button {
                            if let user = authViewModel.currentUser, !commentText.trimmingCharacters(in: .whitespaces).isEmpty {
                                Task {
                                    await viewModel.addComment(memory: memory, userId: user.id, displayName: user.displayName, text: commentText)
                                    commentText = ""
                                }
                            }
                        } label: {
                            Image(systemName: "paperplane.fill")
                                .foregroundStyle(.blue)
                        }
                        .disabled(commentText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.top, 16)
            }
            .padding(.vertical, 24)
        }
        .onAppear {
            viewModel.listenForComments(depoId: memory.depoId, memoryId: memory.id)
        }
        .onDisappear {
            viewModel.stopListeningComments()
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack {
                    Button {
                        if let userId = authViewModel.currentUser?.id {
                            Task {
                                await viewModel.toggleFavorite(memory: memory, userId: userId)
                            }
                        }
                    } label: {
                        let isFavorited = memory.favoritedBy?.contains(authViewModel.currentUser?.id ?? "") ?? false
                        Image(systemName: isFavorited ? "star.fill" : "star")
                            .foregroundStyle(isFavorited ? .yellow : .primary)
                    }

                    Menu {
                        Button {
                            viewModel.startEditing(memory)
                            showingEditSheet = true
                        } label: {
                            Label("Düzenle", systemImage: "pencil")
                        }

                        if canDelete {
                            Button(role: .destructive) {
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Sil", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            AddMemoryView(
                viewModel: viewModel,
                depoId: memory.depoId
            )
        }
        .confirmationDialog(
            "Bu anıyı silmek istediğine emin misin?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Sil", role: .destructive) {
                Task {
                    await viewModel.deleteMemory(memory)
                    dismiss()
                }
            }
            Button("Vazgeç", role: .cancel) {}
        }
        .sheet(isPresented: $showingVoiceRecorder) {
            VoiceReactionRecorderView { url in
                if let userId = authViewModel.currentUser?.id {
                    Task {
                        await viewModel.uploadVoiceReaction(memory: memory, userId: userId, fileURL: url)
                    }
                }
            }
        }
    }

    private func imageFallback(icon: String) -> some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color(.tertiarySystemFill))
            .frame(height: 280)
            .overlay {
                Image(systemName: icon)
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
    }
}
