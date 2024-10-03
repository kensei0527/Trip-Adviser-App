//
//  TripCardView.swift
//  TraveLink
//
//  Created by 古家健成 on 2024/09/17.
//
import SwiftUI

struct HomeTripCard: View {
    let trip: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 旅程の画像（必要に応じてカスタマイズ）
            Image("tripPlaceholder") // プレースホルダー画像を使用
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 150, height: 100)
                .clipped()
                .cornerRadius(8)
            
            // 旅程のタイトル
            Text(trip.title)
                .font(.headline)
                .lineLimit(1)
            
            // 旅程の日付
            Text("\(formattedDate(trip.startDate)) - \(formattedDate(trip.endDate))")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(width: 150)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 4)
    }
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}
