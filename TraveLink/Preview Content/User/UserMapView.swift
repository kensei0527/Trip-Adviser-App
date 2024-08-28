//
//  UserMapView.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/06/27.
//

import SwiftUI
import MapKit

struct UserMapView: View {
    let coordinate: CLLocationCoordinate2D?
    @Environment(\.dismiss) private var dismiss
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.33233141, longitude: -122.03121860),
        span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
    )
    @State private var isCoordinateSet = false
    @State private var mapStyle: MapStyle = .standard
    
    enum MapStyle: String, CaseIterable, Identifiable {
        case standard, satellite, hybrid
        var id: Self { self }
    }
    
    var body: some View {
        ZStack {
            mapView
            VStack {
                topBar
                Spacer()
                if isCoordinateSet {
                    locationInfoCard
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
        .task {
            await setCoordinate()
        }
    }
    
    @ViewBuilder
    private var mapView: some View {
        if isCoordinateSet {
            switch mapStyle {
            case .standard:
                Map(coordinateRegion: .constant(region),
                    interactionModes: [.zoom, .pan],
                    annotationItems: [region.center]) { item in
                    MapMarker(coordinate: item, tint: .red)
                }
            case .satellite:
                Map(coordinateRegion: .constant(region),
                    interactionModes: [.zoom, .pan],
                    annotationItems: [region.center]) { item in
                    MapMarker(coordinate: item, tint: .red)
                }
                .mapStyle(.imagery)
            case .hybrid:
                Map(coordinateRegion: .constant(region),
                    interactionModes: [.zoom, .pan],
                    annotationItems: [region.center]) { item in
                    MapMarker(coordinate: item, tint: .red)
                }
                .mapStyle(.hybrid)
            }
        } else {
            ProgressView()
                .scaleEffect(2)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray.opacity(0.3))
        }
    }
    
    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            Spacer()
            Picker("Map Style", selection: $mapStyle) {
                ForEach(MapStyle.allCases) { style in
                    Text(style.rawValue.capitalized).tag(style)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .background(Color.white.opacity(0.8))
            .cornerRadius(8)
        }
        .padding()
    }
    
    private var locationInfoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Location Details")
                .font(.headline)
                .foregroundStyle(.black)
            Text("Latitude: \(region.center.latitude, specifier: "%.4f")")
                .foregroundStyle(.black)
            Text("Longitude: \(region.center.longitude, specifier: "%.4f")")
                .foregroundStyle(.black)
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(12)
        .shadow(radius: 5)
        .padding()
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    private func setCoordinate() async {
        // シミュレートされた遅延（実際の使用ケースでは削除してください）
        //try? await Task.sleep(nanoseconds: 2 * 1_000_000_000) // 2秒待機
        
        if let coordinate = coordinate {
            await MainActor.run {
                region = MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                )
                isCoordinateSet = true
            }
        }
    }
}

extension CLLocationCoordinate2D: Identifiable {
    public var id: String {
        "\(latitude)-\(longitude)"
    }
}


