import SwiftUI
import MapKit
import Combine

class LocationSearchViewModel: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var searchQuery = ""
    @Published var completions: [MKLocalSearchCompletion] = []
    
    private var completer: MKLocalSearchCompleter
    private var cancellable: AnyCancellable?
    
    override init() {
        completer = MKLocalSearchCompleter()
        // We want to search for cities, points of interest globally
        completer.resultTypes = [.address, .pointOfInterest]
        super.init()
        completer.delegate = self
        
        cancellable = $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] query in
                guard let self = self else { return }
                if query.isEmpty {
                    self.completions = []
                } else {
                    self.completer.queryFragment = query
                }
            }
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.completions = completer.results
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Location search failed: \(error.localizedDescription)")
    }
    
    func selectLocation(_ completion: MKLocalSearchCompletion) async -> (name: String, coordinate: CLLocationCoordinate2D)? {
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        
        do {
            let response = try await search.start()
            if let mapItem = response.mapItems.first {
                // Return formatted name like "İzmir, Türkiye"
                let name = completion.title + (completion.subtitle.isEmpty ? "" : ", \(completion.subtitle)")
                return (name: name, coordinate: mapItem.placemark.coordinate)
            }
        } catch {
            print("Failed to get coordinate: \(error.localizedDescription)")
        }
        return nil
    }
}

struct LocationSearchView: View {
    @StateObject private var viewModel = LocationSearchViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var onSelect: (String, CLLocationCoordinate2D) -> Void
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.completions, id: \.self) { completion in
                    Button {
                        Task {
                            if let result = await viewModel.selectLocation(completion) {
                                onSelect(result.name, result.coordinate)
                                dismiss()
                            }
                        }
                    } label: {
                        VStack(alignment: .leading) {
                            Text(completion.title)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            if !completion.subtitle.isEmpty {
                                Text(completion.subtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $viewModel.searchQuery, prompt: "Şehir veya mekan ara (Örn: İzmir)")
            .navigationTitle("Konum Ara")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
            }
        }
    }
}
