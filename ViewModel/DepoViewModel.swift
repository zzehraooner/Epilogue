//
//  DepoViewModel.swift
//  Epilogue
//
//  Created by Zehra Öner on 20.07.2026.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage
import UIKit

/// Kullanıcının üyesi olduğu depoları gerçek zamanlı dinler,
/// yeni depo oluşturma ve davet koduyla katılma işlemlerini yönetir.
@Observable
final class DepoViewModel {
    var depos: [Depo] = []
    var errorMessage: String?
    var isLoading = false

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    deinit {
        listener?.remove()
    }

    /// Verilen kullanıcının üye olduğu tüm depoları gerçek zamanlı dinlemeye başlar.
    /// Herhangi bir üye yeni anı eklediğinde ya da depo bilgisi değiştiğinde
    /// bu liste otomatik güncellenir.
    func startListening(userId: String) {
        listener?.remove()
        isLoading = true
        listener = db.collection("depos")
            .whereField("memberIds", arrayContains: userId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                self.isLoading = false
                if let error {
                    self.errorMessage = "Depolar yüklenemedi: \(error.localizedDescription)"
                    return
                }
                self.depos = snapshot?.documents.compactMap { try? $0.data(as: Depo.self) } ?? []
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    /// Yeni bir depo oluşturur; oluşturan kişi otomatik olarak owner ve ilk üye olur.
    /// 6 haneli rastgele bir davet kodu üretilir.
    @MainActor
    func createDepo(id: String = UUID().uuidString, name: String, ownerId: String, coverImageURL: String? = nil) async {
        errorMessage = nil
        let inviteCode = generateInviteCode()
        let newDepo = Depo(
            id: id,
            name: name,
            ownerId: ownerId,
            memberIds: [ownerId],
            inviteCode: inviteCode,
            coverImageURL: coverImageURL,
            createdAt: .now
        )
        do {
            try db.collection("depos").document(newDepo.id).setData(from: newDepo)
        } catch {
            errorMessage = "Depo oluşturulamadı: \(error.localizedDescription)"
        }
    }

    /// Davet koduyla bir depoya katılır: kodu Firestore'da arar,
    /// bulursa kullanıcıyı memberIds dizisine ekler.
    @MainActor
    func joinDepo(inviteCode: String, userId: String) async {
        errorMessage = nil
        let cleanCode = inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        do {
            let snapshot = try await db.collection("depos")
                .whereField("inviteCode", isEqualTo: cleanCode)
                .getDocuments()

            guard let document = snapshot.documents.first else {
                errorMessage = "Bu davet koduna sahip bir depo bulunamadı."
                return
            }

            try await document.reference.updateData([
                "memberIds": FieldValue.arrayUnion([userId])
            ])
        } catch {
            errorMessage = "Depoya katılınamadı: \(error.localizedDescription)"
        }
    }

    @MainActor
    func updateDepoName(depoId: String, newName: String) async {
        errorMessage = nil
        do {
            try await db.collection("depos").document(depoId).updateData([
                "name": newName
            ])
        } catch {
            errorMessage = "Depo adı güncellenemedi: \(error.localizedDescription)"
        }
    }

    @MainActor
    func leaveDepo(depoId: String, userId: String) async {
        errorMessage = nil
        do {
            try await db.collection("depos").document(depoId).updateData([
                "memberIds": FieldValue.arrayRemove([userId])
            ])
        } catch {
            errorMessage = "Depodan ayrılınamadı: \(error.localizedDescription)"
        }
    }

    @MainActor
    func deleteDepo(depoId: String) async {
        errorMessage = nil
        do {
            let memoriesSnapshot = try await db.collection("depos").document(depoId).collection("memories").getDocuments()
            for document in memoriesSnapshot.documents {
                try await document.reference.delete()
            }
            try await db.collection("depos").document(depoId).delete()
        } catch {
            errorMessage = "Depo silinemedi: \(error.localizedDescription)"
        }
    }

    func uploadCoverImage(depoId: String, imageData: Data) async -> String? {
        let storageRef = Storage.storage().reference().child("depos/\(depoId)/cover.jpg")
        
        guard let uiImage = UIImage(data: imageData),
              let compressedData = uiImage.jpegData(compressionQuality: 0.7) else {
            return nil
        }
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        do {
            _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                let uploadTask = storageRef.putData(compressedData, metadata: metadata)
                uploadTask.observe(.success) { _ in continuation.resume(returning: ()) }
                uploadTask.observe(.failure) { snapshot in
                    if let error = snapshot.error { continuation.resume(throwing: error) }
                    else { continuation.resume(throwing: URLError(.unknown)) }
                }
            }
            let url = try await storageRef.downloadURL()
            return url.absoluteString
        } catch {
            print("Kapak fotoğrafı yükleme hatası: \(error)")
            return nil
        }
    }

    private func generateInviteCode() -> String {
        let letters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // karışabilecek 0/O, 1/I çıkarıldı
        return String((0..<6).map { _ in letters.randomElement()! })
    }
}
