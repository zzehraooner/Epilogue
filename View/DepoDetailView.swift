//
//  DepoDetailView.swift
//  Epilogue
//
//  Created by Zehra Öner on 21.07.2026.
//

import SwiftUI
import ActivityKit

/// Tek bir deponun detay ekranı: depodaki tüm anıları grid halinde
/// gösterir. Üstte depo bilgisi ve davet kodu, altta anı kartları.
struct DepoDetailView: View {
    enum ViewMode {
        case grid, timeline
    }

    let depo: Depo
    let depoViewModel: DepoViewModel
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var memoryViewModel = MemoryViewModel()
    @State private var showingAddSheet = false
    @State private var showingInviteCode = false
    @State private var showingSettings = false
    @State private var showingSlideshow = false
    @State private var showingMoodBoard = false
    @State private var codeCopied = false
    @State private var searchText = ""
    @State private var viewMode: ViewMode = .grid
    @State private var selectedFilterTag: String? = nil

    private var allTags: [String] {
        let tags = memoryViewModel.memories.compactMap { $0.tags }.flatMap { $0 }
        return Array(Set(tags)).sorted()
    }

    var filteredMemories: [Memory] {
        var result = memoryViewModel.memories
        if !searchText.isEmpty {
            result = result.filter { memory in
                let w1 = memory.wordOne.localizedCaseInsensitiveContains(searchText)
                let w2 = memory.wordTwo.localizedCaseInsensitiveContains(searchText)
                let w3 = memory.wordThree.localizedCaseInsensitiveContains(searchText)
                let note = memory.note.localizedCaseInsensitiveContains(searchText)
                return w1 || w2 || w3 || note
            }
        }
        if let tag = selectedFilterTag {
            result = result.filter { $0.tags?.contains(tag) ?? false }
        }
        return result
    }

