//
//  WelcomeModalView.swift
//  TraveLink
//
//  Created by 古家健成 on 2024/09/17.
//

import SwiftUI

extension UserDefaults {
    private enum Keys {
        static let hasSeenWelcomeModal = "hasSeenWelcomeModal"
    }
    
    var hasSeenWelcomeModal: Bool {
        get {
            return bool(forKey: Keys.hasSeenWelcomeModal)
        }
        set {
            set(newValue, forKey: Keys.hasSeenWelcomeModal)
        }
    }
}





struct OnboardingView: View {
    @Binding var isFirstLaunch: Bool
    
    var body: some View {
        
        TabView {
            OnboardingPage(
                imageName: "home_screen",
                title: "Welcome!",
                description: "Welcome to TraveLink! TraveLink allows you to connect with locals in your destination to plan your trip and learn about tips from various travelers"
            )
            OnboardingPage(
                imageName: "profile_screen",
                title: "Profile",
                description: "Enjoy communication with other users. You can manage your information on the profile screen."
            )
            OnboardingPage(
                imageName: "search_screen",
                title: "Search Users",
                description: "Search for users by country and find new connections in your destination."
            )
            OnboardingPage(
                imageName: "itinerary_screen",
                title: "itinerary planning",
                description: "We plan and manage your itinerary and support a fulfilling trip."
            )
            OnboardingPage(
                imageName: "timeline_screen",
                title: "Timeline",
                description: "Check the timeline posted by users for the latest information."
            )
            // 最後のページ
            OnboardingPage(
                imageName: "welcome_screen",
                title: "Let's get started!",
                description: "Experience a new travel experience with TraveLink.",
                action: {
                    isFirstLaunch = false
                }
            )
        }
        .tabViewStyle(PageTabViewStyle())
        .onAppear{
            print("onBoard")
        }
    }
}




struct OnboardingPage: View {
    var imageName: String
    var title: String
    var description: String
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            // 上部のスペースを削除または調整
            // Spacer()
            
            // 画像の表示
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: UIScreen.main.bounds.height * 0.6) // 画面高さの40%
                .padding(.horizontal)
            
            // タイトル
            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // 説明文
            Text(description)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            // 下部のスペーシングを調整
            Spacer()
            
            // 最後のページのみ「はじめる」ボタンを表示
            if let action = action {
                Button(action: action) {
                    Text("Start")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
