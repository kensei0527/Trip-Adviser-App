//
//  UserProfile.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/06/14.
//
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct UserProfileView: View {
    var user: User
    @StateObject private var chatCreationViewModel = ChatCreationViewModel()
    @State var chatId : String?
    @State var idRow: Array<String> = []
    @State var chatFlag = false
    @EnvironmentObject var authViewModel: AuthViewModel
    var db = Firestore.firestore()
    func createAndStartChat(){
        chatCreationViewModel.createChat(with: user.email) { newChatId in
            if let newChatId = newChatId {
                self.chatId = newChatId
                // ここでChatViewに遷移するコードを追加する
                //print(chatId)
                //chatFlag = true
            }
        }
    }
    
    var body: some View {
        NavigationStack{
            VStack {
                Text("User Name: \(user.name)")
                    .font(.largeTitle)
                    .padding()
                
                Text("Email: \(user.email)")
                    .font(.subheadline)
                    .padding()
                
                Button(action: {
                    //guard let currentUserEmail = Auth.auth().currentUser?.email else { return }
                    //idRow = [currentUserEmail, user.email]
                    //print(idRow[0])
                    print(user.email)
                    createAndStartChat()
                    //ChatView(chatId: chatId!)
                    
                }) {
                    Text("Create Chat")
                }
                NavigationLink(destination: ChatView(chatId: chatId ?? "")
                    .environmentObject(authViewModel),
                               isActive: Binding(
                                get: { chatId != nil },
                                set: { if !$0 { chatId = nil } }
                               )) {
                                   EmptyView()
                               }
                
                /*Button(action: {
                    if(chatId != nil){
                        ChatView(chatId: chatId)
                    }else{
                        //chatId = db.
                        return
                    }
                }, label: {
                    Text("start")
                })*/
                /*if(chatFlag == true){
                    ChatView(chatId: chatId!)
                }*/
                //互いのユーザーネームを参照してナビゲーションを表示する
                //NavigationLink(destination: ChatView(chatId: chatId), label: {Text("Talk")})
            }
            .navigationTitle("Profile")
        }
    }
}

