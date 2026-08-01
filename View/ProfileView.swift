//
//  ProfileView.swift
//  Epilogue
//
//  Created by Zehra Öner on 21.07.2026.
//

import SwiftUI
import PhotosUI
import FirebaseFirestore
internal import LocalAuthentication

struct ProfileView: View {
    @Environment(AuthViewModel.self) var authViewModel
    @State private var profileViewModel = ProfileViewModel()
    @State private var selectedItem: PhotosPickerItem? = nil
    @AppStorage("isBiometricEnabled") private var isBiometricEnabled = false
    @State private var biometricManager = BiometricManager()
    @State private var showingYearInReview = false
    @State private var yearMemories: [Memory] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        if let user = authViewModel.currentUser {
                            
                            // Profile Photo
                            VStack {
                                PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                                    ZStack(alignment: .bottomTrailing) {
                                        if let profileImage = profileViewModel.profileImage {
                                            Image(uiImage: profileImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 120, height: 120)
                                                .clipShape(Circle())
                                        } else if let urlString = user.profileImageURL, let url = URL(string: urlString) {
                                            AsyncImage(url: url) { image in
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                            } placeholder: {
                                                ProgressView()
                                            }
                                            .frame(width: 120, height: 120)
                                            .clipShape(Circle())
                                        } else {
                                            Image(systemName: "person.circle.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 120, height: 120)
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Image(systemName: "camera.circle.fill")
                                            .resizable()
                                            .frame(width: 32, height: 32)
                                            .foregroundColor(.blue)
                                            .background(Color.white.clipShape(Circle()))
                                            .offset(x: -8, y: -8)
                                    }
                                }
                                .onChange(of: selectedItem) { _, newItem in
                                    Task {
                                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                            if let uiImage = UIImage(data: data) {
                                                profileViewModel.profileImage = uiImage
                                                await profileViewModel.uploadProfilePhoto(userId: user.id, imageData: data)
                                            }
                                        }
                                    }
                                }
                                
                                if user.profileImageURL != nil || profileViewModel.profileImage != nil {
                                    Button(role: .destructive) {
                                        Task {
                                            await profileViewModel.deleteProfilePhoto(userId: user.id, currentURL: user.profileImageURL)
                                            profileViewModel.profileImage = nil
                                            authViewModel.currentUser?.profileImageURL = nil
                                        }
                                    } label: {
                                        Text("Fotoğrafı Kaldır")
                                            .font(.footnote)
                                    }
                                    .padding(.top, 4)
                                }
                            }
                            .padding(.top, 20)
                            
                            // Info Section
                            VStack(spacing: 0) {
                                // Adın
                                VStack(spacing: 0) {
                                    HStack {
                                        Text("Adın")
                                            .frame(width: 100, alignment: .leading)
                                            .foregroundColor(.secondary)
                                        
                                        TextField("Adın", text: $profileViewModel.displayName)
                                        
                                        if profileViewModel.displayName != user.displayName {
                                            Button("Kaydet") {
                                                if profileViewModel.validateName(profileViewModel.displayName) {
                                                    Task {
                                                        await profileViewModel.updateDisplayName(userId: user.id, newName: profileViewModel.displayName)
                                                    }
                                                }
                                            }
                                            .fontWeight(.semibold)
                                        }
                                    }
                                    .padding()
                                    if let error = profileViewModel.nameError {
                                        Text(error).foregroundColor(.red).font(.footnote).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal)
                                    }
                                }
                                
                                Divider()
                                
                                // E-posta
                                HStack {
                                    Text("E-posta")
                                        .frame(width: 100, alignment: .leading)
                                        .foregroundColor(.secondary)
                                    
                                    Text(user.email)
                                        .foregroundColor(.gray)
                                    
                                    Spacer()
                                }
                                .padding()
                                
                                Divider()
                                
                                // Telefon Numarası
                                VStack(spacing: 0) {
                                    HStack {
                                        Text("Telefon")
                                            .frame(width: 100, alignment: .leading)
                                            .foregroundColor(.secondary)
                                        
                                        TextField("Telefon", text: $profileViewModel.phoneNumber)
                                            .keyboardType(.phonePad)
                                            .onChange(of: profileViewModel.phoneNumber) { _, newValue in
                                                profileViewModel.phoneNumber = newValue.filter { $0.isNumber }
                                            }
                                        
                                        if profileViewModel.phoneNumber != (user.phoneNumber ?? "") {
                                            Button("Kaydet") {
                                                Task {
                                                    await profileViewModel.updatePhone(userId: user.id, newPhone: profileViewModel.phoneNumber)
                                                }
                                            }
                                            .fontWeight(.semibold)
                                        }
                                    }
                                    .padding()
                                    if let error = profileViewModel.phoneError {
                                        Text(error).foregroundColor(.red).font(.footnote).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal)
                                    }
                                }
                                
