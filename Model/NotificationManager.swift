import Foundation
import UserNotifications
import FirebaseMessaging
import FirebaseFirestore
import UIKit

/// Uygulama genelinde bildirim izinlerini ve Firebase Cloud Messaging (FCM) 
/// token yönetimini sağlayan sınıf.
@Observable
class NotificationManager: NSObject, UNUserNotificationCenterDelegate, MessagingDelegate {
    static let shared = NotificationManager()
    
    var isAuthorized = false
    private let db = Firestore.firestore()
    
    override private init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
    }
    
    /// Kullanıcıdan bildirim göndermek için izin ister.
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                    self.scheduleOnThisDayNotification()
                } else if let error = error {
                    print("Bildirim izni hatası: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// FCM Token güncellendiğinde tetiklenir (MessagingDelegate).
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        print("Yeni FCM Token Alındı: \(fcmToken)")
        
        // Eğer kullanıcı giriş yapmışsa token'ı veritabanına kaydet
        if let userId = AuthViewModel().currentUser?.id {
            saveFCMToken(userId: userId, token: fcmToken)
        }
    }
    
    /// FCM Token'ı Firestore'daki kullanıcı belgesine kaydeder.
    /// Cloud Functions, kullanıcılara bildirim atmak için bu token'ı kullanır.
    func saveFCMToken(userId: String, token: String) {
        db.collection("users").document(userId).setData(["fcmToken": token], merge: true) { error in
            if let error = error {
                print("FCM Token kaydedilemedi: \(error.localizedDescription)")
            } else {
                print("FCM Token başarıyla Firestore'a kaydedildi.")
            }
        }
    }
    
    // Uygulama açıkken bildirim gelirse ön planda göstermek için
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
    
    func scheduleOnThisDayNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Bugün Geçmişte 📸"
        content.body = "Geçmişte bugüne ait anıların olabilir. Göz atmak ister misin?"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "onThisDay", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("On This Day bildirim hatası: \(error)")
            }
        }
    }
}
