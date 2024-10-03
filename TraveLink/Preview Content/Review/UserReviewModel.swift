//
//  UserReviewModel.swift
//  TraveLink
//
//  Created by 古家健成 on 2024/09/14.
//

import SwiftUI
import Firebase

struct Review: Identifiable {
    let id: String
    let reviewerId: String
    let rating: Int
    let comment: String
}

class UserReviewViewModel: ObservableObject {
    @Published var reviews: [Review] = []
    private var db = Firestore.firestore()
    @Published var isReviewNeeded: Bool = false
    @Published var isReviewCompleted: Bool = false
    @Published var averageRating: Double = 0.0
    
    
    
    
    func fetchReviews(for userId: String) {
        db.collection("users").document(userId).collection("reviews").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting reviews: \(error)")
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                self.averageRating = 0.0
                self.reviews = []
                return
            }
                
                self.reviews = documents.compactMap { document -> Review? in
                    let data = document.data()
                    guard let reviewerId = data["reviewerId"] as? String,
                          let rating = data["rating"] as? Int,
                          let comment = data["comment"] as? String else {
                        return nil
                    }
                    return Review(id: document.documentID, reviewerId: reviewerId, rating: rating, comment: comment)
                }
                let totalRating = self.reviews.reduce(0) { $0 + $1.rating }
                self.averageRating = Double(totalRating) / Double(self.reviews.count)
            }
    }
    
    func addReview(for userId: String, reviewerId: String, rating: Int, comment: String) {
        let reviewData: [String: Any] = [
            "reviewerId": reviewerId,
            "rating": rating,
            "comment": comment,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        db.collection("users").document(userId).collection("reviews").addDocument(data: reviewData) { error in
            if let error = error {
                print("Error adding review: \(error.localizedDescription)")
            } else {
                print("Review successfully added")
            }
        }
    }
}
