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
        span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
    )
    
    var body: some View {
        Button("back"){
            dismiss()
        }
        Map(coordinateRegion: $region, annotationItems: coordinate.map { [$0] } ?? []) { item in
            MapMarker(coordinate: item)
        }
        .onAppear {
            if let coordinate = coordinate {
                region = MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
                )
            }
        }
    }
}

extension CLLocationCoordinate2D: Identifiable {
    public var id: String {
        "\(latitude)-\(longitude)"
    }
}
