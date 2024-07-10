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
    var body: some View {
        TabView{
            HomeTabScreen().tabItem { Label("", systemImage: "house") }
            //ChatView(chatId: "chatId1").tabItem { Label("", systemImage: "message.fill") }
            UserListView().tabItem { Label("", systemImage: "person.3.fill") }
            CountryView().tabItem { Label("", systemImage: "magnifyingglass") }
        }
        
        
        //.navigationTitle("TRADVISER")
        
        
    }
}


