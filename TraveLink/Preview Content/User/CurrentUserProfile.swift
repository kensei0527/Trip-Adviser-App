//
//  CurrentUserProfile.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/06/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import MapKit

struct CurrentUserProfileView: View {
    @State private var currentUserEmail: String = ""
    @State private var userLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503)  // デフォルトは東京
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503), span: MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 2))
    @State private var showingLocationPicker = false
    @State private var countryAddress: String = ""
    @State private var cityAddress: String = ""
    @State private var address: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var userName: String = ""
    @State private var isLoading: Bool = true
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var profileImage: Image?
    @State private var introduction: String = ""
    @State private var isEditingIntroduction: Bool = false
    @State private var showingSettingsView = false
    @Environment(\.dismiss) var dismiss
    
    private var db = Firestore.firestore()
    private let storage = Storage.storage().reference()
    
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView()
                } else {
                    // Profile Header
                    ProfileHeader(profileImage: profileImage, userName: userName)
                    
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
                    
                    // Introduction Section
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Introduction")
                                .font(.headline)
                            Spacer()
                            Button(action: {
                                isEditingIntroduction.toggle()
                                if !isEditingIntroduction {
                                    saveIntroduction()
                                }
                            }) {
                                Text(isEditingIntroduction ? "Save" : "Edit")
                            }
                        }
                        
                        if isEditingIntroduction {
                            TextEditor(text: $introduction)
                                .frame(height: 100)
                                .padding(4)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        } else {
                            Text(introduction.isEmpty ? "No introduction yet." : introduction)
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
                            Text(address)
                        }
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        
                        MapView(coordinate: $userLocation)
                            .frame(height: 200)
                            .cornerRadius(10)
                        
                        TextField("Enter your Country", text: $countryAddress)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("Enter your City", text: $cityAddress)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button(action: updateLocation) {
                            Label("Update Location", systemImage: "location")
                        }
                        .buttonStyle(PrimaryButtonStyle())
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
            loadUserData()
            fetchUserData()
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text(""), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
            ImagePicker(image: $inputImage)
        }
        .sheet(isPresented: $showingSettingsView) {
            SettingsView()
        }
    }
    
    private var settingsButton: some View {
        Button(action: {
            showingSettingsView = true
        }) {
            Image(systemName: "gear")
                .foregroundColor(.blue)
        }
    }
    
    func loadImage() {
        guard let inputImage = inputImage else { return }
        profileImage = Image(uiImage: inputImage)
        uploadProfileImage()
    }
    
    /*func uploadProfileImage() {
        guard let inputImage = inputImage,
              let imageData = inputImage.jpegData(compressionQuality: 0.5),
              let userEmail = Auth.auth().currentUser?.email else { return }
        
        let imagePath = "profile_images/\(userEmail).jpg"
        let imageRef = storage.child(imagePath)
        
        imageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                self.alertMessage = "Error uploading image: \(error.localizedDescription)"
                self.showingAlert = true
            } else {
                imageRef.downloadURL { url, error in
                    if let downloadURL = url {
                        self.updateUserProfileImageURL(url: downloadURL.absoluteString)
                    }
                }
            }
        }
    }*/
    
    func updateUserProfileImageURL(url: String) {
        guard let userEmail = Auth.auth().currentUser?.email else { return }
        
        db.collection("users").document(userEmail).setData(["profileImageURL": url], merge: true) { error in
            if let error = error {
                self.alertMessage = "Error updating profile: \(error.localizedDescription)"
            } else {
                self.alertMessage = "Profile picture updated successfully!"
            }
            self.showingAlert = true
        }
    }
    
    
    func uploadProfileImage() {
        guard let inputImage = inputImage,
              let imageData = inputImage.jpegData(compressionQuality: 0.5),
              let userEmail = Auth.auth().currentUser?.email else { return }
        
        let imagePath = "profile_images/\(userEmail).jpg"
        let imageRef = storage.child(imagePath)
        
        // タイムアウト設定: 10秒
        let timeoutInterval: TimeInterval = 10
        
        // タイムアウト処理を設定
        let workItem = DispatchWorkItem {
            self.alertMessage = "Request timed out. Please try again."
            self.showingAlert = true
        }
        
        // タイムアウトをスケジュール
        DispatchQueue.main.asyncAfter(deadline: .now() + timeoutInterval, execute: workItem)
        
        // Firebase Storageへのアップロードリクエスト
        imageRef.putData(imageData, metadata: nil) { metadata, error in
            // タイムアウト処理が実行されないようにキャンセル
            workItem.cancel()
            
            if let error = error {
                self.alertMessage = "Error uploading image: \(error.localizedDescription)"
                self.showingAlert = true
            } else {
                imageRef.downloadURL { url, error in
                    if let downloadURL = url {
                        self.updateUserProfileImageURL(url: downloadURL.absoluteString)
                    } else if let error = error {
                        self.alertMessage = "Error getting download URL: \(error.localizedDescription)"
                        self.showingAlert = true
                    }
                }
            }
        }
    }
    
    func fetchUserData() {
        guard let user = Auth.auth().currentUser else {
            print("No user is currently logged in")
            isLoading = false
            return
        }
        print("email \(String(describing: user.email))")
        let db = Firestore.firestore()
        db.collection("users").whereField("email", isEqualTo: user.email ?? "")
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error getting documents: \(error)")
                    isLoading = false
                    return
                }
                
                guard let document = querySnapshot?.documents.first else {
                    print("No matching document")
                    isLoading = false
                    return
                }
                
                if let name = document.data()["name"] as? String {
                    self.userName = name
                }
                if let address = document.data()["location"] as? String{
                    self.address = address
                }
                if let profileImageURL = document.data()["profileImageURL"] as? String {
                    self.loadProfileImage(from: profileImageURL)
                }
                if let intro = document.data()["introduction"] as? String {
                    self.introduction = intro
                }
                
                isLoading = false
            }
    }
    
    func saveIntroduction() {
        guard let userEmail = Auth.auth().currentUser?.email else { return }
        
        db.collection("users").document(userEmail).setData(["introduction": introduction], merge: true) { error in
            if let error = error {
                self.alertMessage = "Error saving introduction: \(error.localizedDescription)"
                self.showingAlert = true
            } else {
                self.alertMessage = "Introduction saved successfully!"
                self.showingAlert = true
            }
        }
    }
    
    func loadProfileImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, let uiImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.profileImage = Image(uiImage: uiImage)
                }
            }
        }.resume()
    }
    
    func loadUserData() {
        if let user = Auth.auth().currentUser {
            self.currentUserEmail = user.email ?? "No Email"
            fetchUserLocation()
        }
    }
    
    func fetchUserLocation() {
        guard let userEmail = Auth.auth().currentUser?.email else { return }
        
        db.collection("users").document(userEmail).getDocument { document, error in
            if let document = document, document.exists {
                if let latitude = document.data()?["latitude"] as? Double,
                   let longitude = document.data()?["longitude"] as? Double {
                    self.userLocation = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    self.region.center = self.userLocation
                }
                if let savedAddress = document.data()?["address"] as? String {
                    self.address = savedAddress
                }
            }
        }
    }
    
    func updateLocation() {
        address = countryAddress + " " + cityAddress
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, error in
            if let error = error {
                self.alertMessage = "Error: \(error.localizedDescription)"
                self.showingAlert = true
                return
            }
            
            guard let placemark = placemarks?.first,
                  let location = placemark.location else {
                self.alertMessage = "Could not find location for the given address."
                self.showingAlert = true
                return
            }
            
            self.userLocation = location.coordinate
            self.region.center = self.userLocation
            
            saveLocationToFirestore(location: location.coordinate)
        }
    }
    
    func saveLocationToFirestore(location: CLLocationCoordinate2D) {
        guard let userEmail = Auth.auth().currentUser?.email else { return }
        
        let userData: [String: Any] = [
            "latitude": location.latitude,
            "longitude": location.longitude,
            "location": address
        ]
        
        db.collection("users").document(userEmail).setData(userData, merge: true) { error in
            if let error = error {
                self.alertMessage = "Error saving location: \(error.localizedDescription)"
            } else {
                self.alertMessage = "Location updated successfully!"
            }
            self.showingAlert = true
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            dismiss()
            //self.isSignedIn = false
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
        }
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

