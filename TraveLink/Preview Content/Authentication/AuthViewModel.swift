//
//  AuthViewModel.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/06/11.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var isSignedIn = false
    @Published var user: User? = nil
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    @Published var signUpSuccess = false
    private var authStateDidChangeListenerHandle: AuthStateDidChangeListenerHandle?
    
    private var db = Firestore.firestore()
    
    init() {
        authStateDidChangeListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.isSignedIn = user != nil
        }
    }
    
    deinit {
        if let handle = authStateDidChangeListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Error signing in: \(error.localizedDescription)")
            }
        }
    }
    
    func signUp(email: String, password: String, userName: String) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Error signing up: \(error.localizedDescription)")
                self.errorMessage = error.localizedDescription
                self.signUpSuccess = false
            }
            guard let user = authResult?.user else { return }
            
            // Firestoreにユーザー情報を保存
            self.db.collection("users").document(user.email!).setData([
                "name": userName,
                "email": user.email!,
                "password": password
            ]) { error in
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.signUpSuccess = false
                } else {
                    self.isAuthenticated = true
                    self.signUpSuccess = true
                }
            }
        }
    }
    
    /*func signUp(email: String, password: String, userName: String) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Error signing up: \(error.localizedDescription)")
            }
            guard let user = authResult?.user else { return }
            
            // Firestoreにユーザー情報を保存
            self.db.collection("users").document(user.email!).setData([
                "name": userName,
                "email": user.email!,
                "password": password
            ]) { error in
                if let error = error {
                    self.errorMessage = error.localizedDescription
                } else {
                    self.isAuthenticated = true
                }
            }
            self.isAuthenticated = true
        }
        
        func signOut() {
            do {
                try Auth.auth().signOut()
                self.isSignedIn = false
            } catch let signOutError as NSError {
                print("Error signing out: \(signOutError.localizedDescription)")
            }
        }
    }*/
}
