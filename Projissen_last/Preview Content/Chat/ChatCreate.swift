//
//  ChatCreate.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/06/14.
//
import Firebase
import SwiftUI

class ChatCreate {
    private let db = Firestore.firestore()
    
    func createChat(userIds: Array<String>, completion: @escaping (String?) -> Void) {
        let chatData: [String: Any] = [
            "participants": userIds,
            "createdAt": Timestamp()
        ]
        var ref: DocumentReference? = nil
        ref = db.collection("chats").addDocument(data: chatData) { error in
            if let error = error {
                print("Error creating chat: \(error.localizedDescription)")
                completion(nil)
            } else {
                completion(ref?.documentID)
            }
        }
    }
}



class ChatCreationViewModel: ObservableObject {
    private let chatService = ChatCreate()
    
    func createChat(with otherUserId: String, completion: @escaping (String?) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.email else {
            completion(nil)
            return
        }
        
        chatService.createChat(userIds: [currentUserId, otherUserId]) { chatId in
            completion(chatId)
        }
    }
}

