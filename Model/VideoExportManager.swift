import Foundation
import AVFoundation
import UIKit
import Photos

@Observable
class VideoExportManager {
    var isExporting = false
    var progress: Double = 0.0
    var exportedURL: URL?
    var errorMessage: String?
    
    /// Downloads images from URLs and creates a video slideshow
    func exportSlideshow(memories: [Memory], secondsPerSlide: Double = 4.0) async {
        await MainActor.run {
            isExporting = true
            progress = 0.0
            exportedURL = nil
            errorMessage = nil
        }
        
        // 1. Download all images
        var images: [UIImage] = []
        for (index, memory) in memories.enumerated() {
            guard let url = URL(string: memory.imageURL),
                  let (data, _) = try? await URLSession.shared.data(from: url),
                  let image = UIImage(data: data) else { continue }
            images.append(image)
            await MainActor.run {
                progress = Double(index + 1) / Double(memories.count) * 0.5 // First 50% is downloading
            }
        }
        
        guard !images.isEmpty else {
            await MainActor.run {
                errorMessage = "Görüntü indirilemedi."
                isExporting = false
            }
            return
        }
        
        // 2. Create video
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent("stash_slideshow_\(UUID().uuidString).mp4")
        
        let videoSize = CGSize(width: 1080, height: 1920) // Portrait 9:16
        
        guard let writer = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) else {
            await MainActor.run {
                errorMessage = "Video oluşturucu başlatılamadı."
                isExporting = false
            }
            return
        }
        
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(videoSize.width),
            AVVideoHeightKey: Int(videoSize.height)
        ]
        
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: writerInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
                kCVPixelBufferWidthKey as String: Int(videoSize.width),
                kCVPixelBufferHeightKey as String: Int(videoSize.height)
            ]
        )
        
        writer.add(writerInput)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
        
        let fps: Int32 = 30
        let frameDuration = CMTime(value: 1, timescale: fps)
        let framesPerSlide = Int(secondsPerSlide * Double(fps))
        var frameCount = 0
        
        for (imageIndex, image) in images.enumerated() {
            guard let pixelBuffer = pixelBuffer(from: image, size: videoSize) else { continue }
            
            for _ in 0..<framesPerSlide {
                while !writerInput.isReadyForMoreMediaData {
                    try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
                }
                let presentationTime = CMTimeMultiply(frameDuration, multiplier: Int32(frameCount))
                adaptor.append(pixelBuffer, withPresentationTime: presentationTime)
                frameCount += 1
            }
            
            await MainActor.run {
                progress = 0.5 + (Double(imageIndex + 1) / Double(images.count) * 0.5)
            }
        }
        
        writerInput.markAsFinished()
        await writer.finishWriting()
        
        if writer.status == .completed {
            await MainActor.run {
                exportedURL = outputURL
                progress = 1.0
                isExporting = false
            }
        } else {
            await MainActor.run {
                errorMessage = "Video oluşturulamadı: \(writer.error?.localizedDescription ?? "Bilinmeyen hata")"
                isExporting = false
            }
        }
    }
    
    /// Save to Photo Library
    func saveToPhotoLibrary(url: URL) async -> Bool {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            } completionHandler: { success, error in
                continuation.resume(returning: success)
            }
        }
    }
    
    /// Create a pixel buffer from UIImage
    private func pixelBuffer(from image: UIImage, size: CGSize) -> CVPixelBuffer? {
        let attrs: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height),
                                         kCVPixelFormatType_32ARGB, attrs as CFDictionary, &pixelBuffer)
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        )
        
        if let cgContext = context, let cgImage = image.cgImage {
            // Scale to fill while maintaining aspect ratio
            let imageRect = AVMakeRect(aspectRatio: CGSize(width: cgImage.width, height: cgImage.height), insideRect: CGRect(origin: .zero, size: size))
            cgContext.setFillColor(UIColor.black.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: size))
            cgContext.draw(cgImage, in: imageRect)
        }
        
        CVPixelBufferUnlockBaseAddress(buffer, [])
        return buffer
    }
}
