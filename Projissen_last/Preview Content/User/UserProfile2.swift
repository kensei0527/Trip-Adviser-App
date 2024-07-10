//
//  UserProfile2.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/06/27.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import MapKit

struct UserProfileVieww: View {
    @StateObject private var viewModel: UserProfileViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingMap = false
    @State private var db = Firestore.firestore()
    @State private var latitude = 0.0
    @State private var longitude  = 0.0
    @State private var coordinate: CLLocationCoordinate2D?
    
    init(user: User) {
        _viewModel = StateObject(wrappedValue: UserProfileViewModel(user: user))
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("User Name: \(viewModel.user.name)")
                    .font(.largeTitle)
                    .padding()
                
                Text("Email: \(viewModel.user.email)")
                    .font(.subheadline)
                    .padding()
                
                Button(action: {
                    showingMap = true
                    db.collection("users").document(viewModel.user.email).getDocument { (document, error) in
                        if let error = error {
                            print("Error fetching user document: \(error.localizedDescription)")
                            return
                        }
                        latitude = document?.data()?["latitude"] as! Double
                        longitude = document?.data()?["longitude"] as! Double
                        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    }
                    
                }) {
                    Text("Location: \(viewModel.user.location)")
                        .padding()
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(8)
                }
                .sheet(isPresented: $showingMap) {
                    UserMapView(coordinate: coordinate)
                }
                
                Button(action: viewModel.toggleFollow) {
                    Text(viewModel.isFollowing ? "Unfollow" : "Follow")
                        .padding()
                        .background(viewModel.isFollowing ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
                
                Button(action: viewModel.createAndStartChat) {
                    Text("Create Chat")
                        .padding()
                        .background(viewModel.isFollowing ? Color.green : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(!viewModel.isFollowing)
                
                NavigationLink(destination: ChatView(chatId: viewModel.chatId ?? "")
                    .environmentObject(authViewModel),
                               isActive: Binding(
                                get: { viewModel.chatId != nil },
                                set: { if !$0 { viewModel.chatId = nil } }
                               )) {
                                   EmptyView()
                               }
            }
            .navigationTitle("Profile")
            .onAppear {
                viewModel.checkFollowStatus()
            }
            .alert(isPresented: $viewModel.showingChatAlert) {
                Alert(
                    title: Text("Cannot Create Chat"),
                    message: Text("You need to follow this user to create a chat."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert(isPresented: $viewModel.showingFollowRequestAlert) {
                Alert(
                    title: Text("Follow Request"),
                    message: Text("You have already sent a follow request to this user."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}
