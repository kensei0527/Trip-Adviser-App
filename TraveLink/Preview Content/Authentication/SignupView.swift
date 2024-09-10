//
//  SignupView.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/08/21.
//

import SwiftUI
import Firebase
import SafariServices

struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var userName = ""
    @State private var agreedToPrivacyPolicy = false
    @State private var agreedToTermOfUse = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTermOfUse = false
    @EnvironmentObject var viewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode
    
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
            
            HStack {
                Text("If you have reviewed our privacy policy, please give your consent.")
                Spacer()
                Button(action: {
                    showingPrivacyPolicy = true
                }) {
                    Text("Privacy Policy")
                        .foregroundColor(.blue)
                        .underline()
                }
                .sheet(isPresented: $showingPrivacyPolicy) {
                    SafariView(url: URL(string: "https://kensei0527.github.io/TraveLink_web/")!)
                }
                
            }
            .padding()
            
            Toggle("Agree", isOn: $agreedToPrivacyPolicy)
                .padding()
            
            HStack {
                Text("If you have reviewed our Terms of use, please give your consent.")
                Spacer()
                Button(action: {
                    showingTermOfUse = true
                }) {
                    Text("Terms Of Use")
                        .foregroundColor(.blue)
                        .underline()
                }
                .sheet(isPresented: $showingTermOfUse) {
                    SafariView(url: URL(string: "https://kensei0527.github.io/TraveLink_term/")!)
                }
                
            }
            .padding()
            
            Toggle("Agree", isOn: $agreedToTermOfUse)
                .padding()
            
            Button(action: {
                if agreedToPrivacyPolicy && agreedToTermOfUse {
                    viewModel.signUp(email: email, password: password, userName: userName)
                } else {
                    // プライバシーポリシーに同意していない場合のアラートを表示
                }
            }) {
                Text("Sign Up")
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding()
                    .background(agreedToPrivacyPolicy ? Color.green : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(!agreedToPrivacyPolicy)
            .padding(.horizontal)
        }
        .padding()
        .onChange(of: viewModel.signUpSuccess) { value in
            if value {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<SafariView>) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariView>) {
    }
}
