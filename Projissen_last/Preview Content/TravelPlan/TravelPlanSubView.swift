//
//  TravelPlanSubView.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/07/15.
//

import SwiftUI

struct ActivityRow: View {
    let activity: Activity
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(activity.type.rawValue)
                .font(.headline)
            Text(activity.description)
                .font(.subheadline)
            HStack {
                Text(formatTime(activity.startTime))
                Text("-")
                Text(formatTime(activity.endTime))
            }
            .font(.caption)
            Text("Required Time: \(formatDuration(activity.duration))")
                .font(.caption)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h\(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct AddActivityView: View {
    @ObservedObject var viewModel: TripViewModel
    let trip: Trip
    @Binding var isPresented: Bool
    @State private var type: ActivityType = .sightseeing
    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(3600)
    @State private var description = ""
    
    var body: some View {
        NavigationView {
            Form {
                Picker("Type", selection: $type) {
                    ForEach(ActivityType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                DatePicker("Start Time", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                DatePicker("End Time", selection: $endTime, displayedComponents: [.date, .hourAndMinute])
                TextField("Detail", text: $description)
            }
            .navigationTitle("New Item")
            .navigationBarItems(
                leading: Button("Cancel") { isPresented = false },
                trailing: Button("Add") {
                    viewModel.addActivity(to: trip, type: type, startTime: startTime, endTime: endTime, description: description)
                    isPresented = false
                }
            )
        }
    }
}

struct EditActivityView: View {
    @ObservedObject var viewModel: TripViewModel
    let trip: Trip
    let activity: Activity
    @Binding var isPresented: Bool
    @State private var type: ActivityType
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var description: String
    
    init(viewModel: TripViewModel, trip: Trip, activity: Activity, isPresented: Binding<Bool>) {
        self.viewModel = viewModel
        self.trip = trip
        self.activity = activity
        self._isPresented = isPresented
        self._type = State(initialValue: activity.type)
        self._startTime = State(initialValue: activity.startTime)
        self._endTime = State(initialValue: activity.endTime)
        self._description = State(initialValue: activity.description)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Picker("Type", selection: $type) {
                    ForEach(ActivityType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                DatePicker("Start Time", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                DatePicker("End Time", selection: $endTime, displayedComponents: [.date, .hourAndMinute])
                TextField("Detail", text: $description)
            }
            .navigationTitle("Edit")
            .navigationBarItems(
                leading: Button("Cancel") { isPresented = false },
                trailing: Button("Save") {
                    viewModel.updateActivity(activity, in: trip, type: type, startTime: startTime, endTime: endTime, description: description)
                    isPresented = false
                }
            )
        }
    }
}
