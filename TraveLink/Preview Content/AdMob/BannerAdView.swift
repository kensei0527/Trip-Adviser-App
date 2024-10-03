//
//  AdMobViewModel.swift
//  TraveLink
//
//  Created by 古家健成 on 2024/09/17.
//

import GoogleMobileAds
import SwiftUI

struct AdMobBannerView: UIViewRepresentable {
    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: GADAdSizeBanner)
        banner.adUnitID = "ca-app-pub-1177185329132479/4035029727" // ここにあなたの広告ユニットIDを入力してください
        banner.rootViewController = UIApplication.shared.getRootViewController()
        banner.load(GADRequest())
        return banner
    }
    
    func updateUIView(_ uiView: GADBannerView, context: Context) {
        // 必要に応じてビューを更新
    }
}

extension UIApplication {
    func getRootViewController() -> UIViewController? {
        guard let screen = connectedScenes.first as? UIWindowScene else { return nil }
        return screen.windows.first { $0.isKeyWindow }?.rootViewController
    }
}
