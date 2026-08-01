//
//  Memory.swift
//  Epilogue
//
//  Created by Zehra Öner on 21.07.2026.
//

import Foundation

/// Firestore'daki depos/{depoId}/memories/{memoryId} dokümanına
/// karşılık gelen model. Her anı bir depoya aittir ve fotoğraf,
/// üç anahtar kelime, tarih ve isteğe bağlı not içerir.
struct Memory: Identifiable, Codable, Hashable {
    var id: String
    var depoId: String
    var imageURL: String          // Firebase Storage indirme URL'si
    var wordOne: String
    var wordTwo: String
    var wordThree: String
    var date: Date
    var note: String
    
    // Faz 8: Zengin Medya ve İçerik
    var unlockDate: Date?         // Zaman kapsülü açılış tarihi
    var audioURL: String?         // Sesli not (Firebase Storage URL)
    var videoURL: String?         // Kısa video (Firebase Storage URL)
    
    // Tema Şarkısı (Müzik)
    var previewAudioURL: String?
    var songName: String?
    
    // Konum Bilgileri (Faz 4)
    var locationName: String?
    var latitude: Double?
    var longitude: Double?
    
    var createdBy: String         // Anıyı ekleyen kullanıcının uid'si
    var createdAt: Date
    var favoritedBy: [String]?
    var reactions: [String: [String]]?
    var voiceReactions: [String: String]? // userId -> Audio URL
    var tags: [String]?
    
    // Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Equatable (Hashable için otomatik olarak id üzerinden karşılaştırma yapması için)
    static func == (lhs: Memory, rhs: Memory) -> Bool {
        return lhs.id == rhs.id
    }

    /// Kelimeleri "Deniz · Rüzgar · Huzur" biçiminde birleştirir.
    /// Boş kelimeleri atlar.
    var wordsDisplay: String {
        [wordOne, wordTwo, wordThree]
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .joined(separator: " · ")
    }
}
