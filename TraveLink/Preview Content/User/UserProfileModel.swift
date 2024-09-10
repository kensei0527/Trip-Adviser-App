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
                    //print(self.chatId)
                    //print("followCHeckok")
                }
            }
        } else {
            showingChatAlert = true
            print("followCHeck NO")
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
                    
                    // FCMトークンを取得してプッシュ通知を送信
                    self?.sendFollowRequestNotification()
                }
        }
    }
    
    private func sendFollowRequestNotification() {
        db.collection("users").document(user.email).getDocument { [weak self] (document, error) in
            if let error = error {
                print("Error fetching FCM token: \(error.localizedDescription)")
                return
            }
            
            if let document = document, document.exists,
               let fcmToken = document.data()?["fcm"] as? String {
                
                PushNotificationSender.shared.sendPushNotification(
                    to: fcmToken,
                    userId: self?.user.email ?? "",
                    title: "New Follow Request",
                    body: "You Have New Follow Request"
                ) { result in
                    switch result {
                    case .success(let messageId):
                        print("Notification sent successfully with ID: \(messageId)")
                    case .failure(let error):
                        print("Failed to send notification: \(error.localizedDescription)")
                    }
                }
            } else {
                print("FCM token not found for user")
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
    
    func reportUser() {
        guard let currentUserEmail = Auth.auth().currentUser?.email else { return }
        
        let reportData = [
            "reportedUser": user.email,
            "reportingUser": currentUserEmail,
            "timestamp": FieldValue.serverTimestamp()
        ] as [String : Any]
        
        db.collection("reports").addDocument(data: reportData) { error in
            if let error = error {
                print("Error reporting user: \(error.localizedDescription)")
            } else {
                print("User reported successfully")
            }
        }
    }
    
    func blockUser() {
        guard let currentUserEmail = Auth.auth().currentUser?.email else { return }
        
        let blockData = [
            "blockedUser": user.email,
            "blockingUser": currentUserEmail,
            "timestamp": FieldValue.serverTimestamp()
        ] as [String : Any]
        
        db.collection("blockedUsers").addDocument(data: blockData) { error in
            if let error = error {
                print("Error blocking user: \(error.localizedDescription)")
            } else {
                print("User blocked successfully")
            }
        }
    }
}
