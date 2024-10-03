//
//  MyTipView.swift
//  TraveLink
//
//  Created by 古家健成 on 2024/09/17.
//

import SwiftUI
import Firebase

struct MyTipsView: View {
    @ObservedObject var viewModel = TravelTipViewModel()
    @State private var showingEditView = false
    @State private var selectedTip: TravelTip?
    @State private var showingDeleteConfirmation = false
    @State private var currentUserEmail: String = Auth.auth().currentUser?.email ?? ""
    
    var body: some View {
        List {
            ForEach(viewModel.tips.filter { $0.authorId == currentUserEmail }) { tip in
                VStack(alignment: .leading) {
                    Text(tip.title)
                        .font(.headline)
                    Text(tip.content)
                        .lineLimit(2)
                        .font(.subheadline)
                    HStack {
                        Spacer()
                        Button(action: {
                            selectedTip = tip
                            showingEditView = true
                        }) {
                            Text("編集")
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .padding(.trailing)
                        
                        Button(action: {
                            selectedTip = tip
                            showingDeleteConfirmation = true
                        }) {
                            Text("削除")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
                .padding()
            }
        }
        .onAppear {
            viewModel.fetchTips()
        }
        .sheet(isPresented: $showingEditView) {
            if let tip = selectedTip {
                EditTipView(tip: tip, viewModel: viewModel)
            }
        }
        .alert(isPresented: $showingDeleteConfirmation) {
            Alert(
                title: Text("投稿の削除"),
                message: Text("この投稿を削除しますか？"),
                primaryButton: .destructive(Text("削除")) {
                    if let tip = selectedTip {
                        viewModel.deleteTip(tip)
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
}
