//
//  TipDetailView.swift
//  TraveLink
//
//  Created by 古家健成 on 2024/09/16.
//

import SwiftUI
import Firebase

struct TipDetailView: View {
    var tip: TravelTip
    @State private var authorName: String = "Anonymous users"
    @EnvironmentObject var viewModel: TravelTipViewModel
    @State private var isLiked: Bool = false
    @State private var currentUserId: String = Auth.auth().currentUser?.email ?? ""
    @StateObject private var commentViewModel = CommentViewModel()
    @StateObject var userFetchModel = UserFetchModel()
    @State private var newComment: String = ""
    @State private var showProfile = false
    @State private var user = User(id: "", name: "", email: "", location: "", profileImageURL: URL(string: ""))
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(tip.title)
                    .font(.largeTitle)
                    .bold()
                
                Text("Category: \(tip.category.rawValue)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text("Contributor: \(authorName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(tip.content)
                    .font(.body)
                
                ForEach(tip.images, id: \.self) { imageUrl in
                    if let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { image in
                            image.resizable()
                                .scaledToFit()
                        } placeholder: {
                            Color.gray.opacity(0.3)
                        }
                        .frame(maxHeight: 300)
                        .cornerRadius(8)
                    }
                }
                
                // いいねボタン
                HStack {
                    Button(action: {
                        viewModel.toggleLike(for: tip, by: currentUserId)
                        isLiked.toggle()
                    }) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .gray)
                    }
                    Text("\(tip.likes)")
                    Spacer()
                    Text(tip.createdAt, style: .date)
                }
                .font(.footnote)
                .foregroundColor(.gray)
                
                // コメントセクション
                Divider()
                Text("Comment")
                    .font(.headline)
                
                ForEach(commentViewModel.comments) { comment in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(comment.authorName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(comment.content)
                            .font(.body)
                    }
                    .padding(.vertical, 4)
                }
                
                // コメント入力フィールド
                HStack {
                    TextField("Input comment...", text: $newComment)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button(action: {
                        commentViewModel.addComment(to: tip.id, content: newComment)
                        newComment = ""
                    }) {
                        Text("Submit")
                    }
                }
                
                Button(action: {
                    showProfile = true
                }) {
                    Text("Contributor: \(authorName)")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .sheet(isPresented: $showProfile) {
                    UserProfileVieww(user: self.user)
                }
            }
            .padding()
        }
        .onAppear {
            fetchAuthorName()
            isLiked = tip.likedBy.contains(currentUserId)
            commentViewModel.fetchComments(for: tip.id)
            userFetchModel.fetchUserByEmail(tip.authorId) { user in
                self.user = user!
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func fetchAuthorName() {
        let db = Firestore.firestore()
        db.collection("users").document(tip.authorId).getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                self.authorName = data?["name"] as? String ?? "Anonymous User"
            } else {
                print("ユーザー名の取得に失敗: \(error?.localizedDescription ?? "不明なエラー")")
            }
        }
    }
}
