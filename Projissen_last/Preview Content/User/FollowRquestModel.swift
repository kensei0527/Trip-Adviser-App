//
//  FollowRquestModel.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/06/24.
//

import SwiftUI
import FirebaseFirestore

class FollowRequestViewModel: ObservableObject {
    @Published var followRequests: [FollowRequest] = []
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    func addFollowRequest(_ targetUserEmail: String, _ currentUserEmail: String) {
        // Check if a request already exists
        db.collection("followRequests")
            .whereField("fromEmail", isEqualTo: currentUserEmail) //データベースから送りあてのメールアドレスとログインユーザのメールアドレスをチェック
            .whereField("toEmail", isEqualTo: targetUserEmail) // 送り先とターゲットのメールアドレスを照合
            .getDocuments { (querySnapshot, error) in 
                if let error = error {
                    print("Error checking existing requests: \(error.localizedDescription)")
                    return
                }
                
                if let documents = querySnapshot?.documents, !documents.isEmpty {
                    print("A follow request already exists")
                    return
                }
                
                // If no existing request, add a new one
        
                let newRequest = FollowRequest(id: UUID().uuidString, fromEmail: currentUserEmail, toEmail: targetUserEmail) //FollowRequest型のものを作成
                let followRequestRef = self.db.collection("followRequests").document()
                followRequestRef.setData([  //データベースにデータ登録
                    "id": newRequest.id,
                    "fromEmail": currentUserEmail,
                    "toEmail": targetUserEmail
                ]) { error in
                    if let error = error {
                        print("Error adding follow request: \(error.localizedDescription)")
                    } else {
                        print("Follow request successfully added")
                    }
            }
        }
    }
    
    func loadFollowRequests(forUser userEmail: String) {
        // 既存のリスナーがあれば削除
        listener?.remove()
        
        print("Loading follow requests for user: \(userEmail)")
        
        listener = db.collection("followRequests") // データベースから被っているフォローリクエストをとってくる
            .whereField("toEmail", isEqualTo: userEmail)
            .addSnapshotListener { [weak self] (querySnapshot, error) in
                guard let self = self else { return }
                if let error = error {
                    print("Error fetching documents: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No documents found")
                    return
                }
                
                print("Found \(documents.count) documents")
                
                self.followRequests = documents.compactMap { queryDocumentSnapshot -> FollowRequest? in //エラーがなければ配列にデータを格納する
                    let data = queryDocumentSnapshot.data()
                    let id = data["id"] as? String ?? ""
                    let fromEmail = data["fromEmail"] as? String ?? ""
                    let toEmail = data["toEmail"] as? String ?? ""
                    print("Request: from \(fromEmail) to \(toEmail)")
                    return FollowRequest(id: id, fromEmail: fromEmail, toEmail: toEmail)
                }
                print("Loaded \(self.followRequests.count) follow requests")
            }
    }
    
    func approveFollowRequest(_ request: FollowRequest) {
        // Remove the request
        db.collection("followRequests").whereField("id", isEqualTo: request.id).getDocuments { (snapshot, error) in //同じリクエストがあれば
            if let error = error {
                print("Error getting documents: \(error)")
                return
            }
            
            for document in snapshot!.documents {
                document.reference.delete() //承認されたフォローリクエストを削除する
            }
        }
        
        // Add to followers
        let followersRef = db.collection("followers").document(request.toEmail) //フォロワーを更新する
        followersRef.setData([
            "followers": FieldValue.arrayUnion([request.fromEmail])
        ], merge: true) { error in
            if let error = error {
                print("Error updating followers: \(error)")
            } else {
                print("Follower successfully added")
            }
        }
        
        // Remove from local array
        //DispatchQueue.main.async {
           // self.followRequests.removeAll { $0.id == request.id }
        //}
    }
    
    deinit {
        listener?.remove()
    }
}

struct FollowRequest: Identifiable, Equatable {
    let id: String
    let fromEmail: String
    let toEmail: String
}