                                Divider()
                                
                                // Adres
                                VStack(spacing: 0) {
                                    HStack {
                                        Text("Adres")
                                            .frame(width: 100, alignment: .leading)
                                            .foregroundColor(.secondary)
                                        
                                        TextField("Adres", text: $profileViewModel.address)
                                        
                                        if profileViewModel.address != (user.address ?? "") {
                                            Button("Kaydet") {
                                                Task {
                                                    await profileViewModel.updateAddress(userId: user.id, newAddress: profileViewModel.address)
                                                }
                                            }
                                            .fontWeight(.semibold)
                                        }
                                    }
                                    .padding()
                                    if let error = profileViewModel.addressError {
                                        Text(error).foregroundColor(.red).font(.footnote).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal)
                                    }
                                }
                                
                                Divider()
                                
                                // Katılma Tarihi
                                HStack {
                                    Text("Katılma Tarihi")
                                        .frame(width: 100, alignment: .leading)
                                        .foregroundColor(.secondary)
                                    
                                    Text(user.createdAt, style: .date)
                                        .foregroundColor(.gray)
                                    
                                    Spacer()
                                }
                                .padding()
                            }
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                            
                            // Tarihte Bugün (Günün Anısı)
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Tarihte Bugün")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Henüz kaydedilmiş yeterli anın yok.")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Text("Biraz daha anı biriktir!")
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                    }
                                    Spacer()
                                    Image(systemName: "calendar.badge.clock")
                                        .font(.largeTitle)
                                        .foregroundColor(.accentColor.opacity(0.5))
                                }
                                .padding()
                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                            .padding(.vertical, 8)
                            
                            // Başarımlar ve Rozetler
                            BadgesView(userBadges: user.badges)
                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            
                            // Ekstralar
                            VStack(spacing: 0) {
                                NavigationLink {
                                    OrdersListView()
                                } label: {
                                    HStack {
                                        Label("Siparişlerim", systemImage: "shippingbox")
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                }
                                
                                if biometricManager.canUseBiometrics {
                                    Divider()
                                    
                                    // Biyometrik Kilit
                                    HStack {
                                        Label(biometricManager.biometricName + " ile Kilitle", systemImage: biometricManager.biometricType == .faceID ? "faceid" : "touchid")
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Toggle("", isOn: $isBiometricEnabled)
                                            .labelsHidden()
                                    }
                                    .padding()
                                }
                                
                                Divider()

                                NavigationLink {
                                    AppIconView()
                                } label: {
                                    HStack {
                                        Label("Uygulama İkonu", systemImage: "app.badge")
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                }
                                
                                Divider()

                                Button {
                                    showingYearInReview = true
                                } label: {
                                    HStack {
                                        Label("2026 Yılın Özeti", systemImage: "sparkles")
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                }
                            }
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                            
                            // Error Message
                            if let error = profileViewModel.errorMessage {
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.footnote)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            
                            // Çıkış Yap
                            Button(role: .destructive) {
                                authViewModel.signOut()
                            } label: {
                                Text("Çıkış Yap")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            .padding(.top, 16)
                            
                        } else {
                            ProgressView("Yükleniyor...")
                        }
                    }
                    .padding(.bottom, 40)
                }
                
                if profileViewModel.isSaving {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView("Kaydediliyor...")
                        .padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(12)
                }
            }
            .navigationTitle("Profilim")
            .onAppear {
                if let user = authViewModel.currentUser {
                    profileViewModel.loadProfile(user: user)
                }
            }
            .onChange(of: authViewModel.currentUser?.id) { _, _ in
                if let user = authViewModel.currentUser {
                    profileViewModel.loadProfile(user: user)
                }
            }
            .fullScreenCover(isPresented: $showingYearInReview) {
                YearInReviewView(memories: yearMemories)
            }
            .onChange(of: showingYearInReview) { _, isShowing in
                if isShowing {
                    Task {
                        await fetchYearMemories()
                    }
                }
            }
        }
    }
    
    private func fetchYearMemories() async {
        guard let userId = authViewModel.currentUser?.id else { return }
        let db = Firestore.firestore()
        let startOfYear = Calendar.current.date(from: Calendar.current.dateComponents([.year], from: .now))!
        do {
            let snapshot = try await db.collectionGroup("memories")
                .whereField("createdBy", isEqualTo: userId)
                .whereField("date", isGreaterThanOrEqualTo: startOfYear)
                .getDocuments()
            yearMemories = snapshot.documents.compactMap { try? $0.data(as: Memory.self) }
        } catch {
            print("Year in Review fetch error: \(error)")
        }
    }
}
