import Foundation

struct Comment: Identifiable, Codable {
    var id: String
    var memoryId: String
    var userId: String
    var displayName: String
    var text: String
    var createdAt: Date
}
