//
//  SearchCountryList.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/06/12.
//


import SwiftUI
import FirebaseFirestore

class CountryViewModel: ObservableObject {
    @Published var countries: [String] = []
    private var db = Firestore.firestore()
    
    init() {
        fetchData()
    }
    
    func fetchData() {
        db.collection("countries").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                self.countries = querySnapshot?.documents.compactMap { $0["name"] as? String } ?? []
            }
        }
    }
    
    func addCountry(name: String) {
        db.collection("countries").document(name).setData(["country": name]){
            error in
            if let error = error {
                print("Error adding document: \(error)")
            } else {
                self.fetchData()
            }
        }
        //db.collection("countries").addDocument(data: ["name": name]) { error in
           // if let error = error {
             //   print("Error adding document: \(error)")
           // } else {
             //   self.fetchData()
           // }
        //}
    }
}

