//
//  TimeLineView.swift
//  TraveLink
//
//  Created by 古家健成 on 2024/09/16.
//

import SwiftUI
import Firebase
import GoogleMobileAds



struct TimelineView: View {
    @StateObject var viewModel = TravelTipViewModel()
    @State private var showCreateTipView = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Array(viewModel.tips.enumerated()), id: \.element.id) { index, tip in
                    NavigationLink(destination: TipDetailView(tip: tip).environmentObject(viewModel)) {
                        TipRowView(tip: tip)
                            .padding(.vertical, 8)
                            .listRowInsets(EdgeInsets())
                            .background(Color(.systemBackground))
                    }
                    .onAppear {
                        if index == viewModel.tips.count - 1 {
                            viewModel.fetchMoreTips()
                        }
                    }
                    
                    // 5つごとに広告を挿入
                    if index % 5 == 4 {
                        AdMobBannerView()
                            .frame(height: 50)
                            .listRowInsets(EdgeInsets())
                            .background(Color(.systemBackground))
                    }
                }
                
                if viewModel.isFetching && viewModel.hasMoreData {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .listRowInsets(EdgeInsets())
                    .background(Color(.systemBackground))
                } else if !viewModel.hasMoreData {
                    HStack {
                        Spacer()
                        Text("No further postings")
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .listRowInsets(EdgeInsets())
                    .background(Color(.systemBackground))
                }
            }
            .listStyle(PlainListStyle())
            .navigationTitle("TimeLine")
            .navigationBarItems(trailing: Button(action: {
                showCreateTipView = true
            }) {
                Image(systemName: "plus")
            })
            .onAppear {
                if viewModel.tips.isEmpty {
                    viewModel.fetchInitialTips()
                }
            }
            .sheet(isPresented: $showCreateTipView) {
                CreateTipView()
                    .environmentObject(viewModel)
            }
        }
        .environmentObject(viewModel)
    }
}
