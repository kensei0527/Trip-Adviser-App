//
//  CreateTipsView.swift
//  TraveLink
//
//  Created by 古家健成 on 2024/09/16.
//

import SwiftUI
import Firebase
import FirebaseStorage

struct CreateTipView: View {
    @EnvironmentObject var viewModel: TravelTipViewModel
    @Environment(\.presentationMode) var presentationMode // 追加
    
    @State private var selectedCategory: TipCategory = .tripIntroduction
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var showImagePicker = false
    @State private var images: [UIImage] = []
    
    var trip: Trip?
    
    var body: some View {
        Form {
            Section(header: Text("Tip Category")) {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(TipCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
            }
            
            Section(header: Text("Title")) {
                TextField("Enter title", text: $title)
            }
            
            Section(header: Text("Content")) {
                TextEditor(text: $content)
                    .frame(height: 200)
            }
            
            Section(header: Text("Images")) {
                Button(action: {
                    showImagePicker = true
                }) {
                    Text("Add Images")
                }
                
                ForEach(images, id: \.self) { image in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                }
            }
            
            Button(action: submitTip) {
                Text("Submit Tip")
            }
        }
        .sheet(isPresented: $showImagePicker) {
            MultiImagePicker(images: $images)
        }
    }
    
    func submitTip() {
        guard let currentUser = Auth.auth().currentUser else {
            print("No user logged in")
            return
        }
        
        let storage = Storage.storage()
        let storageRef = storage.reference()
        
        var imageUrls: [String] = []
        let dispatchGroup = DispatchGroup()
        
        for (index, image) in images.enumerated() {
            dispatchGroup.enter()
            
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                print("Could not get JPEG representation of UIImage")
                dispatchGroup.leave()
                continue
            }
            
            let imageName = UUID().uuidString
            let imageRef = storageRef.child("tips/\(currentUser.uid)/\(imageName).jpg")
            
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            imageRef.putData(imageData, metadata: metadata) { metadata, error in
                if let error = error {
                    print("Error uploading image: \(error.localizedDescription)")
                    dispatchGroup.leave()
                    return
                }
                
                imageRef.downloadURL { url, error in
                    if let error = error {
                        print("Error getting download URL: \(error.localizedDescription)")
                    } else if let url = url {
                        imageUrls.append(url.absoluteString)
                    }
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.viewModel.addTip(
                authorId: currentUser.email!,
                tripId: self.trip?.id,
                category: self.selectedCategory,
                title: self.title,
                content: self.content,
                images: imageUrls
            )
            
            // フォームのリセット
            self.selectedCategory = .tripIntroduction
            self.title = ""
            self.content = ""
            self.images = []
            
            // シートを閉じる
            self.presentationMode.wrappedValue.dismiss() // 追加
        }
    }
}
