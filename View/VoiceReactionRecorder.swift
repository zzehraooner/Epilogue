import SwiftUI
import AVFoundation
import Combine

class VoiceRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {
    var audioRecorder: AVAudioRecorder?
    @Published var isRecording = false
    @Published var recordedURL: URL?
    
    func requestPermission() {
        AVAudioApplication.requestRecordPermission { allowed in
            print("Audio recording allowed: \(allowed)")
        }
    }
    
    func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            let url = URL.documentsDirectory.appendingPathComponent("voice_reaction_\(UUID().uuidString).m4a")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            DispatchQueue.main.async {
                self.isRecording = true
                self.recordedURL = nil
            }
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        DispatchQueue.main.async {
            self.isRecording = false
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            DispatchQueue.main.async {
                self.recordedURL = recorder.url
            }
        }
    }
}

struct VoiceReactionRecorderView: View {
    @StateObject private var recorder = VoiceRecorder()
    var onSave: (URL) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Sesli Tepki")
                .font(.title2.bold())
            
            Button {
                if recorder.isRecording {
                    recorder.stopRecording()
                } else {
                    recorder.startRecording()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(recorder.isRecording ? Color.red : Color.blue)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: recorder.isRecording ? "stop.fill" : "mic.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.white)
                }
            }
            
            if recorder.isRecording {
                Text("Kaydediliyor...")
                    .foregroundStyle(.red)
            } else if let url = recorder.recordedURL {
                Text("Kayıt Tamamlandı")
                    .foregroundStyle(.green)
                
                HStack(spacing: 20) {
                    Button("Sil") {
                        recorder.recordedURL = nil
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    
                    Button("Gönder") {
                        onSave(url)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
        .onAppear {
            recorder.requestPermission()
        }
    }
}
