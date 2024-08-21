//
//  FollowRequestModel2.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/06/27.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import CoreLocation

class UserProfileViewModel: ObservableObject {
    @Published var user: User
    @Published var isFollowing = false
    @Published var showingChatAlert = false
    @Published var showingFollowRequestAlert = false
    @Published var chatId: String?
    @Published var userCoordinate: CLLocationCoordinate2D?
    @Published var userIntroduction: String = ""
    
    private var db = Firestore.firestore()
    private var chatCreationViewModel = ChatCreationViewModel()
    private var followRequestViewModel = FollowRequestViewModel()
    
    init(user: User) {
        self.user = user
    }
    
    func createAndStartChat() {
        if isFollowing {
            chatCreationViewModel.createChat(with: user.email) { newChatId in
                if let newChatId = newChatId {
                    self.chatId = newChatId
                }
            }
        } else {
            showingChatAlert = true
        }
    }
    
    func checkFollowStatus() {
        guard let currentUserEmail = Auth.auth().currentUser?.email else { return }
        let followersRef = db.collection("followers")
        
        followersRef.document(user.email).getDocument { [weak self] (document, error) in
            if let document = document, document.exists {
                let followers = document.data()?["followers"] as? [String] ?? []
                self?.isFollowing = followers.contains(currentUserEmail)
            }
        }
    }
    
    func toggleFollow() {
        guard let currentUserEmail = Auth.auth().currentUser?.email else { return }
        let followersRef = db.collection("followers").document(user.email)
        
        if isFollowing {
            followersRef.updateData([
                "followers": FieldValue.arrayRemove([currentUserEmail])
            ]) { [weak self] error in
                if error == nil {
                    self?.isFollowing = false
                }
            }
        } else {
            db.collection("followRequests")
                .whereField("fromEmail", isEqualTo: currentUserEmail)
                .whereField("toEmail", isEqualTo: user.email)
                .getDocuments { [weak self] (querySnapshot, error) in
                    if let error = error {
                        print("Error checking existing requests: \(error.localizedDescription)")
                        return
                    }
                    
                    if let documents = querySnapshot?.documents, !documents.isEmpty {
                        self?.showingFollowRequestAlert = true
                        return
                    }
                    
                    self?.followRequestViewModel.addFollowRequest(self?.user.email ?? "", currentUserEmail)
                }
        }
    }
    
    func fetchUserIntroduction() {
        db.collection("users").document(user.email).getDocument { [weak self] (document, error) in
            if let error = error {
                print("Error fetching user introduction: \(error.localizedDescription)")
                return
            }
            
            if let document = document, document.exists {
                self?.userIntroduction = document.data()?["introduction"] as? String ?? ""
            }
        }
    }
    
    func fetchUserLocation() {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(user.location) { [weak self] placemarks, error in
            if let error = error {
                print("Geocoding error: \(error.localizedDescription)")
                return
            }
            if let location = placemarks?.first?.location {
                DispatchQueue.main.async {
                    self?.userCoordinate = location.coordinate
                }
            }
        }
    }
}
