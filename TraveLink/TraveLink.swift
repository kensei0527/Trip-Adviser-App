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
import GoogleMobileAds
import AppTrackingTransparency
import AdSupport



class AppDelegate: NSObject, UIApplicationDelegate{
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        let providerFactory = YourAppCheckProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        FirebaseApp.configure()
        
        // Initialize the Google Mobile Ads SDK.
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [ "ec3dc8a266ff0bb71d1006100a2b4bbc" ]
        
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        
        // Push通知許可のポップアップを表示
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
        //application.registerForRemoteNotifications()
        
        // 追跡許可のリクエストを少し後に呼び出す（通知許可後にリクエスト）
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {  // 通知許可リクエストから10秒後に呼び出し
            self.requestTrackingAuthorization()
        }
        
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
    
    //ATT対応
    func requestTrackingAuthorization() {
        if #available(iOS 14, *) {
            // App Tracking Transparencyのステータスを確認
            ATTrackingManager.requestTrackingAuthorization { status in
                switch status {
                case .authorized:
                    // ユーザーが追跡を許可した場合
                    print("Tracking authorized")
                    // IDFAの取得
                    let idfa = ASIdentifierManager.shared().advertisingIdentifier
                    print("IDFA: \(idfa)")
                case .denied:
                    // ユーザーが追跡を拒否した場合
                    print("Tracking denied")
                case .restricted:
                    // 機能が制限されている場合
                    print("Tracking restricted")
                case .notDetermined:
                    // ユーザーがまだ選択していない場合
                    print("Tracking not determined")
                @unknown default:
                    // 不明な場合
                    print("Unknown tracking authorization status")
                }
            }
        } else {
            // iOS 14未満のデバイスでは、IDFAは自動的に利用可能
            let idfa = ASIdentifierManager.shared().advertisingIdentifier
            print("IDFA: \(idfa)")
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
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    //@UIApplicationDelegateAdaptor var delegate: AppDelegate
    @State var authHandle: AuthStateDidChangeListenerHandle?
    @StateObject private var viewModel = AuthViewModel()
    @StateObject private var sharedState = SharedTripEditorState()
    //@AppStorage("isFirstLaunch") private var isFirstLaunch: Bool = true
    

    //FirebaseApp.configure()
    var body: some Scene {
        WindowGroup {
            AuthenScreen()
                .environmentObject(viewModel)
                .environmentObject(sharedState) //旅程管理のところで使う環境変数PlanEditViewで使用
                
            
        }
    }
    
   
}
