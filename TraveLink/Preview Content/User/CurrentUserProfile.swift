//
//  CurrentUserProfile.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/06/25.
//

import SwiftUI
import MapKit
import Firebase

struct CurrentUserProfileView: View {
    @StateObject private var viewModel = CurrentUserProfileViewModel()
    @State private var showingImagePicker = false
    @State private var showingSettingsView = false
    @State private var showingReviews = false
    @State private var showingFollowersList = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    // Profile Header
                    ProfileHeader(
                        profileImage: viewModel.profileImage,
                        userName: viewModel.userName,
                        postsCount: viewModel.tipViewModel.tips.count,
                        followersCount: viewModel.followers.count,
                        onFollowersTapped: {
                            showingFollowersList = true
                        }
                    )
                    
                    // User Rating
                    userRating
                    
                    // Profile Actions
                    HStack(spacing: 20) {
                        Button(action: { showingImagePicker = true }) {
                            Label("Change Picture", systemImage: "camera")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        
                        Button(action: signOut) {
                            Label("Sign Out", systemImage: "arrow.right.square")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    
                    // Introduction Section
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Introduction")
                                .font(.headline)
                            Spacer()
                            Button(action: {
                                viewModel.isEditingIntroduction.toggle()
                                if !viewModel.isEditingIntroduction {
                                    viewModel.saveIntroduction()
                                }
                            }) {
                                Text(viewModel.isEditingIntroduction ? "Save" : "Edit")
                            }
                        }
                        
                        if viewModel.isEditingIntroduction {
                            TextEditor(text: $viewModel.introduction)
                                .frame(height: 100)
                                .padding(4)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        } else {
                            Text(viewModel.introduction.isEmpty ? "No introduction yet." : viewModel.introduction)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    
                    // Location Information
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Your Location")
                            .font(.headline)
                        
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                            Text(viewModel.address)
                        }
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        
                        MapView(coordinate: $viewModel.userLocation)
                            .frame(height: 200)
                            .cornerRadius(10)
                        
                        TextField("Enter your Country", text: $viewModel.countryAddress)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("Enter your City", text: $viewModel.cityAddress)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button(action: viewModel.updateLocation) {
                            Label("Update Location", systemImage: "location")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    
                    // Posts Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("My Posts")
                            .font(.headline)
                            .padding(.leading)
                        
                        ForEach(viewModel.tipViewModel.tips) { tip in
                            UserTipRow(tip: tip, deleteAction: {
                                viewModel.deleteTip(tip)
                            })
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                }
            }
            .padding()
        }
        .background(Color.gray.opacity(0.1).ignoresSafeArea())
        .navigationTitle("My Profile")
        .navigationBarItems(trailing: settingsButton)
        .onAppear {
            // Any additional setup if needed
        }
        .alert(isPresented: $viewModel.showingAlert) {
            Alert(title: Text(""), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
        }
        .alert(isPresented: $viewModel.showingDeleteConfirmation) {
            Alert(
                title: Text("Delete Post"),
                message: Text("Are you sure you want to delete this post?"),
                primaryButton: .destructive(Text("Delete")) {
                    if let tip = viewModel.selectedTip {
                        viewModel.tipViewModel.deleteTip(tip)
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .sheet(isPresented: $showingImagePicker, onDismiss: viewModel.loadImage) {
            ImagePicker(image: $viewModel.inputImage)
        }
        .sheet(isPresented: $showingSettingsView) {
            SettingsView()
        }
        .sheet(isPresented: $showingReviews) {
            ReviewsListView(reviews: viewModel.userReviewModel.reviews)
        }
        .navigationDestination(isPresented: $showingFollowersList) {
            FollowersListView(followers: viewModel.followers)
        }
    }
    
    private var settingsButton: some View {
        Button(action: {
            showingSettingsView = true
            viewModel.userReviewModel.fetchReviews(for: viewModel.currentUserEmail)
        }) {
            Image(systemName: "gear")
                .foregroundColor(.blue)
        }
    }
    
    private var userRating: some View {
        HStack {
            ForEach(0..<5) { index in
                if !viewModel.userReviewModel.averageRating.isNaN && !viewModel.userReviewModel.averageRating.isInfinite {
                    Image(systemName: index < Int(viewModel.userReviewModel.averageRating) ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                } else {
                    Image(systemName: "star")
                }
            }
            Text(String(format: "%.1f", viewModel.userReviewModel.averageRating))
                .foregroundColor(.secondary)
        }
        .padding(.vertical)
        .onTapGesture {
            showingReviews = true
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            dismiss()
        } catch let signOutError as NSError {
            print("Error signing out: \(signOutError.localizedDescription)")
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct ProfileHeader: View {
    let profileImage: Image?
    let userName: String
    let postsCount: Int
    let followersCount: Int
    let onFollowersTapped: () -> Void  // Callback when followers are tapped
    
    var body: some View {
        VStack {
            if let image = profileImage {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                    .shadow(radius: 7)
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.gray)
            }
            
            Text(userName)
                .font(.title)
                .fontWeight(.bold)
            
            HStack(spacing: 40) {
                VStack {
                    Text("\(postsCount)")
                        .font(.headline)
                    Text("Posts")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .frame(height: 40)
                
                Button(action: {
                    onFollowersTapped()
                }) {
                    VStack {
                        Text("\(followersCount)")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Followers")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.top, 8)
        }
    }
}

struct ReviewsListView: View {
    let reviews: [Review]
    
    var body: some View {
        List(reviews, id: \.comment) { review in
            VStack(alignment: .leading) {
                //Text(review.)
                HStack {
                    ForEach(0..<5) { index in
                        Image(systemName: index < review.rating ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                    }
                }
                Text(review.comment)
                    .padding(.top, 4)
            }
        }
        .navigationTitle("Reviews")
    }
}

struct MapView: UIViewRepresentable {
    @Binding var coordinate: CLLocationCoordinate2D
    
    func makeUIView(context: Context) -> MKMapView {
        MKMapView(frame: .zero)
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        uiView.setRegion(region, animated: true)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        uiView.removeAnnotations(uiView.annotations)
        uiView.addAnnotation(annotation)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.white)
            .foregroundColor(.blue)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.blue, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}
