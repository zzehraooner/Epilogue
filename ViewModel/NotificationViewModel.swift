import Foundation
import FirebaseFirestore

@MainActor
@Observable
class NotificationViewModel {
    var notifications: [AppNotification] = []
    var isLoading = false
    var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    
    /// Kullanıcının bildirimlerini dinler
    func listenForNotifications(userId: String) {
        isLoading = true
        errorMessage = nil
        
        listenerRegistration?.remove()
        
        listenerRegistration = db.collection("users").document(userId).collection("notifications")
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Bildirimler yüklenemedi: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self.notifications = documents.compactMap { doc -> AppNotification? in
                    try? doc.data(as: AppNotification.self)
                }
            }
    }
    
    /// Bildirimi okundu olarak işaretler
    func markAsRead(userId: String, notificationId: String) {
        db.collection("users").document(userId).collection("notifications").document(notificationId)
            .updateData(["isRead": true]) { _ in }
    }
    
    /// Tüm bildirimleri okundu işaretler
    func markAllAsRead(userId: String) {
        let batch = db.batch()
        for notification in notifications where !notification.isRead {
            let ref = db.collection("users").document(userId).collection("notifications").document(notification.id)
            batch.updateData(["isRead": true], forDocument: ref)
        }
        batch.commit { _ in }
    }
    
    /// Dinleyiciyi durdurur
    func stopListening() {
        listenerRegistration?.remove()
        listenerRegistration = nil
    }
    
    // (TEST İÇİN) - Normalde sunucu (Cloud Functions) atar. 
    // Simülasyon amaçlı uygulamadan atılması için metod eklendi.
    func createSystemNotification(userId: String, title: String, message: String) {
        let notification = AppNotification(
            id: UUID().uuidString,
            userId: userId,
            type: .system,
            title: title,
            message: message,
            date: .now,
            isRead: false
        )
        try? db.collection("users").document(userId).collection("notifications").document(notification.id).setData(from: notification)
    }
}
