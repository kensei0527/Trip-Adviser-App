//
//  CommentViewModel.swift
//  TraveLink
//
//  Created by 古家健成 on 2024/09/16.
//

import SwiftUI
import Firebase

struct Comment: Identifiable {
    let id: String
    var tipId: String
    var authorId: String
    var content: String
    var createdAt: Date
    var authorName: String // ユーザー名を保持
}


class CommentViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    private var db = Firestore.firestore()
    private var cUser = User(id: "", name: "", email: "", location: "", profileImageURL: URL(string: ""))
    
    func fetchComments(for tipId: String) {
        db.collection("travelTips").document(tipId).collection("comments")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("コメントの取得に失敗: \(error?.localizedDescription ?? "不明なエラー")")
                    return
                }
                
                self?.comments = documents.compactMap { document -> Comment? in
                    let data = document.data()
                    let id = document.documentID
                    let authorId = data["authorId"] as? String ?? ""
                    let content = data["content"] as? String ?? ""
                    let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    let authorName = data["authorName"] as? String ?? "Anonymous User"
                    
                    return Comment(id: id, tipId: tipId, authorId: authorId, content: content, createdAt: createdAt, authorName: authorName)
                }
            }
    }
    
    func addComment(to tipId: String, content: String) {
        guard let currentUser = Auth.auth().currentUser else { return }
        let userFetchModel = UserFetchModel()
        
        userFetchModel.fetchUserByEmail(currentUser.email ?? ""){ user in
            self.cUser = user ?? User(id: "", name: "", email: "", location: "")
        }
        let commentRef = db.collection("travelTips").document(tipId).collection("comments").document()
        let data: [String: Any] = [
            "authorId": currentUser.email ?? "",
            "content": content,
            "createdAt": Timestamp(date: Date()),
            "authorName": cUser.name
        ]
        commentRef.setData(data) { error in
            if let error = error {
                print("コメントの追加に失敗: \(error.localizedDescription)")
            }
        }
    }
}
