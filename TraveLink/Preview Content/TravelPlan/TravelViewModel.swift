//
//  TravelViewModel.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/07/14.
//

// TripModels.swift

import SwiftUI
import Firebase

// MARK: - Models

struct Trip: Identifiable {
    let id: String
    var title: String
    var startDate: Date
    var endDate: Date
    var activities: [Activity]
    var participants: [String]  // 参加者のユーザーIDを格納
    var advisors: [String]
    var isCompleted: Bool
}

struct Activity: Identifiable, Equatable {
    let id: String
    var type: ActivityType
    var startTime: Date
    var endTime: Date
    var description: String
    
    var duration: TimeInterval {
        return endTime.timeIntervalSince(startTime)
    }
}

enum ActivityType: String, CaseIterable {
    case travel = "Move"
    case sightseeing = "Sightsee"
    case hotel = "Hotel"
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
}

enum UserRole: String, CaseIterable {
    case editor = "Editor"
    case advisor = "Advisor"
}

// MARK: - View Model

class SharedTripEditorState: ObservableObject {
    @Published var isAddEditorViewPresented: Bool = false
}

class TripViewModel: ObservableObject {
    @Published var trips: [Trip] = []
    @Published var currentTrip: Trip?
    @Published var isUpdatingTripStatus = false
    
    let calendar = Calendar(identifier: .gregorian)
    
    private var db = Firestore.firestore()
    private var currentUserEmail: String? {
        return Auth.auth().currentUser?.email
    }
    
