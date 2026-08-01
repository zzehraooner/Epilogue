import Foundation
import FirebaseFirestore

@MainActor
@Observable
class OrderTrackingViewModel {
    var orders: [BookOrder] = []
    var isLoading = false
    var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    
    func listenForOrders(userId: String) {
        isLoading = true
        errorMessage = nil
        
        listenerRegistration?.remove()
        
        listenerRegistration = db.collection("orders")
            .whereField("userId", isEqualTo: userId)
            // Firebase'de composite index gerekebilir
            .order(by: "orderDate", descending: true) 
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    // Eğer orderDate sıralamasından dolayı indeks hatası verirse bunu görelim
                    self.errorMessage = "Siparişler yüklenemedi: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self.orders = documents.compactMap { doc -> BookOrder? in
                    try? doc.data(as: BookOrder.self)
                }
            }
    }
    
    func stopListening() {
        listenerRegistration?.remove()
        listenerRegistration = nil
    }
}
