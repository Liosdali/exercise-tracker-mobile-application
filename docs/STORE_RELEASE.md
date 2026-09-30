# Mağaza Yayını — App Store ve Google Play Gereklilikleri

Atlas Workout (`com.mythosforgelabs.atlasworkout`) için mağaza yayını kontrol
listesi. Koddaki kısım bu dalda yapıldı; geri kalanlar hesap panelleri ve
içerik hazırlığıdır.

Durum işaretleri: ✅ depoda hazır · ⬜ senin yapman gereken · ⚠️ red riski

---

## 0. İki mağazayı da bloklayan eksikler

Bunlar olmadan iki mağazadan da büyük olasılıkla red gelir.

- ⬜ ⚠️ **Gizlilik politikası URL'si.** Herkese açık bir sayfa gerekli (GitHub
  Pages, Notion public sayfası vb.). Hem App Store Connect'e hem Play
  Console'a girilir, uygulama içinden de erişilebilmeli (App Store 5.1.1(i)).
  Uygulamada şu an böyle bir bağlantı **yok**. URL'yi bulduğunda Ayarlar'a
  `url_launcher` ile bir satır eklenecek (paket zaten projede).
- ⬜ ⚠️ **Kullanım koşulları / EULA ve kabulü.** Takımlar, akış ve öneriler
  kullanıcı içeriği (UGC) sayılır. Apple 1.2 ve Play UGC politikası,
  kullanıcıların uygunsuz içeriğe sıfır tolerans içeren koşulları kabul
  etmesini ister. Kabul, ekibe katılmadan veya ekip oluşturmadan önce alınmalı.
  Koşul metni ve bir onay adımı henüz **yok**.
- ⬜ ⚠️ **Şikayetlerin 24 saat içinde ele alınması.** Şikayet ve engelleme
  uygulamada var ✅ (`user_reports`, `user_blocks`). Şikayetleri okuyan bir
  süreç ise yok: şu an kayıtları yalnızca Supabase panelinden görebilirsin.
  Apple, şikayet edilen içeriğin 24 saat içinde kaldırılmasını ve kullanıcının
  gerekirse çıkarılmasını ister. Uygulamadaki mesaj da artık "24 saat içinde
  inceleriz" diyor. En basit çözüm, `user_reports` tablosuna Supabase Database
  Webhook ile e-posta bildirimi bağlamak.
- ⬜ ⚠️ **Egzersiz görsellerinin lisansı.** `storage/` altındaki 1324 GIF ve
  `exercises.json`, ID biçimine bakılırsa ExerciseDB'den geliyor gibi
  görünüyor. ExerciseDB GIF'leri ücretsiz değildir; ticari lisans gerektirir.
  Kaynağı ve kullanım hakkını doğrula. Hakkın yoksa bu durum Apple 5.2 ve
  Play fikri mülkiyet politikası kapsamında red veya kaldırma sebebidir. App
  Store Connect'teki "Content Rights" sorusu da bunu doğrudan sorar.
- ⬜ **Destek URL'si / iletişim e-postası.** App Store'da destek URL'si
  zorunlu, Play'de iletişim e-postası zorunlu.

---

## 1. App Store

### 1.1 Depoda yapılanlar (bu dal)

- ✅ Bundle ID `com.exerciseapp.exerciseApp` → `com.mythosforgelabs.atlasworkout`
  (Android paket adı ve OAuth URL scheme ile uyumlu).
- ✅ Yalnızca iPhone (`TARGETED_DEVICE_FAMILY = 1`). iPad ekran görüntüsü
  gerekmez; iPad'de uygulama iPhone uyumluluk modunda çalışır.
- ✅ `ios/Runner/PrivacyInfo.xcprivacy`: toplanan veri türleri (e-posta, ad,
  kullanıcı kimliği, fitness, sağlık/ölçümler, kullanıcı içeriği; takip yok)
  ve UserDefaults / dosya zaman damgası API gerekçeleri. Runner hedefinin
  kaynaklarına eklendi.
