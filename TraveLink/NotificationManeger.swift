//
//  NotificationManeger.swift
//  TraveLink
//
//  Created by 古家健成 on 2024/08/31.
//


import Firebase
import FirebaseFunctions

class PushNotificationSender {
    // シングルトンインスタンス
    static let shared = PushNotificationSender()
    private init() {}
    
    // Firebase Functionsのインスタンスを遅延初期化
    private lazy var functions = Functions.functions()
    
    func sendPushNotification(to token: String, userId: String, title: String, body: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Cloud Functionに送信するデータを準備
        let data: [String: Any] = [
            "token": token,
            "userId": userId,
            "title": title,
            "body": body
        ]
        
        // Cloud Functionを呼び出し
        functions.httpsCallable("sendPushNotification").call(data) { result, error in
            if let error = error {
                // エラーが発生した場合、completion handlerにエラーを渡す
                completion(.failure(error))
                return
            }
            
            // 成功した場合、messageIdを取得してcompletion handlerに渡す
            if let data = result?.data as? [String: Any], let messageId = data["messageId"] as? String {
                completion(.success(messageId))
            } else {
                // レスポンスが期待した形式でない場合、エラーを生成
                completion(.failure(NSError(domain: "PushNotificationSender", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response from server"])))
            }
        }
    }
}
