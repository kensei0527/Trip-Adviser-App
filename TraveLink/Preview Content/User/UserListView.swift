//
//  SearchAdviser.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/06/14.
//
//

import SwiftUI
import FirebaseAuth

struct UserListView: View {
    @ObservedObject private var viewModel = UserFetchModel()
    @StateObject var followRequestViewModel = FollowRequestViewModel()
    @State private var currentUserEmail: String?
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Search bar
                    SearchBar(text: $searchText)
                        .padding(.horizontal)
                    
                    // Follow requests section
                    if !followRequestViewModel.followRequests.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Follow Requests")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(followRequestViewModel.followRequests) { request in
                                        FollowRequestCard(request: request, onApprove: {
                                            followRequestViewModel.approveFollowRequest(request)
                                        })
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Users list
                    LazyVStack(spacing: 15) {
                        ForEach(filteredUsers) { user in
                            NavigationLink(destination: UserProfileVieww(user: user).environmentObject(followRequestViewModel)) {
                                UserCard(user: user)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Travelers")
            .background(Color.gray.opacity(0.1).ignoresSafeArea())
            .onAppear {
                viewModel.fetchUsers()
                //viewModel.fetchFollowUser()
                self.currentUserEmail = Auth.auth().currentUser?.email
                if let email = self.currentUserEmail {
                    followRequestViewModel.loadFollowRequests(forUser: email)
                }
            }
        }
    }
    
    var filteredUsers: [User] {
        if searchText.isEmpty {
            return viewModel.users.filter { user in
                !viewModel.blockedUsers.contains(user.email)
            }
        } else {
            return viewModel.users.filter { user in
                !viewModel.blockedUsers.contains(user.email) &&
                user.name.lowercased().contains(searchText.lowercased())
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search travelers", text: $text)
                .foregroundColor(.primary)
            if !text.isEmpty {
                Button(action: {
                    self.text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .gray.opacity(0.3), radius: 3)
    }
}

struct FollowRequestCard: View {
    let request: FollowRequest
    let onApprove: () -> Void
    
    var body: some View {
        VStack {
            Image(systemName: "person.crop.circle.badge.plus")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 50)
                .foregroundColor(.blue)
            
            Text(request.fromEmail)
                .font(.caption)
                .lineLimit(1)
            
            Button("Approve") {
                onApprove()
            }
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(15)
        }
        .frame(width: 120)
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct UserCard: View {
    let user: User
    
    var body: some View {
        HStack(spacing: 15) {
            AsyncImage(url: user.profileImageURL) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                    /*Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .foregroundColor(.gray)*/
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                case .failure:
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .foregroundColor(.gray)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 60, height: 60)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(user.name)
                    .font(.headline)
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color("List"))
        .cornerRadius(10)
        .shadow(color: .gray.opacity(0.2), radius: 2)
    }
}
