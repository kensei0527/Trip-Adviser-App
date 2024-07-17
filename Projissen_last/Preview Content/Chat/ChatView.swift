//
//  ChatView.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/06/11.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ChatView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var chatViewModel = ChatViewModel()
    @StateObject private var userModel = UserFetchModel()
    @State private var messageText = ""
    @State private var scrollProxy: ScrollViewProxy?
    @Environment(\.dismiss) private var dismiss
    let chatId: String
    var userMail = Auth.auth().currentUser?.email
    @State private var db = Firestore.firestore()
    @State private var profileImages: [String: URL] = [:]
    
    func getProfileImage(senderId: String) {
        if profileImages[senderId] == nil {
            let docRef = db.collection("users").document(senderId)
            docRef.getDocument { (document, error) in
                if let document = document, document.exists {
                    if let fieldValue = document.get("profileImageURL") as? String,
                       let imageURL = URL(string: fieldValue) {
                        DispatchQueue.main.async {
                            self.profileImages[senderId] = imageURL
                        }
                    } else {
                        print("指定されたフィールドは存在しません")
                    }
                } else {
                    print("ドキュメントが見つかりません")
                }
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat header
            chatHeader
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(chatViewModel.messages) { message in
                            MessageBubble(message: message, isCurrentUser: message.senderId == userMail, profileImageURL: profileImages[message.senderId])
                                .id(message.id)
                                .onAppear {
                                    getProfileImage(senderId: message.senderId)
                                }
                        }
                    }
                    .padding()
                }
                .onAppear {
                    scrollProxy = proxy
                    scrollToBottom()
                }
                .onChange(of: chatViewModel.messages.count) { _ in
                    scrollToBottom()
                }
            }
            
            // Message input
            messageInputBar
        }
        .navigationBarHidden(true)
        .onAppear {
            chatViewModel.fetchMessages(chatId: chatId)
        }
        .onDisappear {
            chatViewModel.stopListening()
        }
    }
    
    private var chatHeader: some View {
        HStack {
            Button(action: {
                // Handle back action
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            AsyncImage(url: profileImages[chatViewModel.messages.first?.senderId ?? ""]) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.gray)
            }
            
            Text(chatViewModel.messages.first?.senderId ?? "Chat")
                .font(.system(size: 18, weight: .semibold))
            
            Spacer()
            
            Button(action: {
                // Handle video call action
            }) {
                Image(systemName: "video")
                    .font(.system(size: 22))
                    .foregroundColor(.primary)
            }
            
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
    }
    
    private var messageInputBar: some View {
        HStack(spacing: 12) {
            Button(action: {
                // Handle camera action
            }) {
                Image(systemName: "camera")
                    .font(.system(size: 24))
                    .foregroundColor(.primary)
            }
            
            TextField("Message...", text: $messageText)
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(20)
            
            Button(action: sendMessage) {
                Image(systemName: messageText.isEmpty ? "mic" : "paperplane.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private func sendMessage() {
        if !messageText.isEmpty, let senderId = userMail {
            chatViewModel.sendMessage(chatId: chatId, senderId: senderId, text: messageText)
            messageText = ""
        }
    }
    
    private func scrollToBottom() {
        withAnimation {
            scrollProxy?.scrollTo(chatViewModel.messages.last?.id, anchor: .bottom)
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    let isCurrentUser: Bool
    let profileImageURL: URL?
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !isCurrentUser {
                AsyncImage(url: profileImageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 32, height: 32)
                        .foregroundColor(.gray)
                }
            } else {
                Spacer()
            }
            
            Text(message.text)
                .padding(12)
                .background(isCurrentUser ? Color.blue : Color(.systemGray6))
                .foregroundColor(isCurrentUser ? .white : .black)
                .cornerRadius(20)
                .frame(maxWidth: 280, alignment: isCurrentUser ? .trailing : .leading)
        }
    }
}

