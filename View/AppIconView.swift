import SwiftUI

struct AppIconOption: Identifiable {
    let id = UUID()
    let name: String
    let displayName: String
    let previewColor: Color
    let iconSystemName: String
}

struct AppIconView: View {
    @State private var currentIcon: String? = UIApplication.shared.alternateIconName
    
    private let icons: [AppIconOption] = [
        AppIconOption(name: "AppIcon", displayName: "Varsayılan", previewColor: .blue, iconSystemName: "shippingbox.fill"),
        AppIconOption(name: "AppIconDark", displayName: "Koyu", previewColor: Color(hex: "1a1a2e"), iconSystemName: "shippingbox.fill"),
        AppIconOption(name: "AppIconPink", displayName: "Pembe", previewColor: .pink, iconSystemName: "shippingbox.fill"),
        AppIconOption(name: "AppIconGreen", displayName: "Yeşil", previewColor: .green, iconSystemName: "shippingbox.fill"),
        AppIconOption(name: "AppIconPurple", displayName: "Mor", previewColor: .purple, iconSystemName: "shippingbox.fill"),
    ]
    
    var body: some View {
        List {
            ForEach(icons) { icon in
                Button {
                    changeIcon(to: icon.name == "AppIcon" ? nil : icon.name)
                } label: {
                    HStack(spacing: 16) {
                        // Icon preview
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(icon.previewColor.gradient)
                            .frame(width: 60, height: 60)
                            .overlay {
                                Image(systemName: icon.iconSystemName)
                                    .font(.title2)
                                    .foregroundStyle(.white)
                            }
                        
                        Text(icon.displayName)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        if isSelected(icon) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.blue)
                                .font(.title3)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Section {
                Text("İkon setlerini Xcode Assets'ten ekledikten sonra burada görünecektir.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Uygulama İkonu")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func isSelected(_ icon: AppIconOption) -> Bool {
        if icon.name == "AppIcon" {
            return currentIcon == nil
        }
        return currentIcon == icon.name
    }
    
    private func changeIcon(to name: String?) {
        UIApplication.shared.setAlternateIconName(name) { error in
            if error == nil {
                currentIcon = name
            }
        }
    }
}
