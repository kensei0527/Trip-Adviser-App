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
    
    func onAppear() async{
        
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.trips) { trip in
                    NavigationLink(destination: TripDetailView(viewModel: viewModel,userList: userFetchModel.useredFollowers, trip: trip)) {
                        Text(trip.title)
                    }
                    
                }
                .onDelete(perform: deleteTrips)
            }
            .navigationTitle("Trip List")
            
            .task {
                await userFetchModel.fetchFollowUser()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTrip = true }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
        }
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
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Trip Title", text: $title)
            }
            .navigationTitle("New Trip")
            .navigationBarItems(
                leading: Button("Cancel") { isPresented = false },
                trailing: Button("Add") {
                    viewModel.addTrip(title: title)
                    isPresented = false
                }
            )
        }
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
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
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
        
        /*Button(action: userFetchModel.fetchFollowUser, label: {
            /*@START_MENU_TOKEN@*/Text("Button")/*@END_MENU_TOKEN@*/
        })*/
        
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
            //userFetchModel.fetchFollowUser()
            print(userFetchModel.useredFollowers)
        }
        .navigationTitle("共同編集者を追加: \(trip.title)")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("完了") {
                    let newEditors = Array(selectedUsers)
                    onComplete(newEditors)
                    
                }
            }
        }
    }
        
}


