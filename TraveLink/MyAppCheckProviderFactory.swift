//
//  MyAppCheckProviderFactory.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/08/19.
//

import Firebase

class YourAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        return AppAttestProvider(app: app)
    }
}


