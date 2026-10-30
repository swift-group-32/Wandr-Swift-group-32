//
//  NotificationView.swift
//  Wandr-Swift-group-32
//
//  Created by Manuela Victoria Ragua on 30/10/26.
//

import SwiftUI

struct NotificationView: View {

    @StateObject private var viewModel =
        NotificationViewModel(
            repository: SupabaseNotificationRepository()
        )

    var body: some View {
        Group {
            if viewModel.isLoading {

                ProgressView("Loading...")

            } else if let error = viewModel.errorMessage {

                VStack(spacing: 12) {
                    Text("Could not load notifications")
                        .font(.headline)

                    Text(error)
                        .font(.caption)
                        .multilineTextAlignment(.center)

                    Button("Retry") {
                        Task {
                            await viewModel.loadNotifications()
                        }
                    }
                }
                .padding()

            } else if viewModel.notifications.isEmpty {

                VStack(spacing: 12) {
                    Image(systemName: "bell.slash")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)

                    Text("No notifications")
                        .font(.headline)

                    Text("You're all caught up.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()

            } else {

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.notifications) { notification in

                            HStack(alignment: .top, spacing: 14) {

                                ZStack {
                                    Circle()
                                        .fill(Color.wandrGreen.opacity(0.15))

                                    Image(
                                        systemName:
                                            notification.type
                                            == "sponsored_quest_opportunity"
                                            ? "megaphone.fill"
                                            : "bell.fill"
                                    )
                                    .foregroundStyle(Color.wandrGreen)
                                }
                                .frame(width: 48, height: 48)

                                VStack(
                                    alignment: .leading,
                                    spacing: 6
                                ) {

                                    Text(notificationTitle(
                                        notification
                                    ))
                                    .font(.headline)

                                    if let content = notification.content {
                                        Text(content)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }

                                    Text(
                                        notification.createdAt,
                                        style: .relative
                                    )
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }
                            .padding()
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )
                            .background(Color.white)
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 18
                                )
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color.wandrCream)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadNotifications()
        }
        
    }

    private func notificationTitle(
        _ notification: AppNotification
    ) -> String {

        switch notification.type {
        case "sponsored_quest_opportunity":
            return "Sponsored Quest Opportunity"

        case "event_reminder":
            return "Event Reminder"

        case "nearby_new_quest":
            return "New Quest Nearby"

        case "completed_friend_quest":
            return "Friend Completed a Quest"

        case "unlocked_badge":
            return "New Badge Unlocked"

        case "friend_request":
            return "Friend Request"

        default:
            return "Notification"
        }
    }
}

#Preview {
    NavigationStack {
        NotificationView()
    }
}
