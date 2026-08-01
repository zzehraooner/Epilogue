import Foundation

enum BookTemplateType: String, Codable, CaseIterable {
    case polaroid = "Polaroid"
    case minimalist = "Minimalist"
}

enum PaperType: String, Codable, CaseIterable {
    case matte = "Mat"
    case glossy = "Parlak"
}

enum OrderStatus: String, Codable {
    case pending = "Hazırlanıyor"
    case shipped = "Kargoya Verildi"
    case delivered = "Teslim Edildi"
}

struct BookOrder: Identifiable, Codable {
    var id: String
    var userId: String
    var depoId: String
    
    // Sipariş Detayları
    var template: BookTemplateType
    var paperType: PaperType
    var pageCount: Int
    var totalPrice: Double
    
    // Teslimat Adresi
    var fullName: String
    var address: String
    var city: String
    var phone: String
    
    // Durum
    var status: OrderStatus
    var orderDate: Date
    
    // Temel Fiyatlandırma
    static let basePrice: Double = 399.0 // 40 sayfaya kadar sabit
    static let perExtraPagePrice: Double = 5.0
    
    static func calculatePrice(pageCount: Int) -> Double {
        if pageCount <= 40 {
            return basePrice
        } else {
            return basePrice + (Double(pageCount - 40) * perExtraPagePrice)
        }
    }
}
