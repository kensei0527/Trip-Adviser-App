//
//  UserFetch.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/06/14.
//

import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct User: Identifiable{
    var id: String
    var name: String
    var email: String
    var location: String
    var profileImageURL: URL?
    
    /*func hash(into hasher: inout Hasher) {
     hasher.combine(id)  // または email を使用することもできます
     }
     
     static func == (lhs: User, rhs: User) -> Bool {
     lhs.id == rhs.id  // または email を使用することもできます
     }*/
}

class UserFetchModel: ObservableObject {
    @Published var users = [User]()
    @Published var followers: [String] = []
    @Published var useredFollowers: [User] = []
    @Published var blockedUsers: [String] = []
    @Published var errorMessage: String?
    @Published var isLoading = false
    private var db = Firestore.firestore()
    
    /*func fetchUsers() {
        db.collection("users").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
                return
            }
            self.users = querySnapshot?.documents.compactMap { document in
                let data = document.data()
                let id = document.documentID
                let name = data["name"] as? String ?? ""
                let email = data["email"] as? String ?? ""
                let location = data["location"] as? String ?? ""
                let profileImageURLString = data["profileImageURL"] as? String ?? ""
                let profileImageURL = URL(string: profileImageURLString)
                return User(id: id, name: name, email: email, location: location, profileImageURL: profileImageURL)
            } ?? []
        }
    }*/
    
    func fetchUsers() {
        guard let currentUserEmail = Auth.auth().currentUser?.email else { return }
        
        // まずブロックしたユーザーを取得
        fetchBlockedUsers(forUser: currentUserEmail) { [weak self] in
            self?.db.collection("users").getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error getting documents: \(error)")
                    return
                }
                self?.users = querySnapshot?.documents.compactMap { document in
                    let data = document.data()
                    let email = data["email"] as? String ?? ""
                    
                    // ブロックしたユーザーまたは自分自身を除外
                    guard email != currentUserEmail, !(self?.blockedUsers.contains(email) ?? false) else {
                        return nil
                    }
                    
                    let id = document.documentID
                    let name = data["name"] as? String ?? ""
                    let location = data["location"] as? String ?? ""
                    let profileImageURLString = data["profileImageURL"] as? String ?? ""
                    let profileImageURL = URL(string: profileImageURLString)
                    return User(id: id, name: name, email: email, location: location, profileImageURL: profileImageURL)
                } ?? []
            }
        }
    }
    
    func fetchBlockedUsers(forUser email: String, completion: @escaping () -> Void) {
        db.collection("blockedUsers")
            .whereField("blockingUser", isEqualTo: email)
            .getDocuments { [weak self] (querySnapshot, error) in
                if let error = error {
                    print("Error getting blocked users: \(error)")
                    completion()
                    return
                }
                
                self?.blockedUsers = querySnapshot?.documents.compactMap { $0.data()["blockedUser"] as? String } ?? []
                completion()
            }
    }
    
    /*@MainActor
    func fetchFollowUser()async{
        isLoading = true
        errorMessage = nil
        do{
            guard let user = Auth.auth().currentUser else {
                print("No user is currently logged in")
                return
            }
            let docRef = db.collection("followers").document(user.email ?? "")
            let document = try await docRef.getDocument()
            
            if document.exists {
                if let fieldValue = document.get("followers") as? [String] {
                    self.followers = fieldValue
                } else {
                    print("指定されたフィールドは存在しません")
                }
            } else {
                print("ドキュメントが見つかりません")
            }
            
            let usersRef = db.collection("users")
            var fetchedUsers: [User] = []
            for email in followers {
                print(email)
                let querySnapshot = try await db.collection("users").whereField("email", isEqualTo: email).getDocuments()
                    for document in querySnapshot.documents {
                            let data = document.data()
                            let name = data["name"] as? String ?? ""
                            let email = data["email"] as? String ?? ""
                            let location = data["location"] as? String ?? ""
                            let profileImageURLString = data["profileImageURL"] as? String ?? ""
                            let profileImageURL = URL(string: profileImageURLString)
                            let user = User(id: document.documentID,
                                            name: name,
                                            email: email,
                                            location: location,
                                            profileImageURL: profileImageURL)
                            fetchedUsers.append(user)
                            //print(self.useredFollowers)
                        
                    }
                }
            self.useredFollowers = fetchedUsers
            self.isLoading = false
            }
        catch{
            await MainActor.run {
                self.errorMessage = "ユーザー情報の取得に失敗しました: \(error.localizedDescription)"
                self.isLoading = false
            }
        
        }
        
    }*/
    
    @MainActor
    func fetchFollowUser() async {
        isLoading = true
        errorMessage = nil
        do {
            guard let user = Auth.auth().currentUser else {
                print("No user is currently logged in")
                return
            }
            
            // フォロワーを取得
            let docRef = db.collection("followers").document(user.email ?? "")
            let document = try await docRef.getDocument()
            
            if document.exists {
                if let fieldValue = document.get("followers") as? [String] {
                    self.followers = fieldValue
                } else {
                    print("指定されたフィールドは存在しません")
                }
            } else {
                print("ドキュメントが見つかりません")
            }
            
            // ブロックしたユーザーを取得
            await fetchBlockedUsers(forUser: user.email ?? "", completion: {})
            
            // フォロワーのうち、ブロックしていないユーザーだけを取得
            let usersRef = db.collection("users")
            var fetchedUsers: [User] = []
            for email in followers where !blockedUsers.contains(email) {
                let querySnapshot = try await usersRef.whereField("email", isEqualTo: email).getDocuments()
                for document in querySnapshot.documents {
                    let data = document.data()
                    let name = data["name"] as? String ?? ""
                    let email = data["email"] as? String ?? ""
                    let location = data["location"] as? String ?? ""
                    let profileImageURLString = data["profileImageURL"] as? String ?? ""
                    let profileImageURL = URL(string: profileImageURLString)
                    let user = User(id: document.documentID,
                                    name: name,
                                    email: email,
                                    location: location,
                                    profileImageURL: profileImageURL)
                    fetchedUsers.append(user)
                }
            }
            self.useredFollowers = fetchedUsers
            self.isLoading = false
        } catch {
            await MainActor.run {
                self.errorMessage = "ユーザー情報の取得に失敗しました: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func fetchUserByEmail(_ email: String, completion: @escaping (User?) -> Void) {
        let docRef = db.collection("users").document(email)
        docRef.getDocument { (document, error) in
            if let error = error {
                print("Error getting document: \(error)")
                completion(nil)
                return
            }
            
            guard let document = document, document.exists else {
                print("Document does not exist")
                completion(nil)
                return
            }
            
            let data = document.data()
            let id = document.documentID
            let name = data?["name"] as? String ?? ""
            let location = data?["location"] as? String ?? ""
            let profileImageURLString = data?["profileImageURL"] as? String ?? ""
            let profileImageURL = URL(string: profileImageURLString)
            
            let user = User(id: id, name: name, email: email, location: location, profileImageURL: profileImageURL)
            completion(user)
        }
    }
}
