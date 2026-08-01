//
//  AddMemoryView.swift
//  Epilogue
//
//  Created by Zehra Öner on 21.07.2026.
//

import SwiftUI
import PhotosUI

/// Yeni anı ekleme veya mevcut anıyı düzenleme sheet'i.
/// PhotosPicker ile fotoğraf seçimi, üç kelime alanı,
/// tarih seçici ve not alanı içerir.
struct AddMemoryView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: MemoryViewModel
    let depoId: String

    // MARK: - Form State
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var previewImage: UIImage?

    @State private var wordOne = ""
    @State private var wordTwo = ""
    @State private var wordThree = ""
    @State private var date = Date()
    @State private var note = ""
    @State private var locationName = ""
    @State private var latitude: Double?
    @State private var longitude: Double?
    @State private var showingLocationPicker = false
    @State private var showingLocationSearch = false

    @State private var selectedTags: Set<String> = []
    @State private var customTagText: String = ""
    private let predefinedTags = ["tatil", "doğumgünü", "aile", "arkadaş", "yemek", "spor", "müzik", "seyahat", "iş", "okul"]

    // MARK: - Time Capsule
    @State private var isTimeCapsule = false
    @State private var unlockDate = Date().addingTimeInterval(86400 * 30) // Default: 30 days later

    // MARK: - Müzik
    @State private var songName: String?
    @State private var previewAudioURL: String?
    @State private var showingMusicSearch = false

    // MARK: - Çizim
    @State private var showingMarkup = false

    /// Düzenleme modundaysa true, yeni anı ekleme modundaysa false.
    private var isEditMode: Bool { viewModel.editingMemory != nil }

    private var isFormValid: Bool {
        // Fotoğraf: yeni seçilmiş veya düzenlemede mevcut
        let hasImage = selectedImageData != nil || isEditMode
        let hasWord = !wordOne.trimmingCharacters(in: .whitespaces).isEmpty
        return hasImage && hasWord
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Fotoğraf Seçimi
                    photoSection

                    // MARK: - Kelime Alanları
                    VStack(spacing: 12) {
                        SectionHeader(title: "Bu Anı 3 Kelimeyle", icon: "textformat.abc")

                        HStack(spacing: 10) {
                            WordField(placeholder: "1. kelime", text: $wordOne)
                            WordField(placeholder: "2. kelime", text: $wordTwo)
                            WordField(placeholder: "3. kelime", text: $wordThree)
                        }
                    }
                    .padding(.horizontal, 20)

                    // MARK: - Tarih
                    VStack(spacing: 12) {
                        SectionHeader(title: "Tarih", icon: "calendar")

                        DatePicker(
                            "Anı tarihi",
                            selection: $date,
                            in: ...Date.now,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            Color(.secondarySystemBackground),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                    }
                    .padding(.horizontal, 20)

                    // MARK: - Konum
                    VStack(spacing: 12) {
                        SectionHeader(title: "Konum (isteğe bağlı)", icon: "mappin.and.ellipse")
                        
                        HStack {
                            Button {
                                showingLocationSearch = true
                            } label: {
                                HStack {
                                    if locationName.isEmpty {
                                        Text("Konum adı, şehir veya mekan...")
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Text(locationName)
                                            .foregroundStyle(.primary)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                }
                            }
                            
                            Button {
                                showingLocationPicker = true
                            } label: {
                                Image(systemName: latitude != nil ? "map.fill" : "map")
                                    .foregroundStyle(latitude != nil ? .blue : .secondary)
                                    .padding(8)
                                    .background(
                                        Color(.tertiarySystemFill),
                                        in: Circle()
                                    )
                            }
                        }
                        .padding(12)
                        .background(
                            Color(.secondarySystemBackground),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                    }
                    .padding(.horizontal, 20)

                    // MARK: - Not
                    VStack(spacing: 12) {
                        SectionHeader(title: "Not (isteğe bağlı)", icon: "note.text")

                        TextEditor(text: $note)
                            .frame(minHeight: 80)
                            .padding(12)
                            .scrollContentBackground(.hidden)
                            .background(
                                Color(.secondarySystemBackground),
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                            )
                    }
                    .padding(.horizontal, 20)

                    // MARK: - Zaman Kapsülü
                    VStack(spacing: 12) {
                        SectionHeader(title: "Zaman Kapsülü (Gizli Anı)", icon: "lock.clock")
                        
                        Toggle("Bu anıyı gelecekte açılmak üzere kilitle", isOn: $isTimeCapsule)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                Color(.secondarySystemBackground),
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                            )
                            .tint(.purple)
                        
                        if isTimeCapsule {
                            DatePicker(
                                "Açılacağı Tarih",
                                selection: $unlockDate,
                                in: Date.now...,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.compact)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                Color(.secondarySystemBackground),
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                            )
                            .transition(.opacity)
                        }
                    }
                    .padding(.horizontal, 20)

                    // MARK: - Müzik Ekle
                    VStack(spacing: 12) {
                        SectionHeader(title: "Müzik (isteğe bağlı)", icon: "music.note")
                        
                        Button {
                            showingMusicSearch = true
                        } label: {
                            HStack {
                                if let songName = songName {
                                    Image(systemName: "music.note.list")
                                        .foregroundStyle(.pink)
                                    Text(songName)
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    Spacer()
                                    Button {
                                        self.songName = nil
                                        self.previewAudioURL = nil
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                } else {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundStyle(.secondary)
                                    Text("Şarkı veya sanatçı ara...")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                Color(.secondarySystemBackground),
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                            )
                        }
                    }
                    .padding(.horizontal, 20)

                    // MARK: - Etiketler
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Etiketler")
                            .font(.headline)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(predefinedTags, id: \.self) { tag in
                                    Button {
                                        if selectedTags.contains(tag) {
                                            selectedTags.remove(tag)
                                        } else {
                                            selectedTags.insert(tag)
                                        }
                                    } label: {
                                        Text("#\(tag)")
                                            .font(.subheadline)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(selectedTags.contains(tag) ? Color.blue : Color(.secondarySystemBackground))
                                            .foregroundStyle(selectedTags.contains(tag) ? .white : .primary)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                        
                        // Custom tag input
                        HStack {
                            TextField("Özel etiket...", text: $customTagText)
                                .textFieldStyle(.roundedBorder)
                            Button("Ekle") {
                                let tag = customTagText.trimmingCharacters(in: .whitespaces).lowercased()
                                if !tag.isEmpty {
                                    selectedTags.insert(tag)
                                    customTagText = ""
                                }
                            }
                            .disabled(customTagText.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 20)
            }
            .navigationTitle(isEditMode ? "Anıyı Düzenle" : "Yeni Anı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") {
                        viewModel.cancelEditing()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditMode ? "Güncelle" : "Kaydet") {
                        Task { await save() }
                    }
                    // disabled() kaldırıldı, böylece tıklanınca hata gösterebilelim
                }
            }
            .overlay {
                if viewModel.isSaving {
                    savingOverlay
                }
            }
            .alert(
                "Hata",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                )
            ) {
                Button("Tamam", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "Bilinmeyen bir hata oluştu.")
            }
            .onChange(of: selectedPhoto) {
                Task { await loadPhoto() }
            }
            .onAppear { populateEditFields() }
            .sheet(isPresented: $showingLocationPicker) {
                LocationPickerView(
                    selectedCoordinate: Binding(
                        get: {
                            if let lat = latitude, let lon = longitude {
                                return CLLocationCoordinate2D(latitude: lat, longitude: lon)
                            }
                            return nil
                        },
                        set: { coord in
                            latitude = coord?.latitude
                            longitude = coord?.longitude
                        }
                    ),
                    locationName: $locationName
                )
            }
            .sheet(isPresented: $showingLocationSearch) {
                LocationSearchView { name, coordinate in
                    self.locationName = name
                    self.latitude = coordinate.latitude
                    self.longitude = coordinate.longitude
                }
            }
            .sheet(isPresented: $showingMusicSearch) {
                MusicSearchView { name, url in
                    self.songName = name
                    self.previewAudioURL = url
                }
            }
            .sheet(isPresented: $showingMarkup) {
                if let image = previewImage {
                    PhotoMarkupView(originalImage: image) { newImage in
                        self.previewImage = newImage
                        self.selectedImageData = newImage.jpegData(compressionQuality: 0.8)
                    }
                }
            }
        }
    }

    // MARK: - Fotoğraf Bölümü

    private var photoSection: some View {
        VStack(spacing: 12) {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Group {
                    if let previewImage {
                        Image(uiImage: previewImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 240)
                            .clipped()
                    } else if isEditMode, let url = URL(string: viewModel.editingMemory?.imageURL ?? "") {
                        // Düzenlemede mevcut fotoğrafı göster
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 240)
                                    .clipped()
                            default:
                                photoPlaceholder
                            }
                        }
                    } else {
                        photoPlaceholder
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(.quaternary, lineWidth: 1)
                )
                .overlay(alignment: .bottomTrailing) {
                    if previewImage != nil {
                        Button {
                            showingMarkup = true
                        } label: {
                            Image(systemName: "pencil.tip.crop.circle.badge.plus")
                                .font(.title)
                                .foregroundStyle(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding(12)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private var photoPlaceholder: some View {
        Rectangle()
            .fill(Color(.tertiarySystemFill))
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 36, weight: .thin))
                        .foregroundStyle(.secondary)
                    Text("Fotoğraf Seç")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
    }

    private var savingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                Text("Anı kaydediliyor…")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
            }
            .padding(28)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    // MARK: - İşlemler

    private func loadPhoto() async {
        guard let selectedPhoto else { return }
        do {
            if let data = try await selectedPhoto.loadTransferable(type: Data.self) {
                selectedImageData = data
                previewImage = UIImage(data: data)
            } else {
                print("⚠️ loadTransferable nil döndürdü.")
                viewModel.errorMessage = "Seçilen fotoğraf yüklenemedi (Veri boş)."
            }
        } catch {
            print("⚠️ Fotoğraf yükleme hatası: \(error)")
            viewModel.errorMessage = "Fotoğraf yüklenirken hata oluştu: \(error.localizedDescription)"
        }
    }

    private func populateEditFields() {
        guard let memory = viewModel.editingMemory else { return }
        wordOne = memory.wordOne
        wordTwo = memory.wordTwo
        wordThree = memory.wordThree
        date = memory.date
        note = memory.note
        locationName = memory.locationName ?? ""
        latitude = memory.latitude
        longitude = memory.longitude
        if let tags = memory.tags {
            selectedTags = Set(tags)
        }
        if let unlock = memory.unlockDate {
            isTimeCapsule = true
            unlockDate = unlock
        }
        songName = memory.songName
        previewAudioURL = memory.previewAudioURL
    }

    @MainActor
    private func save() async {
        guard let userId = authViewModel.currentUser?.id else {
            viewModel.errorMessage = "Kullanıcı kimliği bulunamadı."
            return
        }
        
        if wordOne.trimmingCharacters(in: .whitespaces).isEmpty {
            viewModel.errorMessage = "Lütfen 1. kelimeyi girdiğinizden emin olun."
            return
        }

        if let memory = viewModel.editingMemory {
            // Güncelleme
            await viewModel.updateMemory(
                memory: memory,
                wordOne: wordOne,
                wordTwo: wordTwo,
                wordThree: wordThree,
                date: date,
                note: note,
                imageData: selectedImageData,
                videoData: nil,
                audioData: nil,
                locationName: locationName.isEmpty ? nil : locationName,
                latitude: latitude,
                longitude: longitude,
                unlockDate: isTimeCapsule ? unlockDate : nil,
                tags: Array(selectedTags),
                previewAudioURL: previewAudioURL,
                songName: songName
            )
        } else {
            // Yeni anı
            guard let imageData = selectedImageData else {
                viewModel.errorMessage = "Lütfen bir fotoğraf seçin."
                return
            }
            await viewModel.addMemory(
                depoId: depoId,
                userId: userId,
                wordOne: wordOne,
                wordTwo: wordTwo,
                wordThree: wordThree,
                date: date,
                note: note,
                imageData: imageData,
                videoData: nil,
                audioData: nil,
                locationName: locationName.isEmpty ? nil : locationName,
                latitude: latitude,
                longitude: longitude,
                unlockDate: isTimeCapsule ? unlockDate : nil,
                tags: Array(selectedTags),
                previewAudioURL: previewAudioURL,
                songName: songName
            )
        }

        if viewModel.errorMessage == nil {
            dismiss()
        }
    }
}

// MARK: - Yardımcı Alt Görünümler

/// Bölüm başlığı — ikon + metin.
private struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}

/// Tek kelime giriş alanı — kısa ve yuvarlatılmış.
private struct WordField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .font(.system(size: 15, weight: .medium, design: .rounded))
            .multilineTextAlignment(.center)
            .padding(.vertical, 12)
            .background(
                Color(.secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
    }
}
