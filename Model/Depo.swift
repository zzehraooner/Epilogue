//
//  Depo.swift
//  Epilogue
//
//  Created by Zehra Öner on 20.07.2026.
//
import Foundation

/// Firestore'daki depos/{depoId} dokümanına karşılık gelen model.
/// Bir depo, bir veya birden fazla kullanıcının ortak anı biriktirdiği
/// paylaşılan alandır.
struct Depo: Identifiable, Codable {
    var id: String
    var name: String
    var ownerId: String
    var memberIds: [String]
    var inviteCode: String
    var coverImageURL: String?
    var createdAt: Date
}
