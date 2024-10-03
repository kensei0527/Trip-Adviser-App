//
//  HomeScreen.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/06/05.
//

import SwiftUI

struct HomeScreen: View {
    //@State var isShowNationView = false
    @State var selection = 1
    //@AppStorage("isFirstLaunch") private var isFirstLaunch: Bool = true
    
    var body: some View {
        TabView{
            HomeTabScreen().tabItem { Label("", systemImage: "house") }
                /*.fullScreenCover(isPresented: $isFirstLaunch) {
                    OnboardingView(isFirstLaunch: $isFirstLaunch)
                }*/
            //ChatView(chatId: "chatId1").tabItem { Label("", systemImage: "message.fill") }
            TimelineView().tabItem { Label("", systemImage: "bubble.left.and.bubble.right") }
            UserListView().tabItem { Label("", systemImage: "person.3.fill") }
            CountryView().tabItem { Label("", systemImage: "magnifyingglass") }
            TravelPlanView().tabItem{ Label("", systemImage: "square.and.pencil")}
            
        }
        .navigationViewStyle(.stack)
        .tabViewStyle(.automatic)
        
        
        //.navigationTitle("TRADVISER")
        
        
    }
}


