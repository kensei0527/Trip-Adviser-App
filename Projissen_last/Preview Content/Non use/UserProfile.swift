//
//  UserProfile.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/06/14.
//
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct UserProfileView: View {
    var user: User
    @StateObject private var chatCreationViewModel = ChatCreationViewModel()
    @State var chatId: String?
    @State var chatFlag = false
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isFollowing = false
    @State private var showingChatAlert = false
    @State var currentUserEmail: String?
    @State private var showingFollowRequestAlert = false
    
    @EnvironmentObject var followRequestViewModel: FollowRequestViewModel
    var db = Firestore.firestore()
    
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
        
        // Check if current user is following the profile user
        followersRef.document(user.email).getDocument { (document, error) in
            if let document = document, document.exists {
                let followers = document.data()?["followers"] as? [String] ?? []
                isFollowing = followers.contains(currentUserEmail)
            }
        }
    }
    
    func toggleFollow() {
        guard let currentUserEmail = Auth.auth().currentUser?.email else { return }
        let followersRef = db.collection("followers").document(user.email)
        
        if isFollowing {
            // Unfollowボタン押した時の動作
            followersRef.updateData([
                "followers": FieldValue.arrayRemove([currentUserEmail])
            ]) { error in
                if error == nil {
                    isFollowing = false
                    //followRequestViewModel.addFollowRequest(user.email)
                }
            }
        } else {
            // Followボタン押した時の動作
            db.collection("followRequests")
                .whereField("fromEmail", isEqualTo: currentUserEmail)
                .whereField("toEmail", isEqualTo: user.email)
                .getDocuments { (querySnapshot, error) in
                    if let error = error {
                        print("Error checking existing requests: \(error.localizedDescription)")
                        return
                    }
                    
                    if let documents = querySnapshot?.documents, !documents.isEmpty {
                        showingFollowRequestAlert = true
                        return
                    }
                    
                    // If no existing request, send a new one
                    followRequestViewModel.addFollowRequest(user.email, currentUserEmail)
                }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("User Name: \(user.name)")
                    .font(.largeTitle)
                    .padding()
                
                Text("Email: \(user.email)")
                    .font(.subheadline)
                    .padding()
                
                Button(action: toggleFollow) {
                    Text(isFollowing ? "Unfollow" : "Follow")
                        .padding()
                        .background(isFollowing ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
                
                Button(action: createAndStartChat) {
                    Text("Create Chat")
                        .padding()
                        .background(isFollowing ? Color.green : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(!isFollowing)
                
                NavigationLink(destination: ChatView(chatId: chatId ?? "")
                    .environmentObject(authViewModel),
                               isActive: Binding(
                                get: { chatId != nil },
                                set: { if !$0 { chatId = nil } }
                               )) {
                                   EmptyView()
                               }
            }
            .navigationTitle("Profile")
            .onAppear {
                checkFollowStatus()
            }
            .alert(isPresented: $showingChatAlert) {
                Alert(
                    title: Text("Cannot Create Chat"),
                    message: Text("You need to follow this user to create a chat."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}
