//
//  EditView.swift
//  TraveLink
//
//  Created by 古家健成 on 2024/09/17.
//

import SwiftUI

struct EditTipView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: TravelTipViewModel
    @State var tip: TravelTip
    @State private var selectedCategory: TipCategory
    @State private var title: String
    @State private var content: String
    @State private var images: [UIImage] = []
    @State private var showImagePicker = false
    
    init(tip: TravelTip, viewModel: TravelTipViewModel) {
        self._tip = State(initialValue: tip)
        self.viewModel = viewModel
        self._selectedCategory = State(initialValue: tip.category)
        self._title = State(initialValue: tip.title)
        self._content = State(initialValue: tip.content)
    }
    
    var body: some View {
        Form {
            Section(header: Text("カテゴリー")) {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(TipCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
            }
            
            Section(header: Text("タイトル")) {
                TextField("タイトルを入力", text: $title)
            }
            
            Section(header: Text("内容")) {
                TextEditor(text: $content)
                    .frame(height: 200)
            }
            
            Section(header: Text("画像")) {
                Button(action: {
                    showImagePicker = true
                }) {
                    Text("画像を追加")
                }
                
                // 既存の画像を表示
                ForEach(tip.images, id: \.self) { imageUrl in
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                }
                
                // 新しく追加した画像を表示
                ForEach(images, id: \.self) { image in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                }
            }
            
            Button(action: saveChanges) {
                Text("変更を保存")
            }
        }
        .sheet(isPresented: $showImagePicker) {
            MultiImagePicker(images: $images)
        }
    }
    
    func saveChanges() {
        // 新しく追加した画像をFirebase Storageにアップロードし、ダウンロードURLを取得
        // ここで画像のアップロード処理を行い、tip.imagesを更新します
        
        // 既存のtipを更新
        tip.category = selectedCategory
        tip.title = title
        tip.content = content
        // tip.images = 更新後の画像URLリスト
        
        viewModel.updateTip(tip)
        presentationMode.wrappedValue.dismiss()
    }
}
