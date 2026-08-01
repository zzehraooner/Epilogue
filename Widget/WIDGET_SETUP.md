# Stash Widget Kurulumu

Widget'ları etkinleştirmek için:

1. Xcode'da **File > New > Target** seçin
2. **Widget Extension** seçin
3. İsim: `StashWidget`
4. "Include Configuration App Intent" işaretsiz bırakın
5. Oluşturulan varsayılan dosyaları silin
6. Bu klasördeki `StashWidget.swift` dosyasını Widget target'a ekleyin
7. App Group ekleyin: `group.com.zehraoner.Epilogue`
8. Her iki target'ta da (ana uygulama + widget) aynı App Group'u etkinleştirin
