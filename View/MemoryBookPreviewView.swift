import SwiftUI

struct MemoryBookPreviewView: View {
    let depo: Depo
    let memories: [Memory]
    
    @State private var viewModel = MemoryBookViewModel()
    @State private var selectedTemplate: BookTemplateType = .polaroid
    @State private var showingCheckout = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Şablon Seçici
                Picker("Şablon", selection: $selectedTemplate) {
                    ForEach(BookTemplateType.allCases, id: \.self) { template in
                        Text(template.rawValue).tag(template)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .disabled(viewModel.isLoadingImages)
                
                if viewModel.isLoadingImages {
                    VStack(spacing: 16) {
                        Spacer()
                        ProgressView(value: viewModel.loadingProgress)
                            .progressViewStyle(.circular)
                            .scaleEffect(1.5)
                        Text("Fotoğraflar kitaba hazırlanıyor...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("%\(Int(viewModel.loadingProgress * 100))")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Spacer()
                    }
                } else if memories.isEmpty {
                    VStack {
                        Spacer()
                        Text("Bu depoda henüz hiç anı yok.")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                } else {
                    // Kitap Önizleme (Sayfalar)
                    TabView {
                        // Kapak
                        GeometryReader { geo in
                            CoverPageTemplate(depoName: depo.name, memoryCount: memories.count)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .shadow(radius: 5)
                                .padding()
                        }
                        
                        // İç Sayfalar
                        ForEach(memories) { memory in
                            GeometryReader { geo in
                                BookPageWrapper(
                                    memory: memory,
                                    uiImage: viewModel.loadedImages[memory.id],
                                    template: selectedTemplate
                                )
                                // Ölçeklendir (Çünkü Wrapper 420x595 sabit boyutta)
                                .scaleEffect(min(geo.size.width / 420.0, geo.size.height / 595.0))
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .shadow(radius: 5)
                                .padding()
                            }
                        }
                        
                        // Arka Kapak
                        GeometryReader { geo in
                            BackCoverTemplate()
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .shadow(radius: 5)
                                .padding()
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                    
                    // Alt Butonlar
                    VStack(spacing: 12) {
                        Button {
                            if let url = viewModel.generatePDF(memories: memories, depoName: depo.name, template: selectedTemplate) {
                                let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                   let window = windowScene.windows.first,
                                   let rootVC = window.rootViewController {
                                    rootVC.present(activityVC, animated: true)
                                }
                            }
                        } label: {
                            Label("Ücretsiz PDF İndir", systemImage: "square.and.arrow.down")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .foregroundStyle(.primary)
                                .cornerRadius(12)
                        }
                        
                        Button {
                            showingCheckout = true
                        } label: {
                            Label("Fiziksel Kitap Siparişi", systemImage: "book.closed")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Anı Kitabı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
            .onAppear {
                Task {
                    if viewModel.loadedImages.isEmpty {
                        await viewModel.fetchImages(for: memories)
                    }
                }
            }
            .navigationDestination(isPresented: $showingCheckout) {
                BookOrderCheckoutView(depo: depo, memories: memories, template: selectedTemplate, viewModel: viewModel)
            }
        }
    }
}
