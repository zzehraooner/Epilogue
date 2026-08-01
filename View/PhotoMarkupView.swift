import SwiftUI
import PencilKit

struct PhotoMarkupView: View {
    @Environment(\.dismiss) private var dismiss
    
    let originalImage: UIImage
    var onSave: (UIImage) -> Void
    
    @State private var canvasView = PKCanvasView()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image(uiImage: originalImage)
                    .resizable()
                    .scaledToFit()
                    .overlay {
                        CanvasView(canvasView: $canvasView)
                    }
            }
            .navigationTitle("Çizim Yap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Uygula") {
                        let finalImage = generateMarkedUpImage()
                        onSave(finalImage)
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func generateMarkedUpImage() -> UIImage {
        // Create an image that combines the original image and the canvas drawing
        let size = originalImage.size
        let format = UIGraphicsImageRendererFormat()
        format.scale = originalImage.scale
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            // Draw original image
            originalImage.draw(in: CGRect(origin: .zero, size: size))
            
            // Draw the canvas drawing
            // We need to scale the drawing to match the image size based on the view bounds
            // For simplicity in SwiftUI without geometry reader, we assume the drawing covers the aspect fit bounds
            let drawingImage = canvasView.drawing.image(from: canvasView.bounds, scale: originalImage.scale)
            drawingImage.draw(in: CGRect(origin: .zero, size: size))
        }
        
        return image
    }
}

struct CanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.isOpaque = false
        canvasView.backgroundColor = .clear
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = PKInkingTool(.pen, color: .red, width: 15)
        
        // Let's add a tool picker
        if let window = UIApplication.shared.windows.first {
            let toolPicker = PKToolPicker()
            toolPicker.addObserver(canvasView)
            toolPicker.setVisible(true, forFirstResponder: canvasView)
            DispatchQueue.main.async {
                canvasView.becomeFirstResponder()
            }
        }
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
}
