//
//  NationScreen.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/06/06.
//

import SwiftUI
import FirebaseAuth

struct NationScreen: View {
    let countryname: String
    @StateObject private var viewModel: NationScreenModel
    
    init(countryName: String) {
        self.countryname = countryName
        self._viewModel = StateObject(wrappedValue: NationScreenModel(countryName: countryName))
    }
    
    var body: some View {
        VStack {
            Text(viewModel.countryName)
            ForEach(viewModel.matchingDocumentIDs, id: \.self) { matchUser in
                Text(matchUser)
            }
        }
    }
}
