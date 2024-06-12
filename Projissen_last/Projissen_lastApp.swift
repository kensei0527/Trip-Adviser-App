//
//  Projissen_lastApp.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/06/05.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct Projissen_lastApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State var authHandle: AuthStateDidChangeListenerHandle?
    @StateObject private var viewModel = AuthViewModel()
    

    //FirebaseApp.configure()
    var body: some Scene {
        WindowGroup {
        //AuthViewController()
            /*let _ = authHandle = Auth.auth().addStateDidChangeListener({ (auth, user) in
                if Auth.auth().currentUser != nil {
                    // User is signed in.
                    let _ = HomeScreen()
                } else {
                    // No user is signed in.
                    let _ = AuthenScreen()
                }
            })*/
            //HomeScreen()
            AuthenScreen().environmentObject(viewModel)
            
        }
    }
}
