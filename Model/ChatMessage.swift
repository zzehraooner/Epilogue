//
//  ChatMessage.swift
//  Epilogue
//
//  Created by Zehra Öner on 21.07.2026.
//

import Foundation
import FirebaseFirestore

struct ChatMessage: Identifiable, Codable {
    var id: String = UUID().uuidString
    var text: String
    var senderId: String
    var senderName: String
    var createdAt: Date = .now
}
