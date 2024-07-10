//
//  HomeTabScreen.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/06/10.
//

import SwiftUI
import FirebaseAuth

struct HomeTabScreen: View {
    @StateObject var followRequestViewModel = FollowRequestViewModel()
    @StateObject private var countryViewModel = CountryViewModel()
    
    var body: some View {
        NavigationView{
            TabView {
                VStack {
                    
                    NavigationLink(destination: CurrentUserProfileView(), label: {HStack(alignment: .top){
                        Image(systemName: "person").font(.system(size: 30))
                        Text("User name").font(.system(size: 20))
                        Spacer()
                    }})//.frame(alignment: .top)
                    .navigationTitle("tradviser")
                    .padding()
                    
                        // Other UI components
                        
                        

                    Spacer()
                    Text("Your Research")
                        .padding()
                    ScrollView(.horizontal){
                        
                            LazyHStack (spacing: 20){
                                ForEach(countryViewModel.countries, id: \.self) { country in
                                    NavigationLink(destination: NationScreen(countryName: country)) {
                                        CountryCard(countryName: country, width: 200, height: 200)
                                            .cornerRadius(20)
                                            
                                    }
                                    .cornerRadius(20)
                                }
                            }
                            .padding()
                        
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
                                NavigationLink(destination: EmptyView(), label: {HStack{
                                    Image(systemName: "person").font(.system(size: 30))
                                    Text("User name").font(.system(size: 20))
                                }})
                            }
                            .padding()
                        }
                    }
                    
                    //.navigationTitle("TRADVISER")
                }
                .navigationBarTitle("Tradviser")
            }.navigationBarTitle("Tradviser")
        }.navigationBarTitle("Tradviser")
    }
}
#Preview {
    HomeTabScreen()
}
