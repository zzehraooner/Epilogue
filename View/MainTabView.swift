import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DepoListView()
                .tabItem {
                    Label("Depolarım", systemImage: "folder.fill")
                }
                .tag(0)
                
            OnThisDayView()
                .tabItem {
                    Label("Bugün", systemImage: "clock.arrow.circlepath")
                }
                .tag(1)
            
            NotificationView()
                .tabItem {
                    Label("Bildirimler", systemImage: "bell.fill")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Label("Profil", systemImage: "person.crop.circle")
                }
                .tag(3)
        }
        .onAppear {
            NotificationManager.shared.requestPermission()
        }
    }
}
