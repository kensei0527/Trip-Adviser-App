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
    @StateObject private var tripViewModel = TripViewModel()
    @State private var userName: String = "User name"
    @State private var profileImage: Image?
    @State private var isLoading: Bool = true
    @State private var currentUserEmail: String?
    @State private var isProfileImageMissing: Bool = false
    @State private var isLocationMissing: Bool = false
    @State private var userLocation: String?
    
    
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
                    
                    // プロフィール未完成の場合の吹き出し
                    if isProfileImageMissing || isLocationMissing {
                        ProfileCompletionPrompt(isProfileImageMissing: isProfileImageMissing, isLocationMissing: isLocationMissing)
                            .padding(.horizontal)
                    }
                    
                    // Your Research section
                    sectionHeader(title: "Discover new adviser or traveler!")
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
                    sectionHeader(title: "Your Followers ")
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
                    
                    sectionHeader(title: "Your Trips")
                    if tripViewModel.trips.isEmpty {
                        Text("No travel plans yet.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                            .padding(.top, 8)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 15) {
                                ForEach(tripViewModel.trips) { trip in
                                    NavigationLink(destination: TripDetailView(viewModel: tripViewModel, userList: userFetchModel.useredFollowers,trip: trip)) {
                                        TripCard(trip: trip)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .background(Color.gray.opacity(0.1).ignoresSafeArea())
            
        }
        .onAppear {
            fetchUserData()
            userFetchModel.fetchUsers()
            tripViewModel.fetchTrips()
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
        
        db.collection("users").document(user.email ?? "").getDocument { (document, error) in
            if let error = error {
                print("Error getting document: \(error)")
                isLoading = false
                return
            }
            
            guard let document = document, document.exists else {
                print("No matching document")
                isLoading = false
                return
            }
            
            let data = document.data() ?? [:]
            
            if let name = data["name"] as? String {
                self.userName = name
                print(userName)
            }
            
            if let profileImageURL = data["profileImageURL"] as? String, !profileImageURL.isEmpty {
                self.loadProfileImage(from: profileImageURL)
                self.isProfileImageMissing = false
            } else {
                self.isProfileImageMissing = true
            }
            
            if let location = data["location"] as? String, !location.isEmpty {
                self.userLocation = location
                self.isLocationMissing = false
            } else {
                self.isLocationMissing = true
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
