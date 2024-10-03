//
//  AddReviewView.swift
//  TraveLink
//
//  Created by 古家健成 on 2024/09/14.
//

import SwiftUI

struct AddReviewView: View {
    @StateObject private var viewModel = UserReviewViewModel()
    @StateObject private var userFetchModel = UserFetchModel()
    @State private var rating: Int = 3
    @State private var comment: String = ""
    @State private var showAlert = false
    @State private var username = ""
    @Environment(\.presentationMode) var presentationMode
    
    
    let targetUserId: String
    let currentUserId: String
    @ObservedObject var sharedReviewState: UserReviewViewModel
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Review for　\(username)")) {
                    Picker("Review", selection: $rating) {
                        ForEach(1...5, id: \.self) { number in
                            Text("\(number)").tag(number)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Comment")) {
                    TextEditor(text: $comment)
                        .frame(height: 150)
                }
                
                Section {
                    Button("Post Review") {
                        print(targetUserId)
                        print(currentUserId)
                        submitReview()
                    }
                }
            }
            .onAppear{
                userFetchModel.fetchUserByEmail(targetUserId){ user in
                    username = user?.name ?? ""
                }
            }
            .navigationTitle("Please Post Review !")
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Thank you !"),
                    message: Text("Your Review is posted !"),
                    dismissButton: .default(Text("OK")) {
                        sharedReviewState.isReviewCompleted = true
                        sharedReviewState.isReviewNeeded = false
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }
    
    private func submitReview() {
        viewModel.addReview(
            for: targetUserId,
            reviewerId: currentUserId,
            rating: rating,
            comment: comment
        )
        showAlert = true
    }
}


