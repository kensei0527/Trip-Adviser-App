//
//  ChatCreate.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/06/14.
//
import Firebase
import SwiftUI

import Firebase

class ChatCreate {
    private let db = Firestore.firestore()
    
    func createChat(userIds: [String], completion: @escaping (String?) -> Void) {
        checkExistingChat(userIds: userIds) { existingChatId in
            if let chatId = existingChatId {
                completion(chatId)
            } else {
                self.createNewChat(userIds: userIds, completion: completion)
            }
        }
    }
    
    private func checkExistingChat(userIds: [String], completion: @escaping (String?) -> Void) {
        db.collection("chats")
            .whereField("participants", arrayContainsAny: userIds)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error checking existing chats: \(error.localizedDescription)")
                    completion(nil)
                } else {
                    for document in querySnapshot!.documents {
                        let participants = document.data()["participants"] as? [String] ?? []
                        if Set(participants) == Set(userIds) {
                            completion(document.documentID)
                            return
                        }
                    }
                    completion(nil)
                }
            }
        
    }
    
    private func createNewChat(userIds: [String], completion: @escaping (String?) -> Void) {
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

