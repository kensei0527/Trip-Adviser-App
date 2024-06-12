//
//  ChatView.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/06/11.
//

import SwiftUI

struct ChatView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var chatViewModel = ChatViewModel()
    @State private var messageText = ""
    let chatId: String
    
    var body: some View {
        VStack {
            List(chatViewModel.messages) { message in
                HStack {
                    if message.senderId == authViewModel.user?.uid {
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
                    if let senderId = authViewModel.user?.uid {
                        chatViewModel.sendMessage(chatId: chatId, senderId: senderId, text: messageText)
                        messageText = ""
                    }
                }
                .padding()
            }
        }
        .navigationBarTitle("Chat", displayMode: .inline)
    }
}
