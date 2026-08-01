//
//  ProfileViewModel.swift
//  Epilogue
//
//  Created by Zehra Öner on 21.07.2026.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage
import UIKit

@Observable
class ProfileViewModel {
    var displayName: String = ""
    var profileImage: UIImage? = nil
    var isLoading: Bool = false
    var isSaving: Bool = false
    var errorMessage: String? = nil
    var phoneNumber: String = ""
    var address: String = ""
    var phoneError: String? = nil
    var addressError: String? = nil
    var nameError: String? = nil
    
    func loadProfile(user: AppUser) {
        self.displayName = user.displayName
        self.profileImage = nil
        self.phoneNumber = user.phoneNumber ?? ""
        self.address = user.address ?? ""
    }
    
    func updateDisplayName(userId: String, newName: String) async {
        isSaving = true
        errorMessage = nil
        do {
            let db = Firestore.firestore()
            try await db.collection("users").document(userId).updateData([
                "displayName": newName
            ])
            self.displayName = newName
        } catch {
            self.errorMessage = "İsim güncellenemedi: \(error.localizedDescription)"
        }
        isSaving = false
    }
    
    func validatePhone(_ phone: String) -> Bool {
        let digits = phone.filter { $0.isNumber }
        if digits.count < 10 || digits.count > 11 {
            phoneError = "Telefon numarası 10 veya 11 haneli olmalıdır."
            return false
        }
        phoneError = nil
        return true
    }
    
    func validateName(_ name: String) -> Bool {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 {
            nameError = "Ad en az 2 karakter olmalıdır."
            return false
        }
        nameError = nil
        return true
    }
    
    func updatePhone(userId: String, newPhone: String) async {
        guard validatePhone(newPhone) else { return }
        isSaving = true
        errorMessage = nil
        do {
            let db = Firestore.firestore()
            try await db.collection("users").document(userId).updateData([
                "phoneNumber": newPhone
            ])
            self.phoneNumber = newPhone
        } catch {
            self.errorMessage = "Telefon güncellenemedi: \(error.localizedDescription)"
        }
        isSaving = false
    }
    
    func updateAddress(userId: String, newAddress: String) async {
        if newAddress.trimmingCharacters(in: .whitespacesAndNewlines).count < 10 {
            addressError = "Adres en az 10 karakter olmalıdır."
            return
        }
        addressError = nil
        isSaving = true
        errorMessage = nil
        do {
            let db = Firestore.firestore()
            try await db.collection("users").document(userId).updateData([
                "address": newAddress
            ])
            self.address = newAddress
        } catch {
            self.errorMessage = "Adres güncellenemedi: \(error.localizedDescription)"
        }
        isSaving = false
    }
    
    func uploadProfilePhoto(userId: String, imageData: Data) async {
        isSaving = true
        errorMessage = nil
        do {
            guard let image = UIImage(data: imageData),
                  let compressedData = image.jpegData(compressionQuality: 0.7) else {
                throw URLError(.cannotDecodeRawData)
            }
            
            let storageRef = Storage.storage().reference().child("profiles/\(userId).jpg")
            
            // Upload data
            _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<StorageMetadata, Error>) in
                storageRef.putData(compressedData, metadata: nil) { resultMetadata, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let resultMetadata = resultMetadata {
                        continuation.resume(returning: resultMetadata)
                    } else {
                        continuation.resume(throwing: URLError(.unknown))
                    }
                }
            }
            
            // Get URL with retry
            var url: URL?
            for _ in 0..<5 {
                if let fetched = try? await storageRef.downloadURL() {
                    url = fetched
                    break
                }
                try await Task.sleep(nanoseconds: 1_000_000_000)
            }
            guard let finalURL = url else {
                let failURL = try await storageRef.downloadURL()
                let db = Firestore.firestore()
                try await db.collection("users").document(userId).updateData([
                    "profileImageURL": failURL.absoluteString
                ])
                return
            }
            
            // Update Firestore
            let db = Firestore.firestore()
            try await db.collection("users").document(userId).updateData([
                "profileImageURL": finalURL.absoluteString
            ])
            
        } catch {
            self.errorMessage = "Fotoğraf yüklenemedi: \(error.localizedDescription)"
        }
        isSaving = false
    }
    
    func deleteProfilePhoto(userId: String, currentURL: String?) async {
        guard let currentURL = currentURL, !currentURL.isEmpty else { return }
        isSaving = true
        errorMessage = nil
        do {
            let storageRef = Storage.storage().reference(forURL: currentURL)
            try await storageRef.delete()
            
            let db = Firestore.firestore()
            try await db.collection("users").document(userId).updateData([
                "profileImageURL": FieldValue.delete()
            ])
        } catch {
            self.errorMessage = "Fotoğraf silinemedi: \(error.localizedDescription)"
        }
        isSaving = false
    }
}
