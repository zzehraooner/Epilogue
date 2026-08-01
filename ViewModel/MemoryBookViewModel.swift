import Foundation
import UIKit
import SwiftUI
import FirebaseFirestore

@MainActor
@Observable
class MemoryBookViewModel {
    var isLoadingImages = false
    var loadedImages: [String: UIImage] = [:] // memory.id -> UIImage
    var loadingProgress: Double = 0.0
    
    var isPlacingOrder = false
    var orderSuccess = false
    var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    /// Bütün anıların fotoğraflarını indirir (PDF/Ekranda senkron olarak gösterebilmek için).
    func fetchImages(for memories: [Memory]) async {
        isLoadingImages = true
        loadedImages.removeAll()
        loadingProgress = 0.0
        
        // Sadece resmi olan anıları say
        let memoriesWithImages = memories.filter { !$0.imageURL.isEmpty }
        let total = Double(memoriesWithImages.count)
        var completed = 0.0
        
        // Eşzamanlı (Concurrent) indirme işlemi
        await withTaskGroup(of: (String, UIImage?).self) { group in
            for memory in memoriesWithImages {
                if let url = URL(string: memory.imageURL) {
                    group.addTask {
                        do {
                            let (data, _) = try await URLSession.shared.data(from: url)
                            return (memory.id, UIImage(data: data))
                        } catch {
                            return (memory.id, nil)
                        }
                    }
                }
            }
            
            for await (memoryId, image) in group {
                if let image = image {
                    loadedImages[memoryId] = image
                }
                completed += 1.0
                loadingProgress = completed / max(total, 1.0)
            }
        }
        
        isLoadingImages = false
    }
    
    /// iOS 16+ ImageRenderer kullanarak SwiftUI görünümlerinden sayfa sayfa PDF oluşturur.
    func generatePDF(memories: [Memory], depoName: String, template: BookTemplateType) -> URL? {
        let pdfMetaData = [
            kCGPDFContextCreator: "Stash",
            kCGPDFContextAuthor: "Stash User",
            kCGPDFContextTitle: "\(depoName) Anı Kitabı"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        // A5 boyutuna yakın bir kitap boyutu (148 x 210 mm) (x 2.83 for points)
        // Kabaca 420 x 595 points
        let pageWidth = 420.0
        let pageHeight = 595.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let fileName = "\(depoName.replacingOccurrences(of: " ", with: "_"))_Kitap.pdf"
        let url = URL.documentsDirectory.appending(path: fileName)
        
        do {
            try renderer.writePDF(to: url, withActions: { context in
                
                // Kapak Sayfası
                context.beginPage()
                let coverView = CoverPageTemplate(depoName: depoName, memoryCount: memories.count)
                renderSwiftUIView(coverView, in: context.cgContext, size: pageRect.size)
                
                // Anı Sayfaları
                for memory in memories {
                    context.beginPage()
                    let uiImage = loadedImages[memory.id]
                    
                    let pageView = BookPageWrapper(
                        memory: memory,
                        uiImage: uiImage,
                        template: template
                    )
                    renderSwiftUIView(pageView, in: context.cgContext, size: pageRect.size)
                }
                
                // Arka Kapak
                context.beginPage()
                let backCover = BackCoverTemplate()
                renderSwiftUIView(backCover, in: context.cgContext, size: pageRect.size)
            })
            return url
        } catch {
            print("PDF Oluşturulamadı: \(error)")
            return nil
        }
    }
    
    private func renderSwiftUIView<V: View>(_ view: V, in cgContext: CGContext, size: CGSize) {
        let hostingController = UIHostingController(rootView: view)
        hostingController.view.frame = CGRect(origin: .zero, size: size)
        hostingController.view.backgroundColor = .clear
        
        // Görünümü hemen render et
        hostingController.view.layoutIfNeeded()
        hostingController.view.layer.render(in: cgContext)
    }
    
    func placeOrder(order: BookOrder) async {
        isPlacingOrder = true
        errorMessage = nil
        
        // Gerçek bir e-ticaret altyapısında burada Stripe/Apple Pay vb. çağrılır
        // Simülasyon için 2 saniye bekletiyoruz
        do {
            try await Task.sleep(nanoseconds: 2_000_000_000)
            
            // Siparişi Firestore'a kaydet
            try db.collection("orders").document(order.id).setData(from: order)
            orderSuccess = true
            
            // Kullanıcıya siparişin alındığına dair uygulama içi bildirim gönder
            let notifVM = NotificationViewModel()
            notifVM.createSystemNotification(
                userId: order.userId,
                title: "Sipariş Alındı! 📦",
                message: "Anı kitabı siparişiniz (No: \(order.id.prefix(6))) başarıyla üretime alındı."
            )
            
        } catch {
            errorMessage = "Sipariş verilirken bir hata oluştu: \(error.localizedDescription)"
        }
        
        isPlacingOrder = false
    }
}

/// PDF sayfalarını şablona göre sarmalayan yardımcı görünüm
struct BookPageWrapper: View {
    let memory: Memory
    let uiImage: UIImage?
    let template: BookTemplateType
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            
            if template == .polaroid {
                PolaroidPageTemplate(memory: memory, uiImage: uiImage)
            } else {
                MinimalistPageTemplate(memory: memory, uiImage: uiImage)
            }
        }
        .frame(width: 420, height: 595) // A5 boyutu (points)
    }
}
