//
//  PlanEditView.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/08/18.
//

import SwiftUI
import Firebase

struct TripDetailView: View {
    @ObservedObject var viewModel: TripViewModel
    @StateObject var userFetchModel = UserFetchModel()
    @StateObject var sharedState = SharedTripEditorState()
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
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { sharedState.toggleEditMode() }) {
                    Image(systemName: sharedState.isEditMode ? "pencil.slash" : "pencil")
                }
            }
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
        .environmentObject(sharedState)
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
                Text("Duration: \(formatDuration(activity.duration))")
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
        case .breakfast:
            return "fork.knife.circle.fill"
        case .lunch:
            return "fork.knife.circle.fill"
        case .dinner:
            return "fork.knife.circle.fill"
        }
    }
    
    private func colorForType(_ type: ActivityType) -> Color {
        switch type {
        case .travel:
            return .blue
        case .sightseeing:
            return .green
        case .hotel:
            return .gray
        case .breakfast:
            return .yellow
        case .lunch:
            return .orange
        case .dinner:
            return .red
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
    @Environment(\.dismiss) var dismiss
    @StateObject private var userFetchModel = UserFetchModel()
    @EnvironmentObject var sharedState: SharedTripEditorState
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
                }
                
                Spacer()
                
                if sharedState.selectedUsers.contains(user.id) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .onTapGesture {
                sharedState.toggleUserSelection(user.id)
            }
        }
        .task {
            await userFetchModel.fetchFollowUser()
        }
        .navigationTitle("Add New Editor: \(trip.title)")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    let newEditors = Array(sharedState.selectedUsers)
                    onComplete(newEditors)
                    sharedState.clearSelections()
                    dismiss()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    Task {
                        await userFetchModel.fetchFollowUser()
                    }
                }, label: {
                    Image(systemName: "arrow.clockwise")
                })
            }
        }
    }
}
