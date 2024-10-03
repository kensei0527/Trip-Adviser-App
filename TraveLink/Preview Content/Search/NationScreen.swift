//
//  NationScreen.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/06/06.
//

import SwiftUI
import FirebaseAuth

struct NationScreen: View {
    let countryname: String
    @StateObject private var viewModel: NationScreenModel
    
    init(countryName: String) {
        self.countryname = countryName
        self._viewModel = StateObject(wrappedValue: NationScreenModel(countryName: countryName))
    }
    
    var body: some View {
        NavigationView{
            List {
                Text(viewModel.countryName)
                    .font(.headline)
                
                ForEach(Array(viewModel.matchingDocumentIDs.enumerated()), id: \.element) { index, matchUser in
                    if let user = viewModel.users[matchUser] {
                        NavigationLink(destination: UserProfileVieww(user: user)) {
                            HStack {
                                AsyncImage(url: user.profileImageURL) { image in
                                    image.resizable()
                                } placeholder: {
                                    ProgressView()
                                }
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                                
                                VStack(alignment: .leading) {
                                    Text(user.name)
                                        .font(.headline)
                                    Text(user.email)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    } else {
                        ProgressView()
                            .onAppear{
                                viewModel.fetchUsers()
                            }
                    }
                    
                    // 5つごとに広告を挿入
                    if index % 5 == 4 {
                        AdMobBannerView()
                            .frame(width: 100, height: 50)
                    }
                }
            }
            .navigationTitle("Users in \(viewModel.countryName)")
            .navigationSplitViewStyle(.automatic)
            .navigationViewStyle(StackNavigationViewStyle())
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            viewModel.fetchUsers()
            print(viewModel.users)
        }
    }
}
