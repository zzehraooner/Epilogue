import SwiftUI
import MapKit

/// Seçili depodaki konumu (latitude, longitude) olan anıları haritada gösterir.
struct MemoryMapView: View {
    let memories: [Memory]
    let depo: Depo
    let memoryViewModel: MemoryViewModel
    
    // Yalnızca koordinatı olan anıları filtrele
    private var locationMemories: [Memory] {
        memories.filter { $0.latitude != nil && $0.longitude != nil }
    }
    
    // Kamera pozisyonu
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    @State private var selectedMemory: Memory?
    
    var body: some View {
        Map(position: $cameraPosition, selection: $selectedMemory) {
            ForEach(locationMemories) { memory in
                let coord = CLLocationCoordinate2D(
                    latitude: memory.latitude!,
                    longitude: memory.longitude!
                )
                
                Annotation(memory.locationName ?? memory.wordOne, coordinate: coord) {
                    VStack(spacing: 4) {
                        if let url = URL(string: memory.imageURL) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    Color.gray
                                case .success(let image):
                                    image.resizable().scaledToFill()
                                case .failure(_):
                                    Color.red
                                @unknown default:
                                    Color.gray
                                }
                            }
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .shadow(radius: 3)
                        } else {
                            Image(systemName: "photo.circle.fill")
                                .resizable()
                                .frame(width: 44, height: 44)
                                .foregroundColor(.accentColor)
                                .background(Circle().fill(Color.white))
                                .shadow(radius: 3)
                        }
                    }
                    .onTapGesture {
                        selectedMemory = memory
                    }
                }
                .tag(memory)
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .sheet(item: $selectedMemory) { memory in
            NavigationStack {
                MemoryDetailView(memory: memory, viewModel: memoryViewModel, depo: depo)
                    .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium, .large])
        }
        .navigationTitle("Harita")
        .navigationBarTitleDisplayMode(.inline)
    }
}
