//
//  AddEditorView.swift
//  TraveLink
//
//  Created by 古家健成 on 2024/09/12.
//

import SwiftUI
import Firebase

struct AddTripEditerView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var userFetchModel = UserFetchModel()
    @State private var selectedUsers: [String: UserRole] = [:]
    @EnvironmentObject var sharedState: SharedTripEditorState
    @State private var coEditorList: [User] = []
    var trip: Trip
    var userlist: [User]
    var onComplete: ([String: UserRole]) -> Void
    
    
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Current Co-Editors and Advisors")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top)
                
                ForEach(coEditorList) { user in
                    HStack {
                        AsyncImage(url: user.profileImageURL) { image in
                            image.resizable()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading) {
                            Text(user.name)
                                .font(.headline)
                            Text(trip.advisors.contains(user.email) ? "Advisor" : "Editor")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .frame(height: 60)
                }
                
                Text("Select New Co-Editors or Advisors")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top)
                
                ForEach(userlist) { user in
                    HStack {
                        AsyncImage(url: user.profileImageURL) { image in
                            image.resizable()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading) {
                            Text(user.name)
                                .font(.headline)
                            Text(user.email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedUsers[user.email] != nil {
                            Picker("Role", selection: Binding(
                                get: { self.selectedUsers[user.email] ?? .editor },
                                set: { self.selectedUsers[user.email] = $0 }
                            )) {
                                ForEach(UserRole.allCases, id: \.self) { role in
                                    Text(role.rawValue).tag(role)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 150)
                        } else {
                            Button("Add") {
                                selectedUsers[user.email] = .editor
                            }
                        }
                    }
                    .padding(.horizontal)
                    .frame(height: 60)
                }
                Button("Done") {
                    onComplete(selectedUsers)
                    dismiss()
                }
            }
        }
        .task {
            await userFetchModel.fetchFollowUser()
            print(trip.advisors)
            print(coEditorList)
        }
        .onAppear {
            fetchCurrentParticipants()
        }
        .navigationTitle("Add New Editor/Advisor: \(trip.title)")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    onComplete(selectedUsers)
                    dismiss()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    Task {
                        await userFetchModel.fetchFollowUser()
                    }
                }, label: {
                    Image(systemName: "arrow.clockwise")
                })
            }
        }
    }
    
    private func fetchCurrentParticipants() {
        for userEmail in trip.participants {
            userFetchModel.fetchUserByEmail(userEmail) { user in
                DispatchQueue.main.async {
                    if let user = user {
                        self.coEditorList.append(user)
                    }
                }
            }
        }
    }
    
}
