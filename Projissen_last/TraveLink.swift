//
//  Projissen_lastApp.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/06/05.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import Firebase



class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        let providerFactory = YourAppCheckProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        FirebaseApp.configure()
        return true
    }
}

@main
struct TraveLink: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State var authHandle: AuthStateDidChangeListenerHandle?
    @StateObject private var viewModel = AuthViewModel()
    @StateObject private var sharedState = SharedTripEditorState()
    

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
            AuthenScreen()
                .environmentObject(viewModel)
                .environmentObject(sharedState) //旅程管理のところで使う環境変数PlanEditViewで使用
            
        }
    }
}
