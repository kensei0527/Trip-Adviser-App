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
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.blue.opacity(0.1).edgesIgnoringSafeArea(.all)
                
                List {
                    ForEach(viewModel.trips) { trip in
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
            .navigationTitle("Travel Plans")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await userFetchModel.fetchFollowUser()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTrip = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
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

struct TripCard: View {
    let trip: Trip
    let cardColor = Color("Card")
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(trip.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                Text(dateRangeText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.blue)
                Text(durationText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Image(systemName: "person.3")
                    .foregroundColor(.blue)
                Text("Participants: \(trip.participants.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(cardColor)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var dateRangeText: String {
        let start = formattedDate(trip.startDate)
        let end = formattedDate(trip.endDate)
        return "\(start) - \(end)"
    }
    
    private var durationText: String {
        let days = Calendar.current.dateComponents([.day], from: trip.startDate, to: trip.endDate).day ?? 0
        return "\(days) day\(days == 1 ? "" : "s")"
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
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




