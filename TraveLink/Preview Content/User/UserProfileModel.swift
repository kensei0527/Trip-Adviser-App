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
    @Published var averageRating: Double = 0.0
    @Published var posts: [TravelTip] = [] // 追加: ユーザーの投稿を保持
    
    private var db = Firestore.firestore()
    private var chatCreationViewModel = ChatCreationViewModel()
    private var followRequestViewModel = FollowRequestViewModel()
    
    init(user: User) {
        self.user = user
        fetchAverageRating()
        fetchUserIntroduction()
        checkFollowStatus()
        fetchUserPosts() // 追加: ユーザーの投稿を取得
    }
    
    func createAndStartChat() {
        if isFollowing {
            
            chatCreationViewModel.createChat(with: user.email) { newChatId in
                if newChatId != nil {
                    //self.chatId = newChatId
                    //print(self.chatId)
                    //print("followCHeckok")
                }
                //self.chatId = "DAONdZBdRNOGuJjhjzHr"
            }
        } else {
            showingChatAlert = true
            print("followCHeck NO")
        }
    }
    
    func getChatDocumentId(withUser userEmail: String, completion: @escaping (String?) -> Void) {
        guard let currentUserEmail = Auth.auth().currentUser?.email else {
            print("Current user is not logged in")
            completion(nil)
            return
        }
        
        let chatsRef = db.collection("chats")
        
        // 現在のユーザーのメールアドレスを含むチャットを取得
        chatsRef.whereField("participants", arrayContains: currentUserEmail).getDocuments { (snapshot, error) in
            if let error = error {
                print("Error getting chats: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No chats found")
                completion(nil)
                return
            }
            
            // 相手のユーザーのメールアドレスを含むチャットをフィルタリング
            for document in documents {
                let data = document.data()
                if let participants = data["participants"] as? [String],
                   participants.contains(userEmail) {
                    // 条件に一致するチャットのドキュメントIDを返す
                    completion(document.documentID)
                    return
                }
            }
            
            // 条件に一致するチャットがない場合
            completion(nil)
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
    
    func fetchAverageRating() {
        db.collection("users").document(user.email).collection("reviews").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting reviews: \(error)")
                return
            }
            
            guard let documents = querySnapshot?.documents, !documents.isEmpty else {
                self.averageRating = 0.0
                return
            }
            
            let totalRating = documents.compactMap { $0.data()["rating"] as? Double }.reduce(0, +)
            self.averageRating = totalRating / Double(documents.count)
        }
    }
    
    // 追加: ユーザーの投稿を取得するメソッド
    func fetchUserPosts() {
        db.collection("travelTips")
            .whereField("authorId", isEqualTo: user.email) // もしくは user.uid に変更
            .order(by: "createdAt", descending: true)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching user posts: \(error.localizedDescription)")
                    return
                }
                
                if let documents = snapshot?.documents {
                    self?.posts = documents.compactMap { document in
                        let data = document.data()
                        let id = document.documentID
                        let authorId = data["authorId"] as? String ?? ""
                        let tripId = data["tripId"] as? String
                        let categoryString = data["category"] as? String ?? ""
                        let category = TipCategory(rawValue: categoryString) ?? .other
                        let title = data["title"] as? String ?? ""
                        let content = data["content"] as? String ?? ""
                        let images = data["images"] as? [String] ?? []
                        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                        let likes = data["likes"] as? Int ?? 0
                        let likedBy = data["likedBy"] as? [String] ?? []
                        
                        return TravelTip(
                            id: id,
                            authorId: authorId,
                            tripId: tripId,
                            category: category,
                            title: title,
                            content: content,
                            images: images,
                            createdAt: createdAt,
                            likes: likes,
                            likedBy: likedBy
                        )
                    }
                }
            }
    }
}
