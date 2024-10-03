//
//  TravelTipViewModel.swift
//  TraveLink
//
//  Created by 古家健成 on 2024/09/16.
//

import SwiftUI
import Firebase
import PhotosUI

struct TravelTip: Identifiable {
    let id: String
    var authorId: String
    var tripId: String?
    var category: TipCategory
    var title: String
    var content: String
    var images: [String]
    var createdAt: Date
    var likes: Int
    var likedBy: [String] // 追加: いいねしたユーザーのIDリスト
}



struct MultiImagePicker: UIViewControllerRepresentable {
    @Binding var images: [UIImage]
    
    func makeUIViewController(context: Context) -> some UIViewController {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 0 // 0 means no limit
        configuration.filter = .images // We only want images
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // No update needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: MultiImagePicker
        
        init(_ parent: MultiImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                        if let uiImage = image as? UIImage {
                            DispatchQueue.main.async {
                                self?.parent.images.append(uiImage)
                            }
                        } else {
                            print("Failed to load image: \(error?.localizedDescription ?? "Unknown error")")
                        }
                    }
                }
            }
        }
    }
}


enum TipCategory: String, CaseIterable {
    case tripIntroduction = "Trip Introduction"
    case accommodation = "Accommodation"
    case diningAndRestaurants = "Dining & Restaurants"
    case activitiesAndEvents = "Activities & Events"
    case transportation = "Transportation"
    case localInfo = "Local Information"
    case other = "Other"
}

class TravelTipViewModel: ObservableObject {
    @Published var tips: [TravelTip] = []
    
    private var db = Firestore.firestore()
    private var lastDocument: DocumentSnapshot?
    @Published var isFetching: Bool = false // データ取得中かどうかを示すフラグ
    @Published var hasMoreData: Bool = true // これ以上データがあるかどうか
    
    
    func fetchTips(for trip: Trip? = nil) {
        var query: Query = db.collection("travelTips")
        
        if let trip = trip {
            query = query.whereField("tripId", isEqualTo: trip.id)
        }
        
        query.addSnapshotListener { [weak self] querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("Error fetching tips: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            self?.tips = documents.compactMap { document -> TravelTip? in
                let data = document.data()
                let id = document.documentID
                let authorId = data["authorId"] as? String ?? ""
                let tripId = data["tripId"] as? String
                let category = TipCategory(rawValue: data["category"] as? String ?? "") ?? .other
                let title = data["title"] as? String ?? ""
                let content = data["content"] as? String ?? ""
                let images = data["images"] as? [String] ?? []
                let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                let likes = data["likes"] as? Int ?? 0
                let likedBy = data["likedBy"] as? [String] ?? []
                
                return TravelTip(id: id, authorId: authorId, tripId: tripId, category: category, title: title, content: content, images: images, createdAt: createdAt, likes: likes, likedBy: likedBy)
            }
        }
    }
    
