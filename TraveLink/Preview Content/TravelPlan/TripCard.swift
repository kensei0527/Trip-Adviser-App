//
//  TripCard.swift
//  TraveLink
//
//  Created by 古家健成 on 2024/09/12.
//

import SwiftUI
import Firebase

struct TripCard: View {
    let trip: Trip
    let cardColor = Color("Card")
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(trip.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                Text(dateRangeText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.blue)
                Text(durationText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "person.3")
                    .foregroundColor(.blue)
                Text("Participants: \(trip.participants.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(cardColor)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var dateRangeText: String {
        let start = formattedDate(trip.startDate)
        let end = formattedDate(trip.endDate)
        return "\(start) - \(end)"
    }
    
    private var durationText: String {
        let days = Calendar.current.dateComponents([.day], from: trip.startDate, to: trip.endDate).day ?? 0
        return "\(days) day\(days == 1 ? "" : "s")"
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
