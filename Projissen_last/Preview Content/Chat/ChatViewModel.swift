//
//  ChatViewModel.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/06/11.
//

import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

struct ChatMessage: Identifiable, Codable {
    @DocumentID var id: String?
    let senderId: String
    let text: String
    let timestamp: Timestamp
}

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    func sendMessage(chatId: String, senderId: String, text: String) {
        let newMessage = ChatMessage(senderId: senderId, text: text, timestamp: Timestamp())
        try? db.collection("chats").document(chatId).collection("messages").addDocument(from: newMessage)
    }
    
    func fetchMessages(chatId: String) {
        listener = db.collection("chats").document(chatId).collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Error fetching messages: \(error.localizedDescription)")
                    return
                }
                self.messages = querySnapshot?.documents.compactMap { document in
                    try? document.data(as: ChatMessage.self)
                } ?? []
            }
    }
    
    func stopListening() {
        listener?.remove()
    }
}