    func fetchAllTips() {
        db.collection("travelTips")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching tips: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                self?.tips = documents.compactMap { document -> TravelTip? in
                    let data = document.data()
                    let id = document.documentID
                    let authorId = data["authorId"] as? String ?? ""
                    let tripId = data["tripId"] as? String
                    let category = TipCategory(rawValue: data["category"] as? String ?? "") ?? .other
                    let title = data["title"] as? String ?? ""
                    let content = data["content"] as? String ?? ""
                    let images = data["images"] as? [String] ?? []
                    let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    let likes = data["likes"] as? Int ?? 0
                    let likedBy = data["likedBy"] as? [String] ?? []
                    
                    return TravelTip(id: id, authorId: authorId, tripId: tripId, category: category, title: title, content: content, images: images, createdAt: createdAt, likes: likes, likedBy: likedBy)
                }
            }
    }
    
    func fetchUserTips(userEmail: String) {
        db.collection("travelTips")
            .whereField("authorId", isEqualTo: userEmail)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching user tips: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                self?.tips = documents.compactMap { document -> TravelTip? in
                    let data = document.data()
                    let id = document.documentID
                    let authorId = data["authorId"] as? String ?? ""
                    let tripId = data["tripId"] as? String
                    let category = TipCategory(rawValue: data["category"] as? String ?? "") ?? .other
                    let title = data["title"] as? String ?? ""
                    let content = data["content"] as? String ?? ""
                    let images = data["images"] as? [String] ?? []
                    let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    let likes = data["likes"] as? Int ?? 0
                    let likedBy = data["likedBy"] as? [String] ?? []
                    
                    return TravelTip(id: id, authorId: authorId, tripId: tripId, category: category, title: title, content: content, images: images, createdAt: createdAt, likes: likes, likedBy: likedBy)
                }
            }
    }
    
    // 初期データを取得するメソッド
    func fetchInitialTips(limit: Int = 10) {
        guard !isFetching else { return }
        isFetching = true
        hasMoreData = true
        tips = [] // 既存のデータをクリア
        
        db.collection("travelTips")
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments { [weak self] (snapshot, error) in
                guard let self = self else { return }
                self.isFetching = false
                
                if let error = error {
                    print("Error fetching tips: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                self.tips = documents.compactMap { document in
                    self.documentToTravelTip(document: document)
                }
                self.lastDocument = documents.last
                
                if documents.count < limit {
                    self.hasMoreData = false
                }
            }
    }
    
    // 追加データを取得するメソッド
    func fetchMoreTips(limit: Int = 10) {
        guard !isFetching, hasMoreData else { return }
        guard let lastDocument = lastDocument else { return }
        isFetching = true
        
        db.collection("travelTips")
            .order(by: "createdAt", descending: true)
            .start(afterDocument: lastDocument)
            .limit(to: limit)
            .getDocuments { [weak self] (snapshot, error) in
                guard let self = self else { return }
                self.isFetching = false
                
                if let error = error {
                    print("Error fetching more tips: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                let newTips = documents.compactMap { document in
                    self.documentToTravelTip(document: document)
                }
                self.tips.append(contentsOf: newTips)
                self.lastDocument = documents.last
                
                if documents.count < limit {
                    self.hasMoreData = false
                }
            }
    }
    
    // ドキュメントをTravelTipに変換するヘルパーメソッド
    private func documentToTravelTip(document: DocumentSnapshot) -> TravelTip? {
        let data = document.data() ?? [:]
        let id = document.documentID
        let authorId = data["authorId"] as? String ?? ""
        let tripId = data["tripId"] as? String
        let category = TipCategory(rawValue: data["category"] as? String ?? "") ?? .other
        let title = data["title"] as? String ?? ""
        let content = data["content"] as? String ?? ""
        let images = data["images"] as? [String] ?? []
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let likes = data["likes"] as? Int ?? 0
        let likedBy = data["likedBy"] as? [String] ?? []
        
        return TravelTip(id: id, authorId: authorId, tripId: tripId, category: category, title: title, content: content, images: images, createdAt: createdAt, likes: likes, likedBy: likedBy)
    }
    
    func toggleLike(for tip: TravelTip, by userId: String) {
        let tipRef = db.collection("travelTips").document(tip.id)
        
        var updatedLikedBy = tip.likedBy
        if updatedLikedBy.contains(userId) {
            // 既にいいねしている場合は解除
            updatedLikedBy.removeAll { $0 == userId }
        } else {
            // いいねを追加
            updatedLikedBy.append(userId)
        }
        
        let likesCount = updatedLikedBy.count
        
        tipRef.updateData([
            "likedBy": updatedLikedBy,
            "likes": likesCount
        ]) { error in
            if let error = error {
                print("いいねの更新に失敗: \(error.localizedDescription)")
            }
        }
    }
    
    func addTip(authorId: String, tripId: String?, category: TipCategory, title: String, content: String, images: [String]) {
        let newTip: [String: Any] = [
            "authorId": authorId,
            "tripId": tripId ?? NSNull(),
            "category": category.rawValue,
            "title": title,
            "content": content,
            "images": images,
            "createdAt": Timestamp(date: Date()),
            "likes": 0,
            "likedBy": []
        ]
        
        db.collection("travelTips").addDocument(data: newTip) { error in
            if let error = error {
                print("Error adding tip: \(error.localizedDescription)")
            }
        }
    }
    
    func updateTip(_ tip: TravelTip) {
        let tipData: [String: Any] = [
            "category": tip.category.rawValue,
            "title": tip.title,
            "content": tip.content,
            "images": tip.images
        ]
        
        db.collection("travelTips").document(tip.id).updateData(tipData) { error in
            if let error = error {
                print("Error updating tip: \(error.localizedDescription)")
            }
        }
    }
    
    func deleteTip(_ tip: TravelTip) {
        db.collection("travelTips").document(tip.id).delete { error in
            if let error = error {
                print("Error deleting tip: \(error.localizedDescription)")
            }
        }
    }
    
    
}

