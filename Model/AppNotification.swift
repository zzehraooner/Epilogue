import Foundation
import FirebaseFirestore

enum NotificationType: String, Codable {
    case newMemory = "newMemory"
    case orderStatus = "orderStatus"
    case system = "system"
}

struct AppNotification: Identifiable, Codable {
    var id: String
    var userId: String
    var type: NotificationType
    var title: String
    var message: String
    var date: Date
    var isRead: Bool
}
