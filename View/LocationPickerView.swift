//
//  LocationPickerView.swift
//  Epilogue
//
//  Created by Zehra Öner on 21.07.2026.
//

import SwiftUI
import MapKit
import CoreLocation

struct LocationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @Binding var locationName: String
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var tempCoordinate: CLLocationCoordinate2D?
    @State private var isGeocoding = false
    
    var body: some View {
        NavigationStack {
            MapReader { proxy in
                Map(position: $cameraPosition) {
                    if let coord = tempCoordinate {
                        Marker("Seçilen Konum", coordinate: coord)
                    }
                }
                .onTapGesture { position in
                    if let coordinate = proxy.convert(position, from: .local) {
                        tempCoordinate = coordinate
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if tempCoordinate == nil {
                    Text("Haritaya dokunarak konum seçin")
                        .font(.subheadline)
                        .padding()
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, 20)
                }
            }
            .navigationTitle("Haritadan Seç")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        confirmSelection()
                    } label: {
                        if isGeocoding {
                            ProgressView().controlSize(.small)
                        } else {
                            Text("Seç")
                        }
                    }
                    .disabled(tempCoordinate == nil || isGeocoding)
                }
            }
            .onAppear {
                if let selectedCoordinate {
                    tempCoordinate = selectedCoordinate
                    cameraPosition = .region(MKCoordinateRegion(center: selectedCoordinate, latitudinalMeters: 5000, longitudinalMeters: 5000))
                }
            }
        }
    }
    
    private func confirmSelection() {
        guard let coord = tempCoordinate else { return }
        selectedCoordinate = coord
        
        isGeocoding = true
        Task {
            if let placemark = try? await CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: coord.latitude, longitude: coord.longitude)).first {
                // Konum ismini güncelle (örneğin şehir veya semt)
                if let name = placemark.name ?? placemark.locality {
                    locationName = name
                }
            }
            isGeocoding = false
            dismiss()
        }
    }
}

