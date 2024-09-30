//
//  PlanEditView.swift
//  Projissen_last
//
//  Created by 古家健成 on 2024/08/18.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct TripDetailView: View {
    @ObservedObject var viewModel: TripViewModel
    @StateObject var userFetchModel = UserFetchModel()
    @StateObject var sharedReviewState = UserReviewViewModel()
    //@StateObject var sharedState = SharedTripEditorState()
    var userList: [User]
    let trip: Trip
    @State var reviewedUser: String = ""
    @State private var showingAddActivity = false
    @State private var showingAddEditor = false
    @State private var selectedActivity: Activity?
    @State private var isTripCompleted = false
    @State private var newEditors: [String: UserRole] = [:]
    
    @Environment(\.presentationMode) var presentationMode
    
    
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
        NavigationStack {
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
                    Button(action: {
                        showingAddEditor = true
                    }) {
                        Image(systemName: "person.3.sequence")
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button(action: {
                        if(isTripCompleted == false){
                            sharedReviewState.isReviewNeeded = true
                        }
                        toggleTripCompletion()
                        if(trip.advisors != nil){
                            self.reviewedUser = trip.advisors[0]
                        }else{
                            sharedReviewState.isReviewNeeded = false
                        }
                    }) {
                        Text(isTripCompleted ? "Reopen Trip" : "Complete Trip")
                    }
                    .disabled(viewModel.isUpdatingTripStatus)
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
            .sheet(isPresented: $showingAddEditor) {
                AddTripEditerView(trip: trip, userlist: userList) { editors in
                    self.newEditors = editors as [String: UserRole]
                }
            }
            .sheet(isPresented: .init(
                get: { sharedReviewState.isReviewNeeded },
                set: { if !$0 { sharedReviewState.isReviewNeeded = false } }
            )) {
                if(reviewedUser == ""){
                    AddReviewView(targetUserId: reviewedUser,
                                  currentUserId: (Auth.auth().currentUser?.email)! as String,
                                  sharedReviewState: sharedReviewState)
                }
            }
            .onAppear {
                viewModel.fetchActivities(for: trip)
                viewModel.fetchTripCompletionStatus(for: trip) { status in
                    isTripCompleted = status
                }
                reviewedUser = trip.advisors[0]
            }
            .onChange(of: showingAddEditor) { isPresented in
                if !isPresented && !newEditors.isEmpty {
                    viewModel.addEditors(to: trip, editors: newEditors)
                    newEditors = [:]
                    viewModel.fetchActivities(for: trip)
                }
                else if(!isPresented){
                    viewModel.fetchActivities(for: trip)
                }
            }
            .onChange(of: sharedReviewState.isReviewCompleted) { completed in
                if completed {
                    presentationMode.wrappedValue.dismiss()
                }
            }
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
    
    private func toggleTripCompletion() {
        isTripCompleted.toggle()
        viewModel.updateTripCompletionStatus(for: trip, isCompleted: isTripCompleted) { result in
            switch result {
            case .success:
                print("Trip completion status updated successfully")
                if isTripCompleted {
                    sharedReviewState.isReviewNeeded = true
                }
            case .failure(let error):
                print("Failed to update trip completion status: \(error.localizedDescription)")
                isTripCompleted.toggle()
            }
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

