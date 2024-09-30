//
//  TipRowView.swift
//  TraveLink
//
//  Created by 古家健成 on 2024/09/17.
//
import SwiftUI

struct UserTipRow: View {
    var tip: TravelTip
    var deleteAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(tip.title)
                .font(.headline)
            Text(tip.content)
                .font(.body)
                .lineLimit(3)
            // 画像の表示（必要に応じて）
            if !tip.images.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(tip.images, id: \.self) { imageUrl in
                            AsyncImage(url: URL(string: imageUrl)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 100, height: 100)
                            .clipped()
                            .cornerRadius(8)
                        }
                    }
                }
            }
            HStack {
                Spacer()
                Button(action: deleteAction) {
                    Text("Delete")
                        .foregroundColor(.red)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}
