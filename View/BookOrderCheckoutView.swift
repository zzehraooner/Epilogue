import SwiftUI

struct BookOrderCheckoutView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.dismiss) private var dismiss
    
    let depo: Depo
    let memories: [Memory]
    let template: BookTemplateType
    @Bindable var viewModel: MemoryBookViewModel
    
    @State private var fullName = ""
    @State private var phone = ""
    @State private var address = ""
    @State private var city = ""
    @State private var selectedPaper: PaperType = .matte
    
    private var pageCount: Int {
        memories.count + 2 // Kapak ve arka kapak dahil
    }
    
    private var totalPrice: Double {
        BookOrder.calculatePrice(pageCount: pageCount)
    }
    
    private var isFormValid: Bool {
        !fullName.isEmpty && phone.count >= 10 && !address.isEmpty && !city.isEmpty
    }
    
    var body: some View {
        Form {
            Section("Sipariş Özeti") {
                HStack {
                    Text("Kitap Şablonu")
                    Spacer()
                    Text(template.rawValue)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Sayfa Sayısı")
                    Spacer()
                    Text("\(pageCount) Sayfa")
                        .foregroundStyle(.secondary)
                }
                Picker("Kağıt Tipi", selection: $selectedPaper) {
                    ForEach(PaperType.allCases, id: \.self) { paper in
                        Text(paper.rawValue).tag(paper)
                    }
                }
            }
            
            Section("Teslimat Adresi") {
                TextField("Ad Soyad", text: $fullName)
                    .textContentType(.name)
                    .onChange(of: fullName) { _, newValue in
                        // Sadece harf ve boşluklara izin ver
                        let filtered = newValue.filter { $0.isLetter || $0.isWhitespace }
                        if fullName != filtered {
                            fullName = filtered
                        }
                    }
                    
                TextField("Telefon", text: $phone)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
                    .onChange(of: phone) { _, newValue in
                        // Sadece rakamlara izin ver
                        let filtered = newValue.filter { $0.isNumber }
                        if phone != filtered {
                            phone = filtered
                        }
                    }
                    
                TextField("Şehir", text: $city)
                    .textContentType(.addressCity)
                TextEditor(text: $address)
                    .frame(height: 80)
                    .overlay(alignment: .topLeading) {
                        if address.isEmpty {
                            Text("Açık Adres")
                                .foregroundStyle(Color(UIColor.placeholderText))
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                    }
            }
            
            Section {
                HStack {
                    Text("Toplam Tutar")
                        .font(.headline)
                    Spacer()
                    Text("\(String(format: "%.2f", totalPrice)) ₺")
                        .font(.title3)
                        .bold()
                }
                .padding(.vertical, 8)
                
                Button {
                    placeOrder()
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isPlacingOrder {
                            ProgressView().tint(.white)
                        } else {
                            Text("Ödeme Yap ve Sipariş Ver")
                                .bold()
                        }
                        Spacer()
                    }
                }
                .listRowBackground(isFormValid ? Color.blue : Color.gray.opacity(0.5))
                .foregroundStyle(.white)
                .disabled(!isFormValid || viewModel.isPlacingOrder)
            }
        }
        .navigationTitle("Siparişi Tamamla")
        .alert("Sipariş Alındı! 🎉", isPresented: $viewModel.orderSuccess) {
            Button("Tamam", role: .cancel) {
                // Her şeyi kapat (Root'a dön veya bir öncekine)
                // Şimdilik sadece dismiss
                dismiss()
                // MemoryBookPreviewView'ı da kapatmak için bir environment variable veya binding kullanılabilir.
            }
        } message: {
            Text("Anı kitabın başarıyla üretime alındı. En kısa sürede sana ulaştıracağız!")
        }
        .alert("Hata", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("Tamam", role: .cancel) {}
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
    
    private func placeOrder() {
        guard let userId = authViewModel.currentUser?.id else { return }
        
        let order = BookOrder(
            id: UUID().uuidString,
            userId: userId,
            depoId: depo.id,
            template: template,
            paperType: selectedPaper,
            pageCount: pageCount,
            totalPrice: totalPrice,
            fullName: fullName,
            address: address,
            city: city,
            phone: phone,
            status: .pending,
            orderDate: .now
        )
        
        Task {
            await viewModel.placeOrder(order: order)
        }
    }
}
