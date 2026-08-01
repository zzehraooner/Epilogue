# 📦 Stash (Epilogue)

**Stash**, sevdiklerinizle ortak anılarınızı biriktirmenizi, saklamanızı ve hatırlamanızı sağlayan modern, sosyal bir anı defteri ve dijital kasa (vault) uygulamasıdır. 

SwiftUI ve Firebase kullanılarak, **"Glassmorphism"** tasarım diliyle ve iOS'in en güncel teknolojileriyle (Live Activities, Widgets, MapKit) geliştirilmiştir.

![Stash Banner](https://img.shields.io/badge/Platform-iOS%2017.0+-black.svg?style=flat&logo=apple)
![SwiftUI](https://img.shields.io/badge/SwiftUI-Blue.svg?style=flat&logo=swift)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28.svg?style=flat&logo=firebase)

## ✨ Özellikler

- 🔐 **Ortak Depolar (Shared Vaults):** Aileniz veya arkadaş gruplarınız için özel depolar oluşturun. Güvenli davet kodlarıyla üyeleri deponuza davet edin ve anıları ortaklaşa büyütün.
- 📸 **Zengin Anı Formatları:** Anılarınıza fotoğraf, video, ses kaydı, müzik, konum (otomatik tamamlamalı global konum arama) ve özel etiketler ekleyin.
- ⏳ **Zaman Kapsülü (Time Capsule):** Bazı anıları çok mu özel? Onları "Zaman Kapsülü" olarak işaretleyin ve belirlediğiniz gelecekteki bir tarihe kadar kilitli tutun.
- 🗺️ **Anı Haritası (Memory Map):** Eklediğiniz tüm anıları etkileşimli bir dünya haritası üzerinde görselleştirin.
- 🎵 **Depo Çalma Listesi (Playlist):** Depodaki sesli anılarınızı ve eklediğiniz şarkıları kesintisiz bir müzik çalar deneyimiyle dinleyin.
- ❤️ **Sosyal Etkileşim:** Sevdiklerinizin anılarına emojilerle tepki (reaction) verin, yorum yapın veya en sevdiklerinizi favorilerinize ekleyin.
- 🏆 **Oyunlaştırma ve Rozetler:** Uygulamayı kullandıkça profilinizde sergileyebileceğiniz özel başarımlar ve rozetler kazanın.
- 📅 **Tarihte Bugün (On This Day):** Geçmiş yıllardaki aynı güne ait anılarınızı ana sayfanızda veya iOS Widget'ınızda görün.
- 🏝️ **Canlı Etkinlikler (Live Activities):** Deponuzdaki güncel aktiviteleri doğrudan Kilit Ekranınızdan (Lock Screen) veya Dynamic Island'dan takip edin.
- 🎨 **Premium Tasarım:** Karanlık mod (Dark Mode) odaklı, buzlu cam (ultraThinMaterial) efektleri ve tatmin edici mikro-animasyonlar ile donatılmış arayüz.

## 🛠️ Teknolojiler ve Mimari

*   **UI Framework:** SwiftUI
*   **Mimari:** MVVM (Model-View-ViewModel)
*   **Arka Uç (Backend):** Firebase Firestore (NoSQL Veritabanı) & Firebase Storage (Medya Depolama)
*   **Kimlik Doğrulama:** Firebase Authentication (E-posta/Şifre) & Biyometrik Doğrulama (FaceID/TouchID)
*   **Konum Servisleri:** MapKit & `MKLocalSearchCompleter` (Konum arama ve tersine coğrafi kodlama)
*   **Medya:** AVFoundation (Ses kaydı ve oynatma), PhotosUI
*   **Sistem Entegrasyonları:** ActivityKit (Live Activities), WidgetKit

## 🚀 Kurulum (Nasıl Çalıştırılır?)

Bu projeyi yerel ortamınızda çalıştırmak için aşağıdaki adımları izleyebilirsiniz:

1. **Repoyu Klonlayın:**
   ```bash
   git clone https://github.com/KULLANICI_ADINIZ/Stash.git
   cd Stash
   ```

2. **Firebase Kurulumunu Yapın:**
   * Firebase Console'a gidin ve yeni bir iOS projesi oluşturun.
   * `Bundle ID` olarak uygulamanın Bundle ID'sini girin.
   * İndirdiğiniz `GoogleService-Info.plist` dosyasını Xcode'da projenin kök dizinine sürükleyip bırakın.
   * Firebase Console üzerinden **Firestore Database**, **Storage** ve **Authentication (Email/Password)** servislerini aktifleştirin.

3. **Xcode'da Açın:**
   * `Epilogue.xcodeproj` (veya `Stash.xcodeproj`) dosyasına çift tıklayarak Xcode'u açın.
   * Simülatör veya fiziksel bir iOS 17.0+ cihazı seçin.

4. **Live Activities (Opsiyonel ama Önerilir):**
   * Eğer hata alırsanız, uygulamanın ana `Target` -> `Info` -> `Custom iOS Target Properties` sekmesinde `NSSupportsLiveActivities` anahtarının `YES` (Boolean) olarak eklendiğinden emin olun.

5. **Derleyin ve Çalıştırın:**
   * `Cmd + R` kısayoluyla projeyi derleyin.

## 🤝 Katkıda Bulunma

Eğer projeye katkıda bulunmak isterseniz:
1. Bu repoyu fork'layın.
2. Yeni bir branch oluşturun (`git checkout -b feature/HarikaOzelik`).
3. Değişikliklerinizi commit'leyin (`git commit -m 'Harika bir özellik eklendi'`).
4. Branch'inize push'layın (`git push origin feature/HarikaOzelik`).
5. Bir Pull Request açın!

---
*Bu uygulama sevgiyle ve Swift ile geliştirilmiştir.* 💜
