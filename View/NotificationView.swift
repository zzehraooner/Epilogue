import SwiftUI

struct NotificationView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var viewModel = NotificationViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                } else if viewModel.notifications.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 48))
                            .foregroundStyle(.tertiary)
                        Text("Henüz hiç bildiriminiz yok.")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200, alignment: .center)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(viewModel.notifications) { notification in
                        NotificationCell(notification: notification)
                            .onTapGesture {
                                if !notification.isRead, let userId = authViewModel.currentUser?.id {
                                    viewModel.markAsRead(userId: userId, notificationId: notification.id)
                                }
                            }
                    }
                }
            }
            .navigationTitle("Bildirimler")
            .toolbar {
                if !viewModel.notifications.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            if let userId = authViewModel.currentUser?.id {
                                viewModel.markAllAsRead(userId: userId)
                            }
                        } label: {
                            Text("Tümünü Okundu İşaretle")
                                .font(.caption)
                        }
                    }
                }
            }
            .onAppear {
                if let userId = authViewModel.currentUser?.id {
                    viewModel.listenForNotifications(userId: userId)
                }
            }
            .onDisappear {
                viewModel.stopListening()
            }
        }
    }
}

struct NotificationCell: View {
    let notification: AppNotification
    
    var iconName: String {
        switch notification.type {
        case .newMemory: return "photo.fill"
        case .orderStatus: return "box.truck.fill"
        case .system: return "info.circle.fill"
        }
    }
    
    var iconColor: Color {
        switch notification.type {
        case .newMemory: return .purple
        case .orderStatus: return .blue
        case .system: return .orange
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Circle()
                .fill(iconColor.opacity(0.1))
                .frame(width: 48, height: 48)
                .overlay {
                    Image(systemName: iconName)
                        .foregroundStyle(iconColor)
                        .font(.title3)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.subheadline)
                    .bold(!notification.isRead)
                
                Text(notification.message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                
                Text(notification.date, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 2)
            }
            
            Spacer()
            
            if !notification.isRead {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
    }
}
