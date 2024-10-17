//
//  ProfileCompletion.swift
//  TraveLink
//
//  Created by 古家健成 on 2024/10/02.
//

import SwiftUI

struct ProfileCompletionPrompt: View {
    var isProfileImageMissing: Bool
    var isLocationMissing: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Let's fill your profile!")
                .font(.headline)
                .padding(.bottom, 5)
            if isProfileImageMissing {
                Text("・Add your profile picture")
            }
            if isLocationMissing {
                Text("・Add your city")
            }
            NavigationLink(destination: CurrentUserProfileView()) {
                Text("Edit profile")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
        .overlay(
            Triangle()
                .fill(Color.white)
                .frame(width: 20, height: 30)
                .rotationEffect(Angle(degrees: 180))
                .offset(y: 5),
            alignment: .topLeading
        )
    }
}


struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY)) // 上部中央
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY)) // 右下
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY)) // 左下
        path.closeSubpath()
        return path
    }
}
