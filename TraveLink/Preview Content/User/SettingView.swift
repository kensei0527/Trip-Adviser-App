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
    @State private var username = ""
    @State private var showingChangeUsernameAlert = false
    @State private var newUsername = ""
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfUse = false
    @State private var showWelcomeModal: Bool = false
    
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Account")) {
                    Text("Username: \(username)")
                    Button(action: { showingChangeUsernameAlert = true }) {
                        Label("Change Username", systemImage: "pencil")
                    }
                }
                
                Section(header: Text("Actions")) {
                    Button("Show Welcome Message") {
                        showWelcomeModal = true
                    }
                    .sheet(isPresented: $showWelcomeModal) {
                        OnboardingView(isFirstLaunch: $showWelcomeModal)
                    }
                    Button(action: {
                        showingPrivacyPolicy = true
                    }, label: {
                        Label("Privacy Policy", systemImage: "person.badge.shield.checkmark")
                    })
                    .sheet(isPresented: $showingPrivacyPolicy, content: {
                        SafariView(url: URL(string: "https://kensei0527.github.io/TraveLink_web/")!)
                    })
                    Button(action: {
                        showingTermsOfUse = true
                    }, label: {
                        Label("Terms Of Use", systemImage: "pencil.line")
                    })
                    .sheet(isPresented: $showingTermsOfUse, content: {
                        SafariView(url: URL(string: "https://kensei0527.github.io/TraveLink_term/")!)
                    })
                    
                    Button(action: signOut) {
                        Label("Sign Out", systemImage: "arrow.right.square")
                    }
                    .foregroundColor(.red)
                    
                    Button(action: { showingDeleteAccountAlert = true }) {
                        Label("Delete Account", systemImage: "trash")
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(leading: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .onAppear(perform: loadUsername)
        .alert("Change Username", isPresented: $showingChangeUsernameAlert) {
            TextField("New username", text: $newUsername)
            Button("Cancel", role: .cancel) { }
            Button("Change") {
                changeUsername()
            }
        } message: {
            Text("Enter your new username")
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
    
    func loadUsername() {
        guard let userEmail = Auth.auth().currentUser?.email else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userEmail).getDocument { (document, error) in
            if let document = document, document.exists {
                self.username = document.data()?["name"] as? String ?? ""
            }
        }
    }
    
    func changeUsername() {
        guard let userEmail = Auth.auth().currentUser?.email else { return }
        let db = Firestore.firestore()
        db.collection("users").document(userEmail).updateData(["name": newUsername]) { error in
            if let error = error {
                print("Error updating username: \(error.localizedDescription)")
            } else {
                self.username = newUsername
                self.newUsername = ""
            }
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
