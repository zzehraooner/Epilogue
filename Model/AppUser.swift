//
//  AppUser.swift
//  Epilogue
//
//  Created by Zehra Öner on 20.07.2026.
//

import Foundation

/// Firestore'daki users/{uid} dokümanına karşılık gelen basit model.
/// Firebase Auth kendi kullanıcı nesnesini tutuyor (uid, email);
/// biz buna ek olarak görünen ad gibi profil bilgilerini
/// Firestore'da ayrıca saklıyoruz.
struct AppUser: Identifiable, Codable {
    var id: String          // Firebase Auth uid ile aynı
    var displayName: String
    var email: String
    var profileImageURL: String?
    var createdAt: Date
    var phoneNumber: String?
    var address: String?
    var badges: [String]?
}
