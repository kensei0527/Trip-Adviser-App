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
            Image("TripBuddyLogo") // Assume you've added the logo to your asset catalog
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 200)
                .clipShape(Circle())
            
            Text("Welcome to TraveLink!")
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, 10)
            
            Text("If you have an account, sign in. If you're new, sign up and let's create amazing journeys together!")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom, 30)
            
            /*TextField("Username", text: $userName)
             .textFieldStyle(RoundedBorderTextFieldStyle())
             .padding()*/
            
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
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Button(action: {
                viewModel.signUp(email: email, password: password, userName: userName)
            }) {
                Text("Sign Up")
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}
