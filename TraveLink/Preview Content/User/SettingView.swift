//
//  SettingView.swift
//  TraveLink
//
//  Created by 古家健成 on 2024/08/22.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showingDeleteAccountAlert = false
    
    var body: some View {
        NavigationView {
            List {
                Button(action: signOut) {
                    Label("Sign Out", systemImage: "arrow.right.square")
                }
                .foregroundColor(.red)
                
                Button(action: { showingDeleteAccountAlert = true }) {
                    Label("Delete Account", systemImage: "trash")
                }
                .foregroundColor(.red)
            }
            .navigationTitle("Settings")
            .navigationBarItems(leading: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .alert(isPresented: $showingDeleteAccountAlert) {
            Alert(
                title: Text("Delete Account"),
                message: Text("Are you sure you want to delete your account? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    deleteAccount()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            // サインアウト後の処理（例：ログイン画面への遷移）
            presentationMode.wrappedValue.dismiss()
        } catch let signOutError as NSError {
            print("Error signing out: \(signOutError.localizedDescription)")
        }
    }
    
    func deleteAccount() {
        guard let user = Auth.auth().currentUser else { return }
        
        // Firestoreからユーザーデータを削除
        let db = Firestore.firestore()
        db.collection("users").document(user.email ?? "").delete { error in
            if let error = error {
                print("Error deleting user data: \(error.localizedDescription)")
            } else {
                // Authenticationからユーザーを削除
                user.delete { error in
                    if let error = error {
                        print("Error deleting user: \(error.localizedDescription)")
                    } else {
                        // アカウント削除後の処理（例：ログイン画面への遷移）
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
