import SwiftUI

struct OrdersListView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var viewModel = OrderTrackingViewModel()
    
    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
            } else if viewModel.orders.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)
                    Text("Henüz hiç siparişiniz yok.")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 200, alignment: .center)
                .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.orders) { order in
                    OrderCard(order: order)
                }
            }
        }
        .navigationTitle("Siparişlerim")
        .onAppear {
            if let userId = authViewModel.currentUser?.id {
                viewModel.listenForOrders(userId: userId)
            }
        }
        .onDisappear {
            viewModel.stopListening()
        }
    }
}

struct OrderCard: View {
    let order: BookOrder
    
    var statusColor: Color {
        switch order.status {
        case .pending: return .orange
        case .shipped: return .blue
        case .delivered: return .green
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(order.orderDate, style: .date)
                    .font(.subheadline)
                    .bold()
                
                Spacer()
                
                Text(order.status.rawValue)
                    .font(.caption)
                    .bold()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.1))
                    .foregroundStyle(statusColor)
                    .clipShape(Capsule())
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Şablon: \(order.template.rawValue)")
                        .font(.footnote)
                    Text("Kağıt: \(order.paperType.rawValue)")
                        .font(.footnote)
                    Text("\(order.pageCount) Sayfa")
                        .font(.footnote)
                }
                .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(String(format: "%.2f", order.totalPrice)) ₺")
                    .font(.headline)
            }
            
            if order.status == .shipped {
                HStack {
                    Image(systemName: "box.truck")
                    Text("Kargonuz yola çıktı!")
                }
                .font(.caption)
                .foregroundStyle(.blue)
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
    }
}
