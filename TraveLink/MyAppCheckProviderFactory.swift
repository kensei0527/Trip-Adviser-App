//
//  MyAppCheckProviderFactory.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/08/19.
//

import Firebase

class YourAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        //return AppAttestProvider(app: app)
#if DEBUG
        return AppCheckDebugProvider(app: app)
#else
        // 本番環境用のProvider（例：DeviceCheckProvider）を返す
        //return DeviceCheckProvider(app: app)
        return AppAttestProvider(app: app)
#endif
    }
}


