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
            VStack {
                ScrollView {
                    VStack {
                        ForEach(viewModel.countries, id: \.self) { country in
                            NavigationLink(destination: NationScreen()) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.blue.opacity(0.1))
                                        .frame(height: 150)
                                    
                                    Text(country)
                                        .foregroundColor(.black)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 5)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Search")
            .navigationBarItems(trailing:
                                    Button(action: {
                showingAlert = true
            }) {
                Image(systemName: "plus")
                    .foregroundColor(.blue)
            }
            )
        }
        .textFieldAlert(isPresented: $showingAlert, text: $newCountryName)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        CountryView()
    }
}

// Extension to show an alert with a TextField
struct TextFieldAlert<Presenting>: View where Presenting: View {
    @StateObject private var viewModel = CountryViewModel()
    @Binding var isPresented: Bool
    @Binding var text: String
    let presenting: Presenting
    let title: String
    let message: String
    
    var body: some View {
        NavigationStack {
            ZStack {
                presenting
                    .blur(radius: isPresented ? 2 : 0)
                if isPresented {
                    VStack {
                        Text(title).font(.headline)
                        Text(message).font(.subheadline)
                        TextField("", text: $text)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                        HStack {
                            Button("Cancel") {
                                withAnimation {
                                    isPresented = false
                                }
                            }
                            .padding()
                            //Spacer()
                            Button("OK") {
                                viewModel.addCountry(name: text)
                                withAnimation {
                                    isPresented = false
                                }
                            }
                            .padding()
                        }
                        .padding()
                    }
                    .frame(width: 300, height: 230)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 20)
                    .transition(.scale)
                    .zIndex(1)
                }
            }
        }
    }
}

extension View {
    func textFieldAlert(isPresented: Binding<Bool>, text: Binding<String>) -> some View {
        TextFieldAlert(isPresented: isPresented, text: text, presenting: self, title: "Add New Country", message: "Enter the name of the country")
    }
}
