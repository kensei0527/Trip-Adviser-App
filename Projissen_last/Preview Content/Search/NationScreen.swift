//
//  NationScreen.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/06/06.
//

import SwiftUI
import FirebaseAuth

struct NationScreen : View {
    var body: some View {
        Text("Hello")
        Button(action: {signOut()}, label: {Text("signout")})
    }
    func signOut() {
        do {
            try Auth.auth().signOut()
            //self.isSignedIn = false
        } catch let signOutError as NSError {
            print("Error signing out: \(signOutError.localizedDescription)")
        }
    }

}
