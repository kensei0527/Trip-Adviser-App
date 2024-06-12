//
//  Research.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/06/12.
//

import SwiftUI

import UIKit

struct CountryView: View {
    // 国の名前を含む配列
    let countries = ["Japan", "USA", "Germany", "France", "Italy"]
    
    var body: some View {
        // 各国の名前を表示するVStack
        VStack {
            ForEach(countries, id: \.self) { country in
                // 各国ごとに表示するStack
                VStack {
                    Text(country)
                        .font(.largeTitle)
                        .padding()
                    // その他のカスタムViewやコンポーネントをここに追加可能
                }
                .background(Color.blue.opacity(0.1)) // 各国ごとに背景色を設定
                .cornerRadius(10)
                .padding(.vertical, 5)
            }
        }
        .padding()
    }
}

/*truct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}*/

#Preview{
    CountryView()
}
