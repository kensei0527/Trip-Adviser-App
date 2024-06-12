//
//  HomeScreen.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/06/05.
//

import SwiftUI

struct HomeScreen: View {
    @State var isShowNationView = false
    @State var selection = 1
    var body: some View {
        TabView(selection: $selection,
                content:  {
            HomeTabScreen().tabItem { Label("", systemImage: "house") }
            
        })
        
        
        //.navigationTitle("TRADVISER")
        
        
    }
}

#Preview {
    HomeScreen()
}
