//
//  DepoSettingsView.swift
//  Epilogue
//
//  Created by Zehra Öner on 21.07.2026.
//

import SwiftUI

struct DepoSettingsView: View {
    let depo: Depo
    let memories: [Memory]
    var depoViewModel: DepoViewModel
    
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var newName: String = ""
    @State private var showingLeaveAlert = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        Form {
            Section("Depo Adı") {
                TextField("Depo Adı", text: $newName)
                if newName.trimmingCharacters(in: .whitespaces) != depo.name && !newName.trimmingCharacters(in: .whitespaces).isEmpty {
                    Button("Kaydet") {
                        Task {
                            await depoViewModel.updateDepoName(depoId: depo.id, newName: newName.trimmingCharacters(in: .whitespaces))
                        }
                    }
                }
            }
            
            Section("Davet Kodu") {
                Text(depo.inviteCode)
                    .font(.system(.body, design: .monospaced))
                
                ShareLink(item: "Stash'te depoma katıl! Davet kodu: \(depo.inviteCode)") {
                    Label("Kodu Paylaş", systemImage: "square.and.arrow.up")
                }
            }
            
            Section("Üyeler") {
                HStack {
                    Image(systemName: "person.2.fill")
                    Text("\(depo.memberIds.count) üye")
                }
            }
            
            Section("Diğer") {
                NavigationLink {
                    StatsView(memories: memories)
                } label: {
                    Label("İstatistikler", systemImage: "chart.bar.xaxis")
                }
                
                NavigationLink {
                    MemoryBookPreviewView(depo: depo, memories: memories)
                } label: {
                    Label("Anı Kitabı Oluştur 📚", systemImage: "book.pages")
                        .font(.headline)
                        .foregroundStyle(.blue)
                }
            }
            
            if let userId = authViewModel.currentUser?.id {
                if depo.ownerId == userId {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Text("Depoyu Sil")
                        }
                        .alert("Depoyu Sil", isPresented: $showingDeleteAlert) {
                            Button("Vazgeç", role: .cancel) { }
                            Button("Sil", role: .destructive) {
                                Task {
                                    await depoViewModel.deleteDepo(depoId: depo.id)
                                    dismiss()
                                }
                            }
                        } message: {
                            Text("Bu depoyu ve içindeki tüm anıları silmek istediğinize emin misiniz? Bu işlem geri alınamaz.")
                        }
                    }
                } else {
                    Section {
                        Button {
                            showingLeaveAlert = true
                        } label: {
                            Text("Depodan Ayrıl")
                                .foregroundStyle(.orange)
                        }
                        .alert("Depodan Ayrıl", isPresented: $showingLeaveAlert) {
                            Button("Vazgeç", role: .cancel) { }
                            Button("Ayrıl", role: .destructive) {
                                Task {
                                    await depoViewModel.leaveDepo(depoId: depo.id, userId: userId)
                                    dismiss()
                                }
                            }
                        } message: {
                            Text("Bu depodan ayrılmak istediğinize emin misiniz?")
                        }
                    }
                }
            }
        }
        .navigationTitle("Depo Ayarları")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            newName = depo.name
        }
    }
}
