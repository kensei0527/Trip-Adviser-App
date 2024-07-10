//
//  AuthenScreen.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/06/11.
//

import SwiftUI
import FirebaseAuth

struct AuthenScreen: View {
    @EnvironmentObject var viewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
            if viewModel.isSignedIn {
                HomeScreen()
            } else {
                SignInView()
            }
        }
        .onAppear {
            viewModel.isSignedIn = Auth.auth().currentUser != nil
        }
    }
}

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var userName = ""
    @EnvironmentObject var viewModel: AuthViewModel
    
    var body: some View {
        VStack {
            TextField("Username", text: $userName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button(action: {
                viewModel.signIn(email: email, password: password)
            }) {
                Text("Sign In")
            }
            .padding()
            
            Button(action: {
                viewModel.signUp(email: email, password: password, userName: userName)
            }) {
                Text("Sign Up")
            }
            .padding()
        }
        .padding()
    }
}