    func fetchTrips() {
        guard let userId = currentUserEmail else {
            print("Error: No user logged in")
            return
        }
        
        db.collection("trips").whereField("participants", arrayContains: userId).addSnapshotListener { [weak self] querySnapshot, error in
            guard let self = self, let documents = querySnapshot?.documents else {
                print("Error fetching trips: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            self.trips = documents.compactMap { document -> Trip? in
                let data = document.data()
                let id = document.documentID
                let title = data["title"] as? String ?? ""
                let startDate = (data["startDate"] as? Timestamp)?.dateValue() ?? Date()
                let endDate = (data["endDate"] as? Timestamp)?.dateValue() ?? Date()
                let participants = data["participants"] as? [String] ?? []
                let isCompleted = data["done"] as? Bool ?? false
                let advisor = data["advisors"] as? [String] ?? []
                return Trip(id: id, title: title, startDate: startDate, endDate: endDate, activities: [], participants: participants, advisors: advisor, isCompleted: isCompleted)
            }
        }
    }
    
    var incompleteTrips: [Trip] {
        return trips.filter { !$0.isCompleted }
    }
    
    var completedTrips: [Trip] {
        return trips.filter { $0.isCompleted }
    }
    
    func updateTripCompletionStatus(for trip: Trip, isCompleted: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        isUpdatingTripStatus = true
        let db = Firestore.firestore()
        db.collection("trips").document(trip.id).updateData(["done": isCompleted]) { error in
            self.isUpdatingTripStatus = false
            if let error = error {
                completion(.failure(error))
            } else {
                if let index = self.trips.firstIndex(where: { $0.id == trip.id }) {
                    self.trips[index].isCompleted = isCompleted
                }
                completion(.success(()))
            }
        }
    }
    
    func updateTrip(_ trip: Trip, title: String, startDate: Date, endDate: Date) async throws {
        let tripRef = db.collection("trips").document(trip.id)
        let updatedData: [String: Any] = [
            "title": title,
            "startDate": Timestamp(date: startDate),
            "endDate": Timestamp(date: endDate)
        ]
        
        try await tripRef.updateData(updatedData)
        
        if let index = trips.firstIndex(where: { $0.id == trip.id }) {
            trips[index].title = title
            trips[index].startDate = startDate
            trips[index].endDate = endDate
        }
        
        if currentTrip?.id == trip.id {
            currentTrip?.title = title
            currentTrip?.startDate = startDate
            currentTrip?.endDate = endDate
        }
    }
    
    // 新しいメソッド: 参加者の削除
    func removeParticipant(_ email: String, from trip: Trip) async throws {
        let tripRef = db.collection("trips").document(trip.id)
        try await tripRef.updateData([
            "participants": FieldValue.arrayRemove([email])
        ])
        
        if let index = trips.firstIndex(where: { $0.id == trip.id }) {
            trips[index].participants.removeAll { $0 == email }
        }
        
        if currentTrip?.id == trip.id {
            currentTrip?.participants.removeAll { $0 == email }
        }
    }
    
    // 新しいメソッド: 旅程の検索
    func searchTrips(with query: String) -> [Trip] {
        let lowercasedQuery = query.lowercased()
        return trips.filter { trip in
            trip.title.lowercased().contains(lowercasedQuery) ||
            trip.activities.contains { $0.description.lowercased().contains(lowercasedQuery) }
        }
    }
    
    func addTrip(title: String, startDate: Date, endDate: Date) {
        guard let userId = currentUserEmail else {
            print("Error: No user logged in")
            return
        }
        
        let newTrip = [
            "title": title,
            "startDate": Timestamp(date: startDate),
            "endDate": Timestamp(date: endDate),
            "participants": [userId]
        ] as [String : Any]
        
        db.collection("trips").addDocument(data: newTrip) { error in
            if let error = error {
                print("Error adding trip: \(error.localizedDescription)")
            }
        }
    }
    
    func deleteTrip(_ trip: Trip) {
        db.collection("trips").document(trip.id).delete { error in
            if let error = error {
                print("Error deleting trip: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchActivities(for trip: Trip) {
        db.collection("trips").document(trip.id).collection("activities").addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("Error fetching activities: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            let activities = documents.compactMap { document -> Activity? in
                let data = document.data()
                let id = document.documentID
                let type = ActivityType(rawValue: data["type"] as? String ?? "") ?? .sightseeing
                let startTime = (data["startTime"] as? Timestamp)?.dateValue() ?? Date()
                let endTime = (data["endTime"] as? Timestamp)?.dateValue() ?? Date()
                let description = data["description"] as? String ?? ""
                return Activity(id: id, type: type, startTime: startTime, endTime: endTime, description: description)
            }
            
            if let index = self.trips.firstIndex(where: { $0.id == trip.id }) {
                self.trips[index].activities = activities
            }
            
            if self.currentTrip?.id == trip.id {
                self.currentTrip?.activities = activities
            }
        }
    }
    
    func addActivity(to trip: Trip, type: ActivityType, startTime: Date, endTime: Date, description: String) {
        let newActivity = [
            "type": type.rawValue,
            "startTime": Timestamp(date: startTime),
            "endTime": Timestamp(date: endTime),
            "description": description
        ] as [String : Any]
        db.collection("trips").document(trip.id).collection("activities").addDocument(data: newActivity) { error in
            if let error = error {
                print("Error adding activity: \(error.localizedDescription)")
            }
        }
    }
    
    func deleteActivity(_ activity: Activity, from trip: Trip) {
        if let index = self.trips.firstIndex(where: { $0.id == trip.id }),
           let activityIndex = self.trips[index].activities.firstIndex(where: { $0.id == activity.id }) {
            self.trips[index].activities.remove(at: activityIndex)
        }
        
        db.collection("trips").document(trip.id).collection("activities").document(activity.id).delete { error in
            if let error = error {
                print("Error deleting activity: \(error.localizedDescription)")
            }
        }
    }
    
    func updateActivity(_ activity: Activity, in trip: Trip, type: ActivityType, startTime: Date, endTime: Date, description: String) {
        let updatedActivity = [
            "type": type.rawValue,
            "startTime": Timestamp(date: startTime),
            "endTime": Timestamp(date: endTime),
            "description": description
        ] as [String : Any]
        
        db.collection("trips").document(trip.id).collection("activities").document(activity.id).updateData(updatedActivity) { error in
            if let error = error {
                print("Error updating activity: \(error.localizedDescription)")
            } else {
                // ローカルのデータも更新
                if let tripIndex = self.trips.firstIndex(where: { $0.id == trip.id }),
                   let activityIndex = self.trips[tripIndex].activities.firstIndex(where: { $0.id == activity.id }) {
                    self.trips[tripIndex].activities[activityIndex] = Activity(id: activity.id, type: type, startTime: startTime, endTime: endTime, description: description)
                }
                
                if self.currentTrip?.id == trip.id,
                   let activityIndex = self.currentTrip?.activities.firstIndex(where: { $0.id == activity.id }) {
                    self.currentTrip?.activities[activityIndex] = Activity(id: activity.id, type: type, startTime: startTime, endTime: endTime, description: description)
                }
            }
        }
    }
    
    func addEditors(to trip: Trip, editors: [String: UserRole]) {
        let tripRef = db.collection("trips").document(trip.id)
        
        var newParticipants: [String] = []
        var newAdvisors: [String] = []
        
        for (userEmail, role) in editors {
            newParticipants.append(userEmail)
            if role == .advisor {
                newAdvisors.append(userEmail)
            }
        }
        
        tripRef.updateData([
            "participants": FieldValue.arrayUnion(newParticipants),
            "advisors": FieldValue.arrayUnion(newAdvisors)
        ]) { error in
            if let error = error {
                print("Error adding editors: \(error.localizedDescription)")
            } else {
                self.fetchTrips() // 更新後にトリップリストを再取得
                if self.currentTrip?.id == trip.id {
                    self.currentTrip?.participants.append(contentsOf: newParticipants)
                    self.currentTrip?.advisors.append(contentsOf: newAdvisors)
                }
            }
        }
    }
    
    
    
    
    func fetchTripCompletionStatus(for trip: Trip, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        db.collection("trips").document(trip.id).getDocument { (document, error) in
            if let document = document, document.exists {
                let isCompleted = document.data()?["done"] as? Bool ?? false
                completion(isCompleted)
            } else {
                print("Document does not exist or error: \(error?.localizedDescription ?? "Unknown error")")
                completion(false)
            }
        }
    }
    
    
}


