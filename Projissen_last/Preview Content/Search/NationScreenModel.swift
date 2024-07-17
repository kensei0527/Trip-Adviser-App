//
//  NationScreenView.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/07/02.
//

import FirebaseFirestore

class NationScreenModel: ObservableObject {
    @Published var countryName: String
    private var userFetchModel = UserFetchModel()
    let db = Firestore.firestore()
    @Published var matchingDocumentIDs: [String] = []
    @Published var users: [String: User] = [:]
    
    init(countryName: String) {
        self.countryName = countryName
        pick()
    }
    
    func pick() {
        db.collection("users")
            .getDocuments { [weak self] (querySnapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error getting documents: \(error)")
                } else {
                    self.matchingDocumentIDs = querySnapshot?.documents.compactMap { document in
                        let location = document.data()["location"] as? String ?? ""
                        return location.contains(self.countryName) ? document.documentID : nil
                    } ?? []
                    
                    print("Matching document IDs: \(self.matchingDocumentIDs)")
                    print("countryname: \(self.countryName)")
                }
            }
    }
    
    func fetchUsers() {
        for matchUser in matchingDocumentIDs {
            userFetchModel.fetchUserByEmail(matchUser) { [weak self] user in
                DispatchQueue.main.async {
                    if let user = user {
                        self?.users[matchUser] = user
                    }
                }
            }
        }
    }
}
