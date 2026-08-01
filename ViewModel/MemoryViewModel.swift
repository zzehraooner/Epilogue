import Foundation
import FirebaseFirestore
import FirebaseStorage
import CoreLocation
import UIKit

@Observable
final class MemoryViewModel {
    var memories: [Memory] = []
    var errorMessage: String?
    var isLoading = false
    var isSaving = false

    var editingMemory: Memory?
    var isEditing: Bool { editingMemory != nil }

    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private var listener: ListenerRegistration?
    private var commentListener: ListenerRegistration?
    var comments: [Comment] = []

    deinit {
        listener?.remove()
        commentListener?.remove()
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    func startListening(depoId: String) {
        listener?.remove()
        isLoading = true
        listener = db.collection("depos").document(depoId)
            .collection("memories")
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }
                self.isLoading = false
                if let error {
                    self.errorMessage = "Anılar yüklenemedi: \(error.localizedDescription)"
                    return
                }
                self.memories = snapshot?.documents.compactMap { document in
                var mem = try? document.data(as: Memory.self)
                mem?.id = document.documentID
                return mem
            } ?? []
            
            // App Group UserDefaults update
            if let latest = self.memories.first {
                if let defaults = UserDefaults(suiteName: "group.com.stash") {
                    let dict: [String: Any] = [
                        "wordOne": latest.wordOne,
                        "wordTwo": latest.wordTwo,
                        "wordThree": latest.wordThree,
                        "date": latest.date.timeIntervalSince1970,
                        "imageURL": latest.imageURL
                    ]
                    defaults.set(dict, forKey: "latestMemory")
                }
            }
        }
    }

    @MainActor
    func addMemory(
        depoId: String, userId: String,
        wordOne: String, wordTwo: String, wordThree: String,
        date: Date, note: String,
        imageData: Data?, videoData: Data?, audioData: Data?,
        locationName: String? = nil, latitude: Double? = nil, longitude: Double? = nil,
        unlockDate: Date? = nil, tags: [String]? = nil,
        previewAudioURL: String? = nil, songName: String? = nil
    ) async {
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }
        
        var finalLat = latitude
        var finalLon = longitude
        
        if let locationName = locationName, !locationName.isEmpty, finalLat == nil {
            if let placemark = try? await CLGeocoder().geocodeAddressString(locationName).first,
               let location = placemark.location {
                finalLat = location.coordinate.latitude
                finalLon = location.coordinate.longitude
            }
        }

        let newId = UUID().uuidString
        var imageURL = ""
        var videoURL: String? = nil
        var audioURL: String? = nil
        
        do {
            if let imageData {
                imageURL = try await uploadMedia(data: imageData, path: "memories/\(depoId)/\(newId).jpg", contentType: "image/jpeg")
            }
            if let videoData {
                videoURL = try await uploadMedia(data: videoData, path: "memories/\(depoId)/\(newId).mp4", contentType: "video/mp4")
            }
            if let audioData {
                audioURL = try await uploadMedia(data: audioData, path: "memories/\(depoId)/\(newId).m4a", contentType: "audio/m4a")
            }

            let memory = Memory(
                id: newId, depoId: depoId,
                imageURL: imageURL,
                wordOne: wordOne, wordTwo: wordTwo, wordThree: wordThree,
                date: date, note: note,
                unlockDate: unlockDate,
                audioURL: audioURL,
                videoURL: videoURL,
                previewAudioURL: previewAudioURL,
                songName: songName,
                locationName: locationName,
                latitude: finalLat,
                longitude: finalLon,
                createdBy: userId,
                createdAt: Date(),
                tags: tags
            )

            try db.collection("depos").document(depoId)
                .collection("memories").document(newId)
                .setData(from: memory)
                
            // Not: Normalde burada tüm depo üyelerine Cloud Functions ile bildirim atılır.

        } catch {
            errorMessage = "Anı eklenemedi: \(error.localizedDescription)"
        }
    }

    @MainActor
    func updateMemory(
        memory: Memory,
        wordOne: String, wordTwo: String, wordThree: String,
        date: Date, note: String,
        imageData: Data?, videoData: Data?, audioData: Data?,
        locationName: String? = nil, latitude: Double? = nil, longitude: Double? = nil,
        unlockDate: Date? = nil, tags: [String]? = nil,
        previewAudioURL: String? = nil, songName: String? = nil
    ) async {
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }
        
        var finalLat = latitude
        var finalLon = longitude
        
        if let locationName = locationName, !locationName.isEmpty, finalLat == nil {
            if let placemark = try? await CLGeocoder().geocodeAddressString(locationName).first,
               let location = placemark.location {
                finalLat = location.coordinate.latitude
                finalLon = location.coordinate.longitude
            }
        }

        do {
            var finalImageURL = memory.imageURL
            var finalVideoURL = memory.videoURL
            var finalAudioURL = memory.audioURL

            if let imageData {
                await deleteFile(url: memory.imageURL)
                finalImageURL = try await uploadMedia(data: imageData, path: "memories/\(memory.depoId)/\(memory.id).jpg", contentType: "image/jpeg")
            }
            if let videoData {
                if let url = memory.videoURL { await deleteFile(url: url) }
                finalVideoURL = try await uploadMedia(data: videoData, path: "memories/\(memory.depoId)/\(memory.id).mp4", contentType: "video/mp4")
            }
            if let audioData {
                if let url = memory.audioURL { await deleteFile(url: url) }
                finalAudioURL = try await uploadMedia(data: audioData, path: "memories/\(memory.depoId)/\(memory.id).m4a", contentType: "audio/m4a")
            }

            var updatedData: [String: Any] = [
                "imageURL": finalImageURL,
                "wordOne": wordOne,
                "wordTwo": wordTwo,
                "wordThree": wordThree,
                "date": Timestamp(date: date),
                "note": note,
                "locationName": locationName as Any,
                "latitude": finalLat as Any,
                "longitude": finalLon as Any,
                "tags": tags as Any,
                "previewAudioURL": previewAudioURL as Any,
                "songName": songName as Any
            ]
            
            if let unlockDate = unlockDate {
                updatedData["unlockDate"] = Timestamp(date: unlockDate)
            } else {
                updatedData["unlockDate"] = FieldValue.delete()
            }
            
            if let v = finalVideoURL { updatedData["videoURL"] = v }
            if let a = finalAudioURL { updatedData["audioURL"] = a }

            try await db.collection("depos").document(memory.depoId)
                .collection("memories").document(memory.id)
                .updateData(updatedData)

            editingMemory = nil
        } catch {
            errorMessage = "Anı güncellenemedi: \(error.localizedDescription)"
        }
    }

    @MainActor
    func deleteMemory(_ memory: Memory) async {
        errorMessage = nil
        do {
            try await db.collection("depos").document(memory.depoId)
                .collection("memories").document(memory.id)
                .delete()
            await deleteFile(url: memory.imageURL)
            if let v = memory.videoURL { await deleteFile(url: v) }
            if let a = memory.audioURL { await deleteFile(url: a) }
        } catch {
            errorMessage = "Anı silinemedi: \(error.localizedDescription)"
        }
    }
    
    // YENİ EKLENEN FAVORİLER VE REAKSİYONLAR
    @MainActor
    func toggleFavorite(memory: Memory, userId: String) async {
        let isFav = memory.favoritedBy?.contains(userId) ?? false
        let ref = db.collection("depos").document(memory.depoId).collection("memories").document(memory.id)
        do {
            try await ref.updateData(["favoritedBy": isFav ? FieldValue.arrayRemove([userId]) : FieldValue.arrayUnion([userId])])
        } catch {
            errorMessage = "Hata: \(error.localizedDescription)"
        }
    }

    @MainActor
    func toggleReaction(memory: Memory, userId: String, emoji: String) async {
        let isReacted = memory.reactions?[emoji]?.contains(userId) ?? false
        let ref = db.collection("depos").document(memory.depoId).collection("memories").document(memory.id)
        do {
            try await ref.updateData(["reactions.\(emoji)": isReacted ? FieldValue.arrayRemove([userId]) : FieldValue.arrayUnion([userId])])
        } catch {
            errorMessage = "Hata: \(error.localizedDescription)"
        }
    }
    

    @MainActor
    func uploadVoiceReaction(memory: Memory, userId: String, fileURL: URL) async {
        do {
            let audioData = try Data(contentsOf: fileURL)
            let path = "memories/\(memory.depoId)/\(memory.id)_voicereaction_\(userId).m4a"
            let uploadedURL = try await uploadMedia(data: audioData, path: path, contentType: "audio/m4a")
            
            let ref = db.collection("depos").document(memory.depoId).collection("memories").document(memory.id)
            try await ref.updateData([
                "voiceReactions.\(userId)": uploadedURL
            ])
            print("Voice Reaction uploaded successfully")
        } catch {
            self.errorMessage = "Voice reaction yüklenirken hata: \(error.localizedDescription)"
        }
    }

    func startEditing(_ memory: Memory) { editingMemory = memory }
    func cancelEditing() { editingMemory = nil }

    private func uploadMedia(data: Data, path: String, contentType: String) async throws -> String {
        let ref = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = contentType
        
        var uploadData = data
        if contentType == "image/jpeg" {
            uploadData = UIImage(data: data)?.jpegData(compressionQuality: 0.7) ?? data
        }

        _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let uploadTask = ref.putData(uploadData, metadata: metadata)
            uploadTask.observe(.success) { _ in continuation.resume(returning: ()) }
            uploadTask.observe(.failure) { snapshot in
                if let error = snapshot.error { continuation.resume(throwing: error) }
                else { continuation.resume(throwing: URLError(.unknown)) }
            }
        }
        return try await ref.downloadURL().absoluteString
    }

    private func deleteFile(url: String) async {
        guard url.contains("firebase") else { return }
        do {
            let ref = Storage.storage().reference(forURL: url)
            try await ref.delete()
        } catch {
            print("Dosya silinemedi: \(error.localizedDescription)")
        }
    }

    func listenForComments(depoId: String, memoryId: String) {
        commentListener?.remove()
        commentListener = db.collection("depos").document(depoId).collection("memories").document(memoryId).collection("comments")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self, let docs = snapshot?.documents else { return }
                self.comments = docs.compactMap { try? $0.data(as: Comment.self) }
            }
    }

    func stopListeningComments() {
        commentListener?.remove()
        commentListener = nil
    }

    func addComment(memory: Memory, userId: String, displayName: String, text: String) async {
        let commentId = UUID().uuidString
        let comment = Comment(id: commentId, memoryId: memory.id, userId: userId, displayName: displayName, text: text, createdAt: Date())
        do {
            try db.collection("depos").document(memory.depoId).collection("memories").document(memory.id).collection("comments").document(commentId).setData(from: comment)
        } catch {
            self.errorMessage = "Yorum eklenemedi: \(error.localizedDescription)"
        }
    }

    func deleteComment(memory: Memory, commentId: String) async {
        do {
            try await db.collection("depos").document(memory.depoId).collection("memories").document(memory.id).collection("comments").document(commentId).delete()
        } catch {
            self.errorMessage = "Yorum silinemedi: \(error.localizedDescription)"
        }
    }

}
