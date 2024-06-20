//
//  ChatView.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/06/11.
//

import SwiftUI
import FirebaseAuth

struct ChatView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var chatViewModel = ChatViewModel()
    @State private var messageText = ""
    let chatId: String
    var userMail = Auth.auth().currentUser?.email
    
    
    var body: some View {
        VStack {
            List(chatViewModel.messages) { message in
                HStack {
                    if message.senderId == userMail {
                        Spacer()
                        Text(message.text)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                            .foregroundColor(.white)
                    } else {
                        Text(message.text)
                            .padding()
                            .background(Color.gray)
                            .cornerRadius(10)
                            .foregroundColor(.black)
                        Spacer()
                    }
                }
            }
            .onAppear {
                chatViewModel.fetchMessages(chatId: chatId)
            }
            .onDisappear {
                chatViewModel.stopListening()
            }
            
            HStack {
                TextField("Message", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button("Send") {
                    if let senderId = userMail {
                        print("Sending message from: \(senderId)")
                        chatViewModel.sendMessage(chatId: chatId, senderId: senderId, text: messageText)
                        print("Sent message text: \(messageText)")
                        messageText = ""
                    } else {
                        print("Error: authViewModel.user?.email is nil")
                    }
                    print("Current message text: \(messageText)")
                    print(userMail)
                }
                .padding()
            }
        }
        .navigationBarTitle("Chat", displayMode: .inline)
    }
}