    private let gridColumns = [GridItem(.adaptive(minimum: 160), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Depo Bilgi Başlığı
                depoHeader
                
                if !allTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            Button {
                                selectedFilterTag = nil
                            } label: {
                                Text("Tümü")
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedFilterTag == nil ? Color.blue : Color(.secondarySystemBackground))
                                    .foregroundStyle(selectedFilterTag == nil ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                            
                            ForEach(allTags, id: \.self) { tag in
                                Button {
                                    selectedFilterTag = (selectedFilterTag == tag) ? nil : tag
                                } label: {
                                    Text("#\(tag)")
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedFilterTag == tag ? Color.blue : Color(.secondarySystemBackground))
                                        .foregroundStyle(selectedFilterTag == tag ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                Picker("Görünüm", selection: $viewMode) {
                    Text("Izgara").tag(ViewMode.grid)
                    Text("Zaman Çizelgesi").tag(ViewMode.timeline)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // MARK: - Anı Grid / Zaman Çizelgesi
                if filteredMemories.isEmpty && !memoryViewModel.isLoading {
                    emptyState
                } else if memoryViewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                } else {
                    if viewMode == .grid {
                        LazyVGrid(columns: gridColumns, spacing: 12) {
                            ForEach(filteredMemories) { memory in
                                NavigationLink {
                                    MemoryDetailView(
                                        memory: memory,
                                        viewModel: memoryViewModel,
                                        depo: depo
                                    )
                                } label: {
                                    MemoryCard(memory: memory)
                                }
                                .buttonStyle(ScaleButtonStyle())
                                .disabled((memory.unlockDate ?? Date.distantPast) > Date())
                            }
                        }
                        .padding(.horizontal, 16)
                    } else {
                        TimelineView(
                            memories: filteredMemories,
                            viewModel: memoryViewModel,
                            depo: depo
                        )
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Anılarda ara...")
        .navigationTitle(depo.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 12) {
                    NavigationLink {
                        MemoryMapView(
                            memories: memoryViewModel.memories,
                            depo: depo,
                            memoryViewModel: memoryViewModel
                        )
                    } label: {
                        Image(systemName: "map")
                    }

                    NavigationLink {
                        DepoPlaylistView(depo: depo, memories: memoryViewModel.memories)
                    } label: {
                        Image(systemName: "music.note.list")
                    }

                    NavigationLink {
                        ChatView(depo: depo)
                    } label: {
                        Image(systemName: "message")
                    }

                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }

                    Button {
                        showingInviteCode = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                    }

                    Button {
                        showingSlideshow = true
                    } label: {
                        Image(systemName: "play.circle")
                    }
                    .disabled(filteredMemories.isEmpty)
                    
                    Button {
                        showingMoodBoard = true
                    } label: {
                        Image(systemName: "photo.stack")
                    }
                    .disabled(filteredMemories.isEmpty)
                    
                    Button {
                        startLiveActivity()
                    } label: {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                    }
                    
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddMemoryView(
                viewModel: memoryViewModel,
                depoId: depo.id
            )
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                DepoSettingsView(depo: depo, memories: memoryViewModel.memories, depoViewModel: depoViewModel)
            }
        }
        .alert("Davet Kodu", isPresented: $showingInviteCode) {
            Button("Kopyala") {
                UIPasteboard.general.string = depo.inviteCode
                codeCopied = true
            }
            Button("Tamam", role: .cancel) {}
        } message: {
            Text("Bu kodu arkadaşlarınla paylaş:\n\n\(depo.inviteCode)")
        }
        .overlay {
            if codeCopied {
                copiedToast
            }
        }
        .fullScreenCover(isPresented: $showingSlideshow) {
            SlideshowView(memories: filteredMemories)
        }
        .sheet(isPresented: $showingMoodBoard) {
            MoodBoardView(depo: depo, memories: filteredMemories)
        }
        .onAppear {
            memoryViewModel.startListening(depoId: depo.id)
        }
        .onDisappear {
            memoryViewModel.stopListening()
        }
    }

    // MARK: - Alt Görünümler

    private var depoHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(depo.memberIds.count) üye")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(memoryViewModel.memories.count) anı")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                UIPasteboard.general.string = depo.inviteCode
                withAnimation { codeCopied = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation { codeCopied = false }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                    Text(depo.inviteCode)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [Color.pink.opacity(0.2), Color.orange.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 10)
                
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(colors: [.pink, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            .padding(.bottom, 8)
            
            VStack(spacing: 8) {
                Text("Depo Bomboş")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(.primary)
                
                Text("Sevdiklerinle yaşadığın ilk anıyı ekleyerek bu depoyu canlandır!")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button {
                showingAddSheet = true
            } label: {
                Text("İlk Anını Ekle")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .pink.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .padding(.horizontal, 40)
            .padding(.top, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 80)
    }

    private var copiedToast: some View {
        VStack {
            Spacer()
            Text("✓ Davet kodu kopyalandı")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.black.opacity(0.8), in: Capsule())
                .padding(.bottom, 32)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .allowsHitTesting(false)
    }
    
    private func startLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let attributes = StashActivityAttributes(depoName: depo.name)
        let state = StashActivityAttributes.ContentState(
            memoryCount: memoryViewModel.memories.count,
            latestMemoryName: memoryViewModel.memories.first?.wordsDisplay ?? "Henüz yok"
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil)
            )
            print("Live Activity started: \(activity.id)")
        } catch {
            print("Error starting Live Activity: \(error)")
        }
    }
}

// MARK: - Anı Kartı

/// Grid içindeki tek bir anı kartı — küçük fotoğraf üstünde
/// kelimeler ve tarih.
struct MemoryCard: View {
    let memory: Memory
    @Environment(AuthViewModel.self) private var authViewModel

    var isLocked: Bool {
        if let unlock = memory.unlockDate, unlock > Date() { return true }
        return false
    }

    var body: some View {
        if isLocked {
            LockedMemoryCard(memory: memory)
        } else {
            cardContent
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Fotoğraf / Video
            mediaView
                .frame(height: 140)
                .clipped()
                .overlay(alignment: .topTrailing) {
                    badgeIcons
                }

            // Bilgi alanı
            VStack(alignment: .leading, spacing: 4) {
                Text(memory.wordsDisplay)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .lineLimit(1)

                HStack {
                    Text(memory.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let reactions = memory.reactions {
                        let totalReactions = reactions.values.reduce(0) { $0 + $1.count }
                        if totalReactions > 0 {
                            HStack(spacing: 2) {
                                Text("❤️")
                                    .font(.caption2)
                                Text("\(totalReactions)")
                                    .font(.caption2.bold())
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    }

    @ViewBuilder
    private var mediaView: some View {
        if memory.videoURL != nil {
            ZStack {
                Color.black
                Image(systemName: "play.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.white)
            }
        } else {
            AsyncImage(url: URL(string: memory.imageURL)) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    placeholder(icon: "exclamationmark.triangle")
                case .empty:
                    placeholder(icon: "photo")
                        .overlay { ProgressView() }
                @unknown default:
                    placeholder(icon: "photo")
                }
            }
        }
    }

    @ViewBuilder
    private var badgeIcons: some View {
        HStack {
            if memory.previewAudioURL != nil {
                Image(systemName: "music.note")
                    .foregroundStyle(.pink)
                    .shadow(radius: 2)
                    .padding(8)
            }
            if memory.audioURL != nil {
                Image(systemName: "mic.fill")
                    .foregroundStyle(.white)
                    .shadow(radius: 2)
                    .padding(8)
            }
            let isFav = memory.favoritedBy?.contains(authViewModel.currentUser?.id ?? "") ?? false
            if isFav {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .shadow(radius: 2)
                    .padding(8)
            }
        }
    }

    private func placeholder(icon: String) -> some View {
        Rectangle()
            .fill(Color(.tertiarySystemFill))
            .overlay {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
    }
}