- ✅ `ITSAppUsesNonExemptEncryption = false`: yalnızca HTTPS kullanılıyor,
  böylece her build'de ihracat uyumluluğu sorusu çıkmaz.
- ✅ `CFBundleLocalizations` (en, tr): mağazada iki dil de listelenir.
- ✅ `NSPhotoLibraryUsageDescription`: `file_picker` fotoğraf API'lerini de
  içerdiği için bu açıklama olmadan yüklemede ITMS-90683 uyarısı alınır.
- ✅ Sign in with Apple entitlement (zaten vardı). Google girişi olduğu için
  4.8 gereği Apple girişi zorunluydu; karşılanıyor.
- ✅ Uygulama içi hesap silme (zaten vardı; 5.1.1(v)).
- ✅ Şikayet/engelleme ekranı Türkçeleştirildi. Başarısız istekler artık
  sessizce kaybolmuyor, kullanıcıya gösteriliyor.
- ✅ `codemagic.yaml`: Windows'ta iOS build alınamadığı için Codemagic
  (macOS) üzerinde imzalı IPA üretip TestFlight'a yükleyen iş akışı.

### 1.2 Apple Developer portalı (developer.apple.com)

1. ⬜ **Identifiers → App ID** oluştur: Explicit,
   `com.mythosforgelabs.atlasworkout`, yetenek: **Sign in with Apple**.
   (Push Notifications gerekmez; bildirimler yerel.)
