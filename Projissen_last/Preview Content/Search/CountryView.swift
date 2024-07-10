//
//  Research.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/06/12.
//

import SwiftUI
import FirebaseFirestore

struct CountryView: View {
    @StateObject private var viewModel = CountryViewModel()
    @State private var showingAlert = false
    @State private var newCountryName = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(viewModel.countries, id: \.self) { country in
                        NavigationLink(destination: NationScreen(countryName: country)) {
                            CountryCard(countryName: country, width: .infinity, height: 200)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Explore Countries")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAlert = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .alert("Add New Country", isPresented: $showingAlert) {
            TextField("Country Name", text: $newCountryName)
            Button("Cancel", role: .cancel) { }
            Button("Add") {
                if !newCountryName.isEmpty {
                    viewModel.addCountry(name: newCountryName)
                    newCountryName = ""
                }
            }
        } message: {
            Text("Enter the name of the country")
        }
    }
}

struct CountryCard: View {
    let countryName: String
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        ZStack {
            Image("placeholder_\(countryName.lowercased())")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: width, height: height)
                .clipped()
                .cornerRadius(20)
            
            VStack {
                Spacer()
                Text(countryName)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(10)
            }
        }
        .cornerRadius(20)
        .shadow(radius: 10)
    }
}

struct CountryView_Previews: PreviewProvider {
    static var previews: some View {
        CountryView()
    }
}
