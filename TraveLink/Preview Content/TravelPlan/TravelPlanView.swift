//
//  TravelPlanView.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/07/14.
//

// TripViews.swift

import SwiftUI
import Firebase



struct TravelPlanView: View {
    @StateObject private var viewModel = TripViewModel()
    @StateObject private var userFetchModel = UserFetchModel()
    @State private var showingAddTrip = false
    @State private var showingAddEditor = false
    @State private var newTripTitle = ""
    @State private var selectedTrip: Trip?
    @State private var editMode: EditMode = .inactive
    @State private var showCompletedTrips = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.blue.opacity(0.1).edgesIgnoringSafeArea(.all)
                VStack {
                    Picker("Trip Status", selection: $showCompletedTrips) {
                        Text("Active").tag(false)
                        Text("Completed").tag(true)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    if(showCompletedTrips == false){
                        Text("Plan your new trip!")
                            .padding()
                            .fontWeight(.bold)
                    }
                    List {
                        ForEach(showCompletedTrips ? viewModel.completedTrips : viewModel.incompleteTrips) { trip in
                            if editMode == .inactive {
                                NavigationLink(destination: TripDetailView(viewModel: viewModel, userList: userFetchModel.useredFollowers, trip: trip)
                                ) {
                                    TripCard(trip: trip)
                                }
                            } else {
                                TripCard(trip: trip)
                            }
                        }
                        .onDelete(perform: deleteTrips)
                    }
                    .listStyle(PlainListStyle())
                    
                }
            }
            .navigationTitle(showCompletedTrips ? "Completed Trips" : "Active Trips")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await userFetchModel.fetchFollowUser()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !showCompletedTrips {
                        Button(action: { showingAddTrip = true }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if !showCompletedTrips {
                        EditButton()
                    }
                }
            }
            .environment(\.editMode, $editMode)
        }
        .accentColor(.blue)
        .onAppear {
            viewModel.fetchTrips()
        }
        .sheet(isPresented: $showingAddTrip) {
            AddTripView(viewModel: viewModel, isPresented: $showingAddTrip)
        }
    }
    
    private func deleteTrips(at offsets: IndexSet) {
        offsets.forEach { index in
            let trip = viewModel.trips[index]
            viewModel.deleteTrip(trip)
        }
    }
}



struct AddTripView: View {
    @ObservedObject var viewModel: TripViewModel
    @Binding var isPresented: Bool
    @State private var title = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(86400) // Default to next day
    @State private var showStartDatePicker = false
    @State private var showEndDatePicker = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Trip Details")) {
                    TextField("Trip Title", text: $title)
                }
                
                Section(header: Text("Travel Period")) {
                    DateSelectionRow(title: "Start Date",
                                     date: $startDate,
                                     showPicker: $showStartDatePicker)
                    
                    if showStartDatePicker {
                        DatePicker("", selection: $startDate, displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .frame(maxHeight: 400)
                    }
                    
                    DateSelectionRow(title: "End Date",
                                     date: $endDate,
                                     showPicker: $showEndDatePicker)
                    
                    if showEndDatePicker {
                        DatePicker("", selection: $endDate, in: startDate..., displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .frame(maxHeight: 400)
                    }
                }
            }
            .navigationTitle("New Trip")
            .navigationBarItems(
                leading: Button("Cancel") { isPresented = false },
                trailing: Button("Add") {
                    viewModel.addTrip(title: title, startDate: startDate, endDate: endDate)
                    isPresented = false
                }
                    .disabled(title.isEmpty || endDate < startDate)
            )
        }
    }
}

struct DateSelectionRow: View {
    let title: String
    @Binding var date: Date
    @Binding var showPicker: Bool
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(dateFormatter.string(from: date))
                .foregroundColor(.blue)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            showPicker.toggle()
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }
}




