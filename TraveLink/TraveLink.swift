//
//  Projissen_lastApp.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/06/05.
//

import SwiftUI
import Firebase
import UserNotifications
import FirebaseMessaging
import FirebaseCore



class AppDelegate: NSObject, UIApplicationDelegate{
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        let providerFactory = YourAppCheckProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        FirebaseApp.configure()
        
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        
        // Push通知許可のポップアップを表示
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, _ in
            guard granted else { return }
            /*DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }*/
        }
        application.registerForRemoteNotifications()
        return true
    }
    
    // テスト通知に必要なFCMトークンを出力する
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // set firebase apns token
        
        Messaging.messaging().apnsToken = deviceToken
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error fetching FCM registration token: \(error)")
            } else if let token = token {
                print("FCM registration token: \(token)")
            }
        }
    }
}

extension AppDelegate: MessagingDelegate {}

// MARK: - AppDelegate Push Notification
extension AppDelegate: UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if let messageID = userInfo["gcm.message_id"] {
            print("MessageID: \(messageID)")
        }
        print(userInfo)
        completionHandler(.newData)
    }
    
    // アプリがForeground時にPush通知を受信する処理
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        if let uid = Auth.auth().currentUser?.uid {
            setFcmToken(fcmToken: fcmToken)
        }
    }
    
    func setFcmToken(fcmToken: String){
        guard let userEmail = Auth.auth().currentUser?.email else {
            print("Error: No authenticated user found")
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userEmail)
        
        userRef.setData(["fcm": fcmToken], merge: true) { error in
            if let error = error {
                print("Error saving FCM token: \(error.localizedDescription)")
            } else {
                print("FCM token successfully saved for user: \(userEmail)")
            }
        }
    }

}

@main
struct TraveLink: App {
    // register app delegate for Firebase setup
    //@UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @UIApplicationDelegateAdaptor var delegate: AppDelegate
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
