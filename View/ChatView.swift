//
//  ChatView.swift
//  Epilogue
//
//  Created by Zehra Öner on 21.07.2026.
//

import SwiftUI

struct ChatView: View {
    let depo: Depo
    @State private var chatViewModel = ChatViewModel()
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var messageText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(chatViewModel.messages) { message in
                        MessageBubble(message: message, isCurrentUser: message.senderId == authViewModel.currentUser?.id)
                    }
                }
                .padding()
            }
            .defaultScrollAnchor(.bottom)
            
            Divider()
            
            HStack {
                TextField("Mesaj yaz...", text: $messageText)
                    .textFieldStyle(.roundedBorder)
                
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.title2)
                        .foregroundStyle(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .accentColor)
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .onAppear {
            chatViewModel.startListening(depoId: depo.id)
        }
        .onDisappear {
            chatViewModel.stopListening()
        }
        .navigationTitle("Sohbet")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func sendMessage() {
        guard let user = authViewModel.currentUser else { return }
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        chatViewModel.sendMessage(depoId: depo.id, text: text, user: user)
        messageText = ""
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isCurrentUser {
                Spacer()
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                if !isCurrentUser {
                    Text(message.senderName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                }
                
                Text(message.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(isCurrentUser ? Color.accentColor : Color(.systemGray5))
                    .foregroundStyle(isCurrentUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            
            if !isCurrentUser {
                Spacer()
            }
        }
    }
}
