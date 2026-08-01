//
//  CreateDepoSheet.swift
//  Epilogue
//
//  Created by Zehra Öner on 20.07.2026.
//

import SwiftUI
import PhotosUI

struct CreateDepoSheet: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.dismiss) private var dismiss
    var depoViewModel: DepoViewModel

    @State private var name = ""
    @State private var isSubmitting = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var previewImage: UIImage?
    @State private var localError: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            if let previewImage {
                                Image(uiImage: previewImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(uiColor: .systemGray6))
                                        .frame(width: 100, height: 100)
                                    Image(systemName: "photo")
                                        .foregroundStyle(.gray)
                                        .font(.title)
                                }
                            }
                        }
                        .onChange(of: selectedPhoto) { _, newValue in
                            Task {
                                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                    selectedImageData = data
                                    if let uiImage = UIImage(data: data) {
                                        previewImage = uiImage
                                    }
                                }
                            }
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
                
                Section("Depo Adı") {
                    TextField("Örn: Aile Anılarımız", text: $name)
                }
                if let error = localError {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("Yeni Depo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Oluştur") {
                        guard let userId = authViewModel.currentUser?.id else { return }
                        Task {
                            isSubmitting = true
                            localError = nil
                            
                            let newDepoId = UUID().uuidString
                            var coverURL: String? = nil
                            
                            if let imageData = selectedImageData {
                                coverURL = await depoViewModel.uploadCoverImage(depoId: newDepoId, imageData: imageData)
                            }
                            
                            await depoViewModel.createDepo(id: newDepoId, name: name, ownerId: userId, coverImageURL: coverURL)
                            
                            isSubmitting = false
                            if let error = depoViewModel.errorMessage {
                                localError = error
                            } else {
                                dismiss()
                            }
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
                }
            }
        }
    }
}

#Preview {
    CreateDepoSheet(depoViewModel: DepoViewModel())
        .environment(AuthViewModel())
}
