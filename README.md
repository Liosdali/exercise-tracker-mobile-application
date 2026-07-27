# Exercise App

Tamamen çevrimdışı (offline) çalışan bir Flutter egzersiz/antrenman uygulaması.
Egzersizleri kategoriye (vücut bölgesine) göre listeler, her egzersiz için
GIF/resim ve talimatlar gösterir; ayrıca bir takvim üzerinden antrenman
yaptığınız günleri ve o gün yaptığınız egzersizleri kaydetmenizi sağlar.

## Özellikler

- **Egzersiz kütüphanesi**: 1300+ egzersiz, vücut bölgesine göre
  kategorilenmiş (sırt, göğüs, kardiyo, omuz, bacak vb.).
- **Arama/filtreleme**: Kategori içinde isim, ekipman veya hedef kasa göre
  arama.
- **Egzersiz detayı**: Animasyonlu GIF, ekipman, hedef/yardımcı kaslar ve
  adım adım talimatlar.
- **Antrenman takvimi**: Takvimde antrenman yapılan günler işaretlenir;
  bir güne dokunarak o gün yapılan egzersizleri (set/tekrar/ağırlık/not ile)
  ekleyebilir, düzenleyebilir veya silebilirsiniz.
- **Tamamen çevrimdışı**: Egzersiz verisi ve medya (resim/GIF) uygulamaya
  gömülüdür; antrenman kayıtları cihazda yerel SQLite veritabanında
  saklanır. İnternet bağlantısı gerekmez.

## Gereksinimler

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (bu proje
  Flutter 3.x / Dart ^3.12 ile geliştirildi ve test edildi).
- Android Studio veya Xcode (fiziksel telefon/emülatör ile önizleme için) —
  isteğe bağlı, çünkü Windows/Web üzerinde de önizleme yapılabilir.
- Kurulumu doğrulamak için: `flutter doctor`

## Kurulum

```powershell
cd exercise_app
flutter pub get
```

Bu komut `pubspec.yaml` içindeki tüm bağımlılıkları (provider, sqflite,
table_calendar, intl vb.) indirir.

## Önizleme / Çalıştırma

Bağlı cihazları görmek için:

```powershell
flutter devices
```

Ardından `flutter run` ile istediğiniz hedefte çalıştırabilirsiniz:

- **Android telefon/emülatör**:
  ```powershell
  flutter run -d <android-device-id>
  ```
- **iOS (yalnızca macOS'te)**:
  ```powershell
  flutter run -d <ios-device-id>
  ```
- **Web tarayıcıda hızlı önizleme** (Chrome/Edge):
  ```powershell
  flutter run -d chrome
  ```
- **Windows masaüstü uygulaması olarak**:
  ```powershell
  flutter run -d windows
  ```

`flutter run` çalışırken kod değişikliklerini terminalde `r` (hot reload)
veya `R` (hot restart) tuşuyla anında görebilirsiniz.

> Not: Emülatör/simülatör kullanacaksanız önce bir tane başlatın:
> `flutter emulators` ile mevcut emülatörleri listeleyip
> `flutter emulators --launch <emulator-id>` ile başlatabilirsiniz.

## Yayın (Release) Paketi Oluşturma

- **Android APK**:
  ```powershell
  flutter build apk --release
  ```
  Çıktı: `build/app/outputs/flutter-apk/app-release.apk`

- **Android App Bundle (Play Store için)**:
  ```powershell
  flutter build appbundle --release
  ```

- **iOS (yalnızca macOS'te)**:
  ```bash
  flutter build ios --release
  ```

- **Windows masaüstü**:
  ```powershell
  flutter build windows --release
  ```

> Uygulama, 1300+ egzersize ait resim ve GIF'leri (~130 MB) doğrudan
> `storage/` klasöründen asset olarak gömdüğü için üretilen paket boyutu
> büyüktür (~140 MB+). Bu, uygulamanın tamamen çevrimdışı çalışabilmesi
> için bilinçli bir tercihtir.

## Testleri Çalıştırma

```powershell
flutter analyze
flutter test
```

`flutter test`, uygulamanın açılıp veri setini yüklediğini ve alt gezinme
(Egzersizler / Takvim) sekmelerinin çalıştığını doğrulayan bir smoke test
içerir. Test ortamında gerçek sqflite eklentisi bulunmadığından,
`sqflite_common_ffi` paketi test veritabanı motoru olarak kullanılır (yalnızca
`test/` altında, üretim kodunu etkilemez).

## Proje Yapısı

```
lib/
  main.dart                     # Uygulama girişi, Provider kurulumu
  models/
    exercise.dart                # Egzersiz veri modeli
    workout_entry.dart           # Antrenman kaydı veri modeli
  data/
    exercise_repository.dart     # exercises.json asset'ini okur/parse eder
    database_helper.dart         # SQLite (sqflite) CRUD işlemleri
  providers/
    exercise_provider.dart       # Egzersiz verisini widget ağacına sunar
    workout_provider.dart        # Antrenman kayıtlarını widget ağacına sunar
  screens/
    home_shell.dart              # Alt gezinme (Egzersizler / Takvim)
    categories_screen.dart       # Kategori listesi
    category_exercises_screen.dart # Kategoriye göre egzersiz listesi + arama
    exercise_detail_screen.dart  # Egzersiz detayı (GIF, talimatlar)
    exercise_picker_screen.dart  # Takvimden egzersiz seçme ekranı
    log_entry_screen.dart        # Antrenman kaydı ekleme/düzenleme formu
    calendar_screen.dart         # Antrenman takvimi
  widgets/
    category_style.dart          # Kategori ikon/etiket yardımcıları
    exercise_thumbnail.dart      # Egzersiz küçük resmi bileşeni
storage/
  data/exercises.json            # Egzersiz veri seti (asset)
  images/, videos/                # Egzersiz resim ve GIF'leri (asset)
test/
  widget_test.dart               # Smoke test
```

## Sorun Giderme

- **Kurulumu doğrulamak için**: `flutter doctor -v` çalıştırıp eksik bileşen
  (Android SDK, Xcode, vs.) olup olmadığını kontrol edin.
- **Bağımlılık hatası alırsanız**: `flutter clean` ardından `flutter pub get`
  çalıştırın.
- **Emülatör/cihaz görünmüyorsa**: `flutter devices` listesinde yoksa,
  USB hata ayıklama (Android) veya güvenilir cihaz onayının (iOS) açık
  olduğundan emin olun.
