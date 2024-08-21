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
    @State private var longitude = 0.0
    @State private var coordinate: CLLocationCoordinate2D?
    
    init(user: User) {
        _viewModel = StateObject(wrappedValue: UserProfileViewModel(user: user))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    profileHeader
                    userInfo
                    introductionSection
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("Profile")
            .background(Color(.systemBackground))
            .onAppear {
                viewModel.checkFollowStatus()
                viewModel.fetchUserIntroduction()
            }
            .sheet(isPresented: $showingMap) {
                UserMapView(coordinate: coordinate)
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
    
    private var profileHeader: some View {
        VStack {
            AsyncImage(url: viewModel.user.profileImageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundColor(.gray)
            }
            .frame(width: 120, height: 120)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 4))
            .shadow(radius: 7)
            
            Text(viewModel.user.name)
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 8)
        }
    }
    
    private var userInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "envelope")
                    .foregroundColor(.blue)
                Text(viewModel.user.email)
            }
            
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
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.red)
                    Text(viewModel.user.location)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var introductionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Introduction")
                .font(.headline)
                .padding(.bottom, 4)
            
            Text(viewModel.userIntroduction.isEmpty ? "No introduction available." : viewModel.userIntroduction)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: viewModel.toggleFollow) {
                Text(viewModel.isFollowing ? "Unfollow" : "Follow")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isFollowing ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            
            Button(action: viewModel.createAndStartChat) {
                Text("Chat")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isFollowing ? Color.green : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
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
    }
}
