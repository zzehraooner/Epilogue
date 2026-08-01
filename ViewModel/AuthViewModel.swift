//
//  AuthViewModel.swift
//  Epilogue
//
//  Created by Zehra Öner on 20.07.2026.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Uygulamanın kimlik doğrulama durumunu ve işlemlerini yöneten
/// merkezi ViewModel. Uygulama açıldığında Firebase'in mevcut oturumu
/// olup olmadığını dinler; giriş/kayıt/çıkış işlemlerini buradan yapar.
@Observable
final class AuthViewModel {
    var currentUser: AppUser?
    var isLoading = true
    var errorMessage: String?

    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()

    init() {
        listenToAuthState()
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    /// Firebase'in oturum durumu her değiştiğinde (giriş/çıkış/uygulama açılışı)
    /// otomatik tetiklenir. Kullanıcı varsa Firestore'dan profilini çeker.
    private func listenToAuthState() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            guard let self else { return }
            guard let firebaseUser else {
                self.currentUser = nil
                self.isLoading = false
                return
            }
            Task { await self.fetchProfile(uid: firebaseUser.uid) }
        }
    }

    @MainActor
    private func fetchProfile(uid: String) async {
        do {
            let snapshot = try await db.collection("users").document(uid).getDocument()
            if let user = try? snapshot.data(as: AppUser.self) {
                self.currentUser = user
            }
        } catch {
            self.errorMessage = "Profil yüklenemedi: \(error.localizedDescription)"
        }
        self.isLoading = false
    }

    /// Yeni hesap oluşturur: önce Firebase Auth'ta kullanıcıyı yaratır,
    /// sonra Firestore'da profil dokümanını yazar.
    @MainActor
    func signUp(email: String, password: String, displayName: String) async {
        errorMessage = nil
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let newUser = AppUser(
                id: result.user.uid,
                displayName: displayName,
                email: email,
                createdAt: .now
            )
            try db.collection("users").document(result.user.uid).setData(from: newUser)
            self.currentUser = newUser
        } catch {
            errorMessage = mapFirebaseError(error)
        }
    }

    @MainActor
    func signIn(email: String, password: String) async {
        errorMessage = nil
        do {
            _ = try await Auth.auth().signIn(withEmail: email, password: password)
            // currentUser, addStateDidChangeListener tarafından otomatik doldurulacak.
        } catch {
            errorMessage = mapFirebaseError(error)
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            currentUser = nil
        } catch {
            errorMessage = "Çıkış yapılamadı: \(error.localizedDescription)"
        }
    }

    /// Firebase'in İngilizce hata mesajlarını kullanıcıya daha
    /// anlaşılır Türkçe karşılıklarla göstermek için basit bir eşleme.
    private func mapFirebaseError(_ error: Error) -> String {
        let nsError = error as NSError
        switch AuthErrorCode(rawValue: nsError.code) {
        case .emailAlreadyInUse:
            return "Bu e-posta adresi zaten kullanılıyor."
        case .invalidEmail:
            return "Geçersiz e-posta adresi."
        case .weakPassword:
            return "Şifre çok zayıf, en az 6 karakter olmalı."
        case .wrongPassword, .userNotFound:
            return "E-posta veya şifre hatalı."
        default:
            return error.localizedDescription
        }
    }
}