2. ⬜ **Services ID** (Supabase web OAuth için; README'deki "Apple" bölümü).
   Varsa, primary App ID'yi yeni bundle ID'ye bağla.
3. ⬜ **Keys → Sign in with Apple** anahtarı (.p8). Hesap silme Edge
   Function'ı için Key ID ve Team ID gerekir.
4. ⬜ **Supabase güncellemesi (bundle ID değiştiği için şart):**
   - Authentication → Providers → Apple → *Client IDs* alanına
     `com.mythosforgelabs.atlasworkout` ekle (eskisini kaldırabilirsin).
   - Edge Function secret: `APPLE_NATIVE_CLIENT_ID=com.mythosforgelabs.atlasworkout`
     (`supabase secrets set ...`). Bu yapılmazsa iOS'ta Apple ile giriş
     "invalid audience" hatası verir.
5. ⬜ **Team ID**'ni not al (Membership sayfası).

### 1.3 App Store Connect (appstoreconnect.apple.com)

1. ⬜ **Agreements, Tax, Banking:** Ücretsiz uygulama için yalnızca Program
   License Agreement'ın kabulü yeterli. AB'de dağıtacaksan **DSA trader
   status** beyanı zorunlu (Business → Compliance).
2. ⬜ **Users and Access → Integrations → App Store Connect API** →
   anahtar oluştur (rol: App Manager). `.p8`, Key ID ve Issuer ID'yi
   Codemagic'e girersin.
3. ⬜ **Apps → + New App:** iOS, ad "Atlas Workout" (30 karakter, benzersiz
   olmalı), birincil dil, bundle ID, SKU (ör. `atlasworkout-ios`).
4. ⬜ **App Information:** kategori *Health & Fitness*, Content Rights
   sorusu (bkz. bölüm 0, görseller), yaş derecelendirmesi anketi (UGC
   bulunduğu için "User-Generated Content" sorusuna evet).
5. ⬜ **App Privacy:** Privacy Policy URL ve veri etiketleri. Cevaplar
   `PrivacyInfo.xcprivacy` ile birebir aynı olmalı:
   | Veri | Bağlı mı | Takip | Amaç |
   |---|---|---|---|
   | E-posta adresi | Evet | Hayır | Uygulama işlevi |
   | Ad | Evet | Hayır | Uygulama işlevi |
   | Kullanıcı kimliği | Evet | Hayır | Uygulama işlevi |
   | Fitness | Evet | Hayır | Uygulama işlevi |
   | Sağlık (kilo/ölçüler) | Evet | Hayır | Uygulama işlevi |
   | Diğer kullanıcı içeriği | Evet | Hayır | Uygulama işlevi |
   Misafir modunda hiçbir veri cihazdan çıkmaz; yalnızca giriş yapınca
   senkronize edilir.
6. ⬜ **Sürüm sayfası (1.0):**
   - Ekran görüntüleri: **iPhone 6.9"** (1320×2868 veya 1290×2796), 3–10 adet.
     Başka boy zorunlu değil.
   - Promotional text (170), Description (4000), Keywords (100 karakter,
     virgülle), Support URL, Marketing URL (opsiyonel), Copyright
     ("2026 Mete Baykal" / şirket adı).
   - **App Review Information:** iletişim bilgisi ve notlar. Uygulama
     yalnızca Google/Apple ile giriş kullandığı için demo hesap yerine şu
     notu yaz: "Tüm antrenman özellikleri misafir modunda giriş gerektirmez.
     Takımlar sekmesi için Sign in with Apple kullanılabilir. Hesap silme:
     Ayarlar → Hesap → Hesabı sil. Şikayet/engelleme: Takımlar akışında
     başka bir kullanıcının gönderisindeki ⋮ menüsü."
     (Menü yollarını göndermeden önce uygulamada doğrula.)
7. ⬜ **Pricing and Availability:** Ücretsiz, ülkeler.

### 1.4 Codemagic (iOS build, Windows'tan)

1. ⬜ codemagic.io'ya GitHub ile gir, bu repoyu ekle, **codemagic.yaml**
   modunu seç.
2. ⬜ Teams → Integrations → **App Store Connect**: 1.3/2'deki API
   anahtarını ekle, adını tam olarak `atlas_asc` koy.
3. ⬜ Teams → **Code signing identities**: iOS certificates → *Generate
   certificate* (Apple Distribution). iOS provisioning profiles →
   *Fetch profiles* ile `com.mythosforgelabs.atlasworkout` App Store
   profilini çek. (Önce 1.2/1'deki App ID oluşmuş olmalı.)
4. ⬜ App → Environment variables, grup adı `atlas_ios`:
   `SUPABASE_URL`, `SUPABASE_ANON_KEY` (Secure işaretle), `APP_STORE_APPLE_ID`
   (App Store Connect → App Information → Apple ID, sayısal).
5. ⬜ `dev-appstore` dalını push et → Codemagic'te **iOS → TestFlight**
   iş akışını elle başlat. Build ~20–30 dk sürer ve ücretsiz 500 dakikadan
   düşer.
6. ⬜ TestFlight'ta kendi iPhone'una kur ve şunları gerçek cihazda dene:
   Google girişi, Apple girişi, uygulama kapalıyken ve açıkken OAuth dönüşü,
   bildirimler, yedek dışa ve içe aktarma, hesap silme, yatay ekran
   (iPhone'da açık; düzen bozuksa yalnızca dikeye kısıtla).
7. ⬜ Sürüm sayfasında build'i seç → **Add for Review**.

---

## 2. Google Play

### 2.1 Depoda durum

- ✅ `applicationId com.MythosForgeLabs.AtlasWorkout`, sürüm `1.0.4+5`.
- ✅ targetSdk / compileSdk **36** (Flutter 3.44.8 varsayılanı). Play'in güncel
  hedef API şartını karşılıyor.
- ✅ Upload keystore ve `key.properties` yerel ve gitignore'da. R8
  küçültme açık.
- ✅ Kullanılmayan `SCHEDULE_EXACT_ALARM` izni kaldırıldı. Bildirimler inexact
  zamanlama kullandığı için bu izin gerekmiyordu, ama beyan edilseydi
  Play Console ayrı bir izin beyan formu isterdi.
- ✅ OAuth dönüş intent-filter'ı, hesap silme, şikayet ve engelleme.
- ℹ️ Paket boyutu: yaklaşık 155 MB medya asset olarak gömülü. AAB base modülü
  sıkıştırılmış 200 MB sınırının altında olmalı. `flutter build appbundle`
  sonrasında Play Console'daki indirme boyutunu kontrol et. Sınır aşılırsa
  medya Play Asset Delivery'ye taşınır.

### 2.2 Play Console (play.google.com/console)

1. ⬜ **Geliştirici hesabı:** kimlik doğrulaması ve iletişim bilgileri.
   Hesap **kişisel** ise ve Kasım 2023'ten sonra açıldıysa, üretime
   çıkmadan önce **kapalı test** gerekir: en az **12 test kullanıcısı**, test
   grubunda **14 gün** kesintisiz. Bu en uzun süren adım, o yüzden hemen başlat.
   Kurumsal (D-U-N-S) hesapta bu şart yok.
2. ⬜ **Uygulama oluştur:** ad, varsayılan dil, uygulama/ücretsiz.
3. ⬜ **Play App Signing:** ilk AAB yüklemesinde kabul et. Yerel
   `upload-keystore.jks` upload anahtarıdır; yedeğini güvenli bir yerde tut.
4. ⬜ **App content** bölümünün tamamı:
   - Privacy policy URL (bölüm 0)
   - **App access:** "Bazı işlevler kısıtlı". Takımlar için giriş
     gerektiğini ve inceleyicinin bir Google hesabıyla girebileceğini açıkla.
     Gerekirse bir test Google hesabı ver.
   - Ads: Hayır
   - **Content rating** (IARC anketi): UGC ve kullanıcı etkileşimi var
   - **Target audience:** 13+ veya 18+ seç. Çocukları hedeflemek Families
     politikasını tetikler, ki UGC ile birlikte ağır bir yük.
   - **Data safety:** e-posta, ad, kullanıcı kimliği, sağlık ve fitness bilgisi,
     diğer kullanıcı içeriği. Hepsi uygulama işlevi için, paylaşılmıyor,
     aktarımda şifreli. Kullanıcı silme isteyebiliyor: evet.
   - **Hesap silme web bağlantısı:** Play, uygulama dışından da silme
     isteği yapılabilen bir **web URL'si** ister. Gizlilik politikası
     sayfasına "Hesabımı sil" bölümü (e-posta ile talep) eklemek yeterli.
   - **Health apps** beyanı: fitness/antrenman uygulaması olarak işaretle.
     Tıbbi iddia yok.
   - News / Government / Financial features: Hayır
5. ⬜ **Store listing:** ad (30), kısa açıklama (80), tam açıklama (4000),
   simge **512×512 PNG**, **feature graphic 1024×500** (zorunlu), telefon
   ekran görüntüleri (en az 2, önerilen 4–8), kategori *Health & Fitness*,
   iletişim e-postası.
6. ⬜ `flutter build appbundle --release` →
   `build/app/outputs/bundle/release/app-release.aab` → Test and release →
   önce **Internal testing**, sonra **Closed testing** (12 kişi × 14 gün),
   ardından **Production** erişimine başvur.

---

## 3. Ortak içerik hazırlığı

- ⬜ Gizlilik politikası + kullanım koşulları + hesap silme talebi sayfası
  (TR + EN). Hepsi tek bir statik sitede toplanabilir.
- ⬜ Mağaza metinleri TR + EN. Tıbbi iddia içermemeli (Apple 1.4.1): "kilo
  verdirir" gibi vaatlerden kaçın.
- ⬜ Ekran görüntüleri: iPhone 6.9" ve Android telefon. İkisi de gerçek
  uygulama ekranları olmalı (Atlas temasıyla).
- ⬜ Supabase üretim projesinde tüm migration'ların uygulandığını doğrula
  (`supabase db push`), özellikle `202609200002`. İnceleme sırasında takım
  sekmesi hata verirse 2.1 (completeness) gerekçesiyle red gelir.
