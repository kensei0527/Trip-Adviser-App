//
//  TravelPlanView.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/07/14.
//

// TripViews.swift

import SwiftUI
import Firebase

import SwiftUI

struct TravelPlanView: View {
    @StateObject private var viewModel = TripViewModel()
    @StateObject private var userFetchModel = UserFetchModel()
    @State private var showingAddTrip = false
    @State private var showingAddEditor = false
    @State private var newTripTitle = ""
    @State private var selectedTrip: Trip?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.blue.opacity(0.1).edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(viewModel.trips) { trip in
                            NavigationLink(destination: TripDetailView(viewModel: viewModel, userList: userFetchModel.useredFollowers, trip: trip)) {
                                TripCard(trip: trip)
                            }
                        }
                    }
                    .padding()
                }
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
                        .foregroundColor(.blue)
                }
            }
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
        .background(Color.white)
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
struct TripDetailView: View {
    @ObservedObject var viewModel: TripViewModel
    @StateObject var userFetchModel = UserFetchModel()
    var userList: [User]
    let trip: Trip
    @State private var showingAddActivity = false
    @State private var showingAddEditor = false
    @State private var selectedActivity: Activity?
    
    func sectionFor() -> some View{
        ForEach(groupedActivities, id: \.0) { date, activities in
            Section(header: Text(formatDate(date))) {
                ForEach(activities) { activity in
                    TimelineItemView(activity: activity, isLastActivity: activity == activities.last) {
                        selectedActivity = activity
                    }
                }
                .onDelete { indexSet in
                 deleteActivities(at: indexSet, for: date)
                 }
            }
        }
    }
    
    var body: some View {
        List {
            sectionFor()
        }
        
        .listStyle(PlainListStyle())
        .navigationTitle(trip.title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingAddActivity = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .toolbar{
            NavigationLink(destination: AddTripEditerView(trip: trip, userlist: userList){ newEditors in
                print(trip.title)
                viewModel.addEditors(to: trip, editors: newEditors)
            }){
                Image(systemName: "person.3.sequence")
            }
        }
        .onAppear {
            viewModel.fetchActivities(for: trip)
        }
        .sheet(isPresented: $showingAddActivity) {
            AddActivityView(viewModel: viewModel, trip: trip, isPresented: $showingAddActivity)
        }
        .sheet(item: $selectedActivity) { activity in
            EditActivityView(viewModel: viewModel, trip: trip, activity: activity, isPresented: Binding(
                get: { selectedActivity != nil },
                set: { if !$0 { selectedActivity = nil } }
            ))
        }
        
    }
    
    private var groupedActivities: [(Date, [Activity])] {
        let grouped = Dictionary(grouping: trip.activities) { activity in
            Calendar.current.startOfDay(for: activity.startTime)
        }
        return grouped.sorted { $0.key < $1.key }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日 (EEEEE)"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    private func deleteActivities(at offsets: IndexSet, for date: Date) {
        let activitiesForDate = groupedActivities.first { $0.0 == date }?.1 ?? []
        offsets.forEach { index in
            let activity = activitiesForDate[index]
            viewModel.deleteActivity(activity, from: trip)
        }
    }
}

struct TimelineItemView: View {
    let activity: Activity
    let isLastActivity: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            VStack(spacing: 0) {
                Image(systemName: iconForType(activity.type))
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(colorForType(activity.type))
                    .clipShape(Circle())
                
                if !isLastActivity {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2, height: 40)
                }
            }
            
            VStack(alignment: .leading, spacing: 5) {
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
                Text("所要時間: \(formatDuration(activity.duration))")
                    .font(.caption)
            }
        }
        .padding(.vertical, 8)
        //.background(Color.white)
        .onTapGesture(perform: onTap)
    }
    
    private func iconForType(_ type: ActivityType) -> String {
        switch type {
        case .travel:
            return "airplane"
        case .sightseeing:
            return "binoculars.fill"
        case .hotel:
            return "bed.double.fill"
        }
    }
    
    private func colorForType(_ type: ActivityType) -> Color {
        switch type {
        case .travel:
            return .blue
        case .sightseeing:
            return .green
        case .hotel:
            return .orange
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

struct AddTripEditerView: View {
    @StateObject private var userFetchModel = UserFetchModel()
    @State private var selectedUsers: Set<String> = []
    var trip: Trip
    var userlist: [User]
    var onComplete: ([String]) -> Void
    
    
    
    var body: some View {
        
        
        
        List(userlist) { user in
            HStack {
                AsyncImage(url: user.profileImageURL) { image in
                    image.resizable()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                
                VStack(alignment: .leading) {
                    Text(user.name)
                        .font(.headline)
                    Text(user.email)
                        .font(.subheadline)
                        //.foreground(Color.gray)
                }
                
                Spacer()
                
                if selectedUsers.contains(user.id) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            
            .onTapGesture {
                if selectedUsers.contains(user.id) {
                    selectedUsers.remove(user.id)
                } else {
                    selectedUsers.insert(user.id)
                }
            }
        }
        
        //.onAppear(perform: userFetchModel.fetchFollowUser)
        .task{
            print("onappear")
            await userFetchModel.fetchFollowUser()
            print(userFetchModel.useredFollowers)
        }
        .navigationTitle("Add New Editor: \(trip.title)")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    let newEditors = Array(selectedUsers)
                    onComplete(newEditors)
                    
                }
            }
        }
        .toolbar{
            ToolbarItem(placement: .topBarTrailing){
                Button(action: {
                    Task {
                        await userFetchModel.fetchFollowUser()
                    }},
                       label: {
                    Image(systemName: "arrow.clockwise")
                })
            }
        }
    }
        
}


