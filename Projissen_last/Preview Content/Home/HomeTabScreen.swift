//
//  HomeTabScreen.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/06/10.
//

import SwiftUI

struct HomeTabScreen: View {
    var body: some View {
        NavigationStack{
            TabView {
                VStack {
                    
                    NavigationLink(destination: NationScreen(), label: {HStack(alignment: .top){
                        Image(systemName: "person").font(.system(size: 30))
                        Text("User name").font(.system(size: 20))
                        Spacer()
                    }})//.frame(alignment: .top)
                    .padding()
                    Spacer()
                    Text("Your Research")
                        .padding()
                    ScrollView(.horizontal){
                        HStack(){
                            /*Button(action:
                             {isShowNationView = true},
                             label:
                             {GridRow{
                             RoundedRectangle(cornerSize: .init(width: 20, height: 20))
                             .frame(width: 150, height: 150)
                             }}
                             
                             ).sheet(isPresented: $isShowNationView, content: {
                             NationScreen()
                             })*/
                            //.padding(.horizontal, 10)
                            NavigationLink(destination: NationScreen(), label: {ZStack {
                                
                                GridRow{
                                    RoundedRectangle(cornerSize: .init(width: 20, height: 20))
                                        .frame(width: 150, height: 150)
                                    
                                }.zIndex(1)
                                Text("Country Name").zIndex(2).foregroundColor(.black)
                            }})
                            .padding()
                        }
                    }
                    Text("Your Traveler")
                    ScrollView(.horizontal){
                        HStack(){
                            
                            VStack {
                                NavigationLink(destination: UserListView(), label: {HStack{
                                    Image(systemName: "person").font(.system(size: 30))
                                    Text("User name").font(.system(size: 20))
                                }})
                                .padding()
                                NavigationLink(destination: NationScreen(), label: {HStack{
                                    Image(systemName: "person").font(.system(size: 30))
                                    Text("User name").font(.system(size: 20))
                                }})
                            }
                            .padding()
                        }
                    }
                    /*TabView(selection: $selection,
                     content:  {
                     NationScreen().tabItem { Label("Messege", systemImage: "message.fill") }
                     NationScreen().tabItem { Label("Search", systemImage: "magnifyingglass") }
                     })*/
                    //.navigationTitle("TRADVISER")
                }
                //.navigationTitle("Tradviser")
            }.navigationTitle("Tradviser")
        }
    }
}
#Preview {
    HomeTabScreen()
}
