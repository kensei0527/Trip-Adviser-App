//
//  ProviderFactory.swift
//  TraveLink
//
//  Created by 古家健成 on 2024/09/10.
//

import Firebase
import FirebaseAppCheck

class YourAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
#if DEBUG
        return AppCheckDebugProvider(app: app)
#else
        // 本番環境用のProvider（例：DeviceCheckProvider）を返す
        return DeviceCheckProvider(app: app)
#endif
    }
}
