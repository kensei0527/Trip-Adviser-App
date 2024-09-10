//
//  HomeTabScreen.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/06/10.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

struct HomeTabScreen: View {
    @StateObject var followRequestViewModel = FollowRequestViewModel()
    @StateObject private var countryViewModel = CountryViewModel()
    @StateObject private var userFetchModel = UserFetchModel()
    @State private var userName: String = "User name"
    @State private var profileImage: Image?
    @State private var isLoading: Bool = true
    @State private var currentUserEmail: String?
    
    private var db = Firestore.firestore()
    private let storage = Storage.storage().reference()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Logo and user profile
                    HStack {
                        Image("TripBuddyLogo") // Assume you've added the logo to your asset catalog
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 60)
                            .clipShape(Circle())
                        Text("TraveLink")
                            .font(.title)
                            .fontWeight(.bold)
                        Spacer()
                        NavigationLink(destination: CurrentUserProfileView()) {
                            profileImageView
                        }
                    }
                    .padding()
                    
                    // User greeting
                    Text("Welcome, \(userName)!")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // Your Research section
                    sectionHeader(title: "Your Research")
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 15) {
                            ForEach(countryViewModel.countries, id: \.self) { country in
                                NavigationLink(destination: NationScreen(countryName: country)) {
                                    CountryCard(countryName: country, width: 150, height: 150)
                                        .cornerRadius(15)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Your Traveler section
                    sectionHeader(title: "Your Travelers")
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 15) {
                            ForEach(userFetchModel.users.filter { userFetchModel.followers.contains($0.email) }) { follower in
                                NavigationLink(destination: UserProfileVieww(user: follower).environmentObject(followRequestViewModel)) {
                                    TravelerCard(user: follower)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationBarHidden(true)
            .background(Color.gray.opacity(0.1).ignoresSafeArea())
        }
        .onAppear {
            fetchUserData()
            userFetchModel.fetchUsers()
            //userFetchModel.fetchFollowUser()
            self.currentUserEmail = Auth.auth().currentUser?.email
            
        }
        .task{
            await userFetchModel.fetchFollowUser()
        }
    }
    
    private var profileImageView: some View {
        Group {
            if let profileImage = profileImage {
                profileImage
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private func sectionHeader(title: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
            Spacer()
        }
        .padding(.horizontal)
    }
    
    func fetchUserData() {
        guard let user = Auth.auth().currentUser else {
            print("No user is currently logged in")
            isLoading = false
            return
        }
        
        db.collection("users").whereField("email", isEqualTo: user.email ?? "")
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error getting documents: \(error)")
                    isLoading = false
                    return
                }
                
                guard let document = querySnapshot?.documents.first else {
                    print("No matching document")
                    isLoading = false
                    return
                }
                
                if let name = document.data()["name"] as? String {
                    self.userName = name
                    print(userName)
                }
                if let profileImageURL = document.data()["profileImageURL"] as? String {
                    self.loadProfileImage(from: profileImageURL)
                }
                
                isLoading = false
            }
    }
    
    func loadProfileImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, let uiImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.profileImage = Image(uiImage: uiImage)
                }
            }
        }.resume()
    }
    
    struct TravelerCard: View {
        let user: User
        
        var body: some View {
            VStack {
                AsyncImage(url: user.profileImageURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 70, height: 70)
                            .clipShape(Circle())
                    case .failure:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 70, height: 70)
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 70, height: 70)
                
                Text(user.name)
                    .font(.caption)
                    .lineLimit(1)
            }
            .frame(width: 100)
            .padding()
            .background(Color("List"))
            .cornerRadius(10)
            .shadow(radius: 2)
        }
    }
    
}
