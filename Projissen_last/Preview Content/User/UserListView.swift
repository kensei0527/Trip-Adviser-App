//
//  SearchAdviser.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/06/14.
//
import SwiftUI
import FirebaseAuth

struct UserListView: View {
    @ObservedObject private var viewModel = UserFetchModel()
    @StateObject var followRequestViewModel = FollowRequestViewModel()
    //@State private var refreshID = UUID()
    @State private var currentUserEmail: String?
    var body: some View {
        NavigationView {
            VStack{
                if followRequestViewModel.followRequests.isEmpty {
                    Text("No follow requests")
                } else {
                    List {
                        ForEach(followRequestViewModel.followRequests) { request in
                            Text("From: \(request.fromEmail)")
                            Button("Approve") {
                                followRequestViewModel.approveFollowRequest(request)
                            }
                        }
                    }
                    
                }
                
                
                List(viewModel.users) { user in
                    NavigationLink(destination: UserProfileVieww(user: user).environmentObject(followRequestViewModel)) {
                        Text(user.name)
                        //Text("Go to UserProfile")
                    }
                }
                .navigationTitle("Users")
                .onAppear {
                    viewModel.fetchUsers()
                    self.currentUserEmail = Auth.auth().currentUser?.email
                    if let email = self.currentUserEmail {
                        followRequestViewModel.loadFollowRequests(forUser: email)
                    }
                }
            }
        }
    }
}

