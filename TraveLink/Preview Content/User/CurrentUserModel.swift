//
//  CurrentUserModel.swift
//  TraveLink
//
//  Created by 古家健成 on 2024/10/06.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import MapKit

class CurrentUserProfileViewModel: ObservableObject {
    @Published var userReviewModel = UserReviewViewModel()
    @Published var tipViewModel = TravelTipViewModel()
    @Published var currentUserEmail: String = ""
    @Published var userLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503)  // Default is Tokyo
    @Published var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503), span: MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 2))
    @Published var countryAddress: String = ""
    @Published var cityAddress: String = ""
    @Published var address: String = ""
    @Published var alertMessage = ""
    @Published var userName: String = ""
    @Published var isLoading: Bool = true
    @Published var inputImage: UIImage?
    @Published var profileImage: Image?
    @Published var introduction: String = ""
    @Published var isEditingIntroduction: Bool = false
    @Published var selectedTip: TravelTip?
    @Published var followers: [User] = []
    @Published var showingAlert = false
    @Published var showingDeleteConfirmation = false
    
    private var db = Firestore.firestore()
    private let storage = Storage.storage().reference()
    
    init() {
        loadUserData()
        fetchUserData()
        fetchFollowers()
    }
    
    func loadImage() {
        guard let inputImage = inputImage else { return }
        profileImage = Image(uiImage: inputImage)
        uploadProfileImage()
    }
    
    func updateUserProfileImageURL(url: String) {
        guard let userEmail = Auth.auth().currentUser?.email else { return }
        
        db.collection("users").document(userEmail).setData(["profileImageURL": url], merge: true) { error in
            if let error = error {
                self.alertMessage = "Error updating profile: \(error.localizedDescription)"
            } else {
                self.alertMessage = "Profile picture updated successfully!"
            }
            self.showingAlert = true
        }
    }
    
    func uploadProfileImage() {
        guard let inputImage = inputImage,
              let imageData = inputImage.jpegData(compressionQuality: 0.5),
              let userEmail = Auth.auth().currentUser?.email else { return }
        
        let imagePath = "profile_images/\(userEmail).jpg"
        let imageRef = storage.child(imagePath)
        
        // Timeout setting: 10 seconds
        let timeoutInterval: TimeInterval = 10
        
        // Set up timeout handling
        let workItem = DispatchWorkItem {
            self.alertMessage = "Request timed out. Please try again."
            self.showingAlert = true
        }
        
        // Schedule the timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + timeoutInterval, execute: workItem)
        
        // Firebase Storage upload request
        imageRef.putData(imageData, metadata: nil) { metadata, error in
            // Cancel the timeout work item
            workItem.cancel()
            
            if let error = error {
                self.alertMessage = "Error uploading image: \(error.localizedDescription)"
                self.showingAlert = true
            } else {
                imageRef.downloadURL { url, error in
                    if let downloadURL = url {
                        self.updateUserProfileImageURL(url: downloadURL.absoluteString)
                    } else if let error = error {
                        self.alertMessage = "Error getting download URL: \(error.localizedDescription)"
                        self.showingAlert = true
                    }
                }
            }
        }
    }
    
    func fetchUserData() {
        guard let user = Auth.auth().currentUser else {
            print("No user is currently logged in")
            isLoading = false
            return
        }
        print("email \(String(describing: user.email))")
        let db = Firestore.firestore()
        db.collection("users").whereField("email", isEqualTo: user.email ?? "")
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error getting documents: \(error)")
                    self.isLoading = false
                    return
                }
                
                guard let document = querySnapshot?.documents.first else {
                    print("No matching document")
                    self.isLoading = false
                    return
                }
                
                if let name = document.data()["name"] as? String {
                    self.userName = name
                }
                if let address = document.data()["location"] as? String {
                    self.address = address
                }
                if let profileImageURL = document.data()["profileImageURL"] as? String {
                    self.loadProfileImage(from: profileImageURL)
                }
                if let intro = document.data()["introduction"] as? String {
                    self.introduction = intro
                }
                
                // All processing is complete, set isLoading to false
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
    }
    
    func saveIntroduction() {
        guard let userEmail = Auth.auth().currentUser?.email else { return }
        
        db.collection("users").document(userEmail).setData(["introduction": introduction], merge: true) { error in
            if let error = error {
                self.alertMessage = "Error saving introduction: \(error.localizedDescription)"
                self.showingAlert = true
            } else {
                self.alertMessage = "Introduction saved successfully!"
                self.showingAlert = true
            }
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
    
    func loadUserData() {
        if let user = Auth.auth().currentUser {
            self.currentUserEmail = user.email ?? "No Email"
            fetchUserLocation()
            userReviewModel.fetchReviews(for: currentUserEmail)
            tipViewModel.fetchUserTips(userEmail: currentUserEmail)
        }
    }
    
    func fetchUserLocation() {
        guard let userEmail = Auth.auth().currentUser?.email else { return }
        
        db.collection("users").document(userEmail).getDocument { document, error in
            if let document = document, document.exists {
                if let latitude = document.data()?["latitude"] as? Double,
                   let longitude = document.data()?["longitude"] as? Double {
                    self.userLocation = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    self.region.center = self.userLocation
                }
                if let savedAddress = document.data()?["address"] as? String {
                    self.address = savedAddress
                }
            }
        }
    }
    
    func updateLocation() {
        address = countryAddress + " " + cityAddress
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, error in
            if let error = error {
                self.alertMessage = "Error: \(error.localizedDescription)"
                self.showingAlert = true
                return
            }
            
            guard let placemark = placemarks?.first,
                  let location = placemark.location else {
                self.alertMessage = "Could not find location for the given address."
                self.showingAlert = true
                return
            }
            
            self.userLocation = location.coordinate
            self.region.center = self.userLocation
            
            self.saveLocationToFirestore(location: location.coordinate)
        }
    }
    
    func saveLocationToFirestore(location: CLLocationCoordinate2D) {
        guard let userEmail = Auth.auth().currentUser?.email else { return }
        
        let userData: [String: Any] = [
            "latitude": location.latitude,
            "longitude": location.longitude,
            "location": address
        ]
        
        db.collection("users").document(userEmail).setData(userData, merge: true) { error in
            if let error = error {
                self.alertMessage = "Error saving location: \(error.localizedDescription)"
            } else {
                self.alertMessage = "Location updated successfully!"
            }
            self.showingAlert = true
        }
    }
    
    func deleteTip(_ tip: TravelTip) {
        selectedTip = tip
        showingDeleteConfirmation = true
    }
    
    func fetchFollowers() {
        guard let userEmail = Auth.auth().currentUser?.email else { return }
        db.collection("followers").document(userEmail).getDocument { [weak self] (document, error) in
            if let error = error {
                print("Error fetching followers: \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists else {
                print("Followers document does not exist for user: \(userEmail)")
                self?.followers = []
                return
            }
            
            let followerEmails = document.data()?["followers"] as? [String] ?? []
            
            guard !followerEmails.isEmpty else {
                self?.followers = []
                return
            }
            
            // Firestore 'in' query limit is 10, so batch if necessary
            let batches = stride(from: 0, to: followerEmails.count, by: 10).map {
                Array(followerEmails[$0..<min($0 + 10, followerEmails.count)])
            }
            
            var fetchedFollowers: [User] = []
            let group = DispatchGroup()
            
            for batch in batches {
                group.enter()
                self?.db.collection("users").whereField(FieldPath.documentID(), in: batch).getDocuments { (querySnapshot, err) in
                    if let err = err {
                        print("Error fetching users: \(err.localizedDescription)")
                        group.leave()
                        return
                    }
                    
                    if let documents = querySnapshot?.documents {
                        for doc in documents {
                            let data = doc.data()
                            let id = doc.documentID
                            let email = doc.documentID
                            let name = data["name"] as? String ?? ""
                            let location = data["location"] as? String ?? ""
                            let profileImageURLString = data["profileImageURL"] as? String
                            let profileImageURL = profileImageURLString != nil ? URL(string: profileImageURLString!) : nil
                            let user = User(id: id, name: name, email: email, location: location, profileImageURL: profileImageURL)
                            fetchedFollowers.append(user)
                        }
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                self?.followers = fetchedFollowers
            }
        }
    }
}
