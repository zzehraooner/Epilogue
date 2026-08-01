//
//  ChatViewModel.swift
//  Epilogue
//
//  Created by Zehra Öner on 21.07.2026.
//

import Foundation
import FirebaseFirestore
import Observation

@Observable
class ChatViewModel {
    var messages: [ChatMessage] = []
    var errorMessage: String?
    
    private var db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    
    func startListening(depoId: String) {
        listenerRegistration = db.collection("depos").document(depoId).collection("messages")
            .order(by: "createdAt")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    Task { @MainActor in
                        self.errorMessage = error.localizedDescription
                    }
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                let fetchedMessages = documents.compactMap { doc -> ChatMessage? in
                    try? doc.data(as: ChatMessage.self)
                }
                
                Task { @MainActor in
                    self.messages = fetchedMessages
                }
            }
    }
    
    func stopListening() {
        listenerRegistration?.remove()
        listenerRegistration = nil
    }
    
    func sendMessage(depoId: String, text: String, user: AppUser) {
        let message = ChatMessage(text: text, senderId: user.id, senderName: user.displayName)
        
        do {
            try db.collection("depos").document(depoId).collection("messages").document(message.id).setData(from: message)
        } catch {
            Task { @MainActor in
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
