//
//  CompletePlanView.swift
//  TraveLink
//
//  Created by 古家健成 on 2024/09/14.
//

import SwiftUI
import Firebase

struct CompletedTripsView: View {
    @ObservedObject var viewModel: TripViewModel
    @State private var showingTripDetail = false
    @State private var selectedTrip: Trip?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.completedTrips) { trip in
                    CompletedTripCard(trip: trip)
                        .onTapGesture {
                            selectedTrip = trip
                            showingTripDetail = true
                        }
                }
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Completed Trips")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.fetchTrips()
            }
            .sheet(isPresented: $showingTripDetail) {
                if let trip = selectedTrip {
                    CompletedTripDetailView(viewModel: viewModel, trip: trip)
                }
            }
        }
    }
}

struct CompletedTripCard: View {
    let trip: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(trip.title)
                .font(.headline)
            HStack {
                Image(systemName: "calendar")
                Text("\(formatDate(trip.startDate)) - \(formatDate(trip.endDate))")
                    .font(.subheadline)
            }
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Completed")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct CompletedTripDetailView: View {
    @ObservedObject var viewModel: TripViewModel
    let trip: Trip
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Trip Details")) {
                    Text("Title: \(trip.title)")
                    Text("Start Date: \(formatDate(trip.startDate))")
                    Text("End Date: \(formatDate(trip.endDate))")
                    Text("Participants: \(trip.participants.joined(separator: ", "))")
                }
                
                Section(header: Text("Activities")) {
                    ForEach(trip.activities) { activity in
                        VStack(alignment: .leading) {
                            Text(activity.description)
                                .font(.headline)
                            Text("\(formatTime(activity.startTime)) - \(formatTime(activity.endTime))")
                                .font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle("Trip Details")
            .navigationBarItems(trailing: Button("Reopen") {
                reopenTrip()
            })
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func reopenTrip() {
        Task {
            do {
                try await viewModel.updateTripCompletionStatus(for: trip, isCompleted: false){ _ in
                    return
                }
                presentationMode.wrappedValue.dismiss()
            } catch {
                print("Error reopening trip: \(error.localizedDescription)")
            }
        }
    }
}
