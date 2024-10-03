//
//  ChatViewModel.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/06/11.
//

import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseStorage

struct ChatMessage: Identifiable, Codable {
    @DocumentID var id: String?
    let senderId: String
    let text: String
    let timestamp: Timestamp
    let imageURL: String?
}

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    func sendMessage(chatId: String, senderId: String, text: String, imageURL: String? = nil) {
        let newMessage = ChatMessage(senderId: senderId, text: text, timestamp: Timestamp(), imageURL: imageURL)
        do {
            _ = try db.collection("chats").document(chatId).collection("messages").addDocument(from: newMessage)
            
        } catch let error {
            print("Error sending message: \(error.localizedDescription)")
        }
    }
    
    func fetchMessages(chatId: String) {
        listener = db.collection("chats").document(chatId).collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { querySnapshot, error in
                
                if let error = error {
                    print("Error fetching messages: \(error.localizedDescription)")
                    return
                }
                if(querySnapshot == nil){
                    self.messages = []
                }
                else{
                    self.messages = querySnapshot?.documents.compactMap { document in
                        try? document.data(as: ChatMessage.self)
                    } ?? []
                }
            }
    }
    
    // 画像アップロード機能
    func uploadImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])))
            return
        }
        
        let storageRef = Storage.storage().reference().child("chat_images/\(UUID().uuidString).jpg")
        
        storageRef.putData(imageData, metadata: nil) { (metadata, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            storageRef.downloadURL { (url, error) in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(url.absoluteString))
                }
            }
        }
    }
    
    func stopListening() {
        listener?.remove()
    }
    
    
}
