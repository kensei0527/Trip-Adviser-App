//
//  UserFetch.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/06/14.
//
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct User: Identifiable {
    var id: String
    var name: String
    var email: String
    var location: String
}

class UserFetchModel: ObservableObject {
    @Published var users = [User]()
    private var db = Firestore.firestore()
    
    func fetchUsers() {
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
                return User(id: id, name: name, email: email, location: location)
            } ?? []
        }
    }
}


