//
//  SearchAdviser.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/06/14.
//
import SwiftUI

struct UserListView: View {
    @ObservedObject private var viewModel = UserFetchModel()
    
    var body: some View {
        NavigationView {
            List(viewModel.users) { user in
                NavigationLink(destination: UserProfileView(user: user)) {
                    Text(user.name)
                }
            }
            .navigationTitle("Users")
            .onAppear {
                viewModel.fetchUsers()
            }
        }
    }
}

