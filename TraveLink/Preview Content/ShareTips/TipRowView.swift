//
//  TipRowView.swift
//  TraveLink
//
//  Created by 古家健成 on 2024/09/16.
//

import SwiftUI
import Firebase

struct TipRowView: View {
    var tip: TravelTip
    @State private var authorName: String = "Anonymous User"
    @EnvironmentObject var viewModel: TravelTipViewModel
    @StateObject var userFetchModel = UserFetchModel()
    @State private var isLiked: Bool = false
    @State private var currentUserId: String = Auth.auth().currentUser?.email ?? ""
    @State private var showProfile = false
    @State private var user = User(id: "", name: "", email: "", location: "", profileImageURL: URL(string: ""))
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 投稿者情報と投稿時間
            HStack(alignment: .top, spacing: 12) {
                // プロフィール画像の表示
                if let profileImageURL = user.profileImageURL {
                    AsyncImage(url: profileImageURL) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(.gray)
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.gray)
                        .frame(width: 40, height: 40)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    // 投稿者名
                    Button(action: {
                        showProfile = true
                    }) {
                        Text(authorName)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .sheet(isPresented: $showProfile) {
                        // ユーザープロフィールビューへの遷移（適宜調整してください）
                        UserProfileVieww(user: user)
                    }
                    
                    // 投稿時間
                    Text(tip.createdAt, style: .time) // 時間表示
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            // カテゴリー
            Text(tip.category.rawValue)
                .font(.caption)
                .foregroundColor(.gray)
            
            // タイトル
            Text(tip.title)
                .font(.headline)
                .padding(.vertical, 2)
            
            // コンテンツ
            Text(tip.content)
                .font(.body)
                .lineLimit(3)
                .truncationMode(.tail)
            
            // 投稿画像
            if let imageUrl = tip.images.first, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image.resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(height: 200)
                .clipped()
                .cornerRadius(8)
            }
            
            // いいねボタンとカウント
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
                
                // コメントボタン（必要に応じて）
                Button(action: {
                    // コメント画面への遷移など
                }) {
                    Image(systemName: "bubble.right")
                        .foregroundColor(.gray)
                }
                Text("Comment")
            }
            .font(.footnote)
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .onAppear {
            fetchAuthorName()
            isLiked = tip.likedBy.contains(currentUserId)
            userFetchModel.fetchUserByEmail(tip.authorId) { fetchedUser in
                if let fetchedUser = fetchedUser {
                    self.user = fetchedUser
                }
            }
        }
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
