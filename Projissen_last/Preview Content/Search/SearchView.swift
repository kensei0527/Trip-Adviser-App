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
        VStack {
            ScrollView {
                VStack {
                    ForEach(viewModel.countries, id: \.self) { country in
                        /*VStack {
                            Text(country)
                                .font(.largeTitle)
                                .padding()
                        }
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.vertical, 5)
                         */
                        
                        NavigationLink(destination: NationScreen(), label: {ZStack {
                            
                            GridRow{
                                RoundedRectangle(cornerSize: .init(width: 20, height: 20))
                                    .frame(width: 150, height: 150)
                                
                            }.zIndex(1)
                            Text(country).zIndex(2).foregroundColor(.black)
                        }})
                    }
                }
                .padding()
            }
            
            Button(action: {
                showingAlert = true
                //ViewController()
            }) {
                Text("Add Country")
                    .font(.title2)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
            .cornerRadius(10)
            }
            /*.alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Add New Country"),
                    message: Text("Enter the name of the country"),
                    primaryButton: .default(Text("Add"), action: {
                        if !newCountryName.isEmpty {
                            viewModel.addCountry(name: newCountryName)
                            newCountryName = ""
                        }
                    }),
                    secondaryButton: .cancel()
                )
            }*/
            .padding()
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
