# Exercise App

Çevrimdışı (offline) kullanılabilen, isteğe bağlı Google/Apple hesabı ve
Supabase bulut senkronizasyonu sunan bir Flutter egzersiz/antrenman uygulaması.
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
- **Çevrimdışı kullanım**: Egzersiz verisi ve medya (resim/GIF) uygulamaya
  gömülüdür; antrenman kayıtları cihazda yerel SQLite veritabanında
  saklanır. Misafir kullanım için internet bağlantısı gerekmez.
- **İsteğe bağlı hesap**: Android/iOS'ta Google veya Apple ile giriş;
  ad, yaş, kilo, boy ve isteğe bağlı cinsiyet içeren özel profil.
- **Hesaba özel bulut verileri**: Planlanan spor günleri, aktif/özel programlar,
  hareket ve antrenman geçmişi, ölçümler ve ilerleme cihazlar arasında korunur.
  İlk girişte mevcut misafir kayıtlarını aktarmak için onay istenir.
  Çakışan değişiklikler sessizce ezilmez; kullanıcı hangi sürümü koruyacağını seçer.

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

## Google/Apple girişi ve Supabase kurulumu

Hesap yapılandırması verilmeden uygulama misafir modunda kullanılabilir.
İlk giriş ve bulut senkronizasyonu internet gerektirir; mevcut hesabın cihazdaki
kayıtları çevrimdışı kullanılabilir. Yeni OAuth akışlarının kapsamı Android/iOS'tur.
Marka adı ve mevcut Android/iOS uygulama kimlikleri bu entegrasyonla değiştirilmez.

### Veritabanı ve hesap silme servisi

Sıralama önemlidir. Kök dizindeki `supabase_schema.sql` sosyal tabloları
(`social_users`, `groups`, `group_members`, `workout_sessions`, `user_blocks`,
`user_reports`) kuran **yalnızca sıfırdan kurulum** dosyasıdır; migration
klasöründe karşılığı yoktur. `supabase/migrations/202609071000_team_content_features.sql`
ise `public.groups` tablosuna foreign key verir. Dolayısıyla boş bir projede
doğrudan `supabase db push` çalıştırmak, `groups` tablosu henüz olmadığı için
hata verir.

**Yeni (boş) bir Supabase projesinde:**

1. Önce `supabase_schema.sql` dosyasını çalıştırın. Supabase SQL Editor
   kullanıyorsanız dosyanın en sonundaki `\ir ...` satırını atlayın ve ardından
   `supabase/migrations/202609070001_private_accounts.sql` dosyasını elle
   çalıştırın. `psql` kullanıyorsanız `\ir` satırı bunu kendisi halleder:

   ```powershell
   psql "<connection-string>" -v ON_ERROR_STOP=1 -f supabase_schema.sql
   ```

2. Ardından kalan migration'ları uygulayın:

   ```powershell
   supabase login
   supabase link --project-ref <project-ref>
   supabase db push
   supabase functions deploy delete-account
   ```

**Mevcut bir veritabanında:** eski başlangıç şemasını tekrar çalıştırmayın,
yalnızca `supabase db push` ile yeni migration'ları uygulayın.

`202609160001_team_rls_and_schema_fixes.sql` ekip özelliklerinin çalışması için
gereklidir: `groups` tablosuna `description`/`owner_id` sütunlarını ekler,
`group_members` üzerindeki kendine referans veren (sonsuz döngüye giren) RLS
politikasını değiştirir, ekip oluşturma/katılma/ayrılma/silme için eksik
INSERT/UPDATE/DELETE politikalarını tanımlar ve davet koduyla katılma işlemini
`join_team_by_invite_token` fonksiyonuna taşır. Bu migration uygulanmadan ekip
ekranları çalışmaz.

`delete-account` fonksiyonu istekteki kullanıcı kimliğine güvenmez; Bearer
oturumunu Supabase Auth ile doğrular ve yalnızca o hesabı siler. Fonksiyonun
`verify_jwt = false` ayarı anonim silme izni değildir: yeni JWT imza anahtarlarıyla
uyumluluk için doğrulama fonksiyonun içinde yapılır. Silme işleminde profil ve
ilişkili özel veriler veritabanı ilişkileri üzerinden temizlenir.

### Google

Google Cloud Console'da OAuth onay ekranını ve **Web application** OAuth
istemcisini oluşturun. Geliştirme sırasında gerekli test kullanıcılarını ekleyin.
Yetkili yönlendirme adresi:

```text
https://<project-ref>.supabase.co/auth/v1/callback
```

Supabase Dashboard > Authentication > Providers > Google altında istemci
kimliği ve sırrını girin. Uygulama sistem tarayıcısıyla Supabase PKCE akışını
kullanır; Google istemci sırrı Flutter uygulamasına eklenmez.

### Apple

Apple Developer hesabında iOS App ID için **Sign in with Apple** yeteneğini
etkinleştirin. Depodaki iOS bundle ID `com.mythosforgelabs.atlasworkout` değerindedir;
imzalama/provisioning profilinin bu kimlik ve yetenekle eşleşmesi gerekir.
`ios\Runner\Runner.entitlements` Debug, Profile ve Release yapılandırmalarına bağlıdır.

Android'deki tarayıcı akışı için aynı uygulamayla ilişkili bir **Services ID**
oluşturun. Apple web yapılandırmasına `<project-ref>.supabase.co` alan adını ve
yukarıdaki HTTPS Supabase callback adresini ekleyin. Supabase Apple provider
ayarlarına Services ID ve native iOS bundle ID'yi izin verilen istemci
kimlikleri olarak girin; Apple imzalama anahtarıyla üretilen OAuth istemci sırrını
yalnızca sunucu/provider ayarlarında saklayın. Apple web OAuth sırrını süresi
dolmadan yenileyin (en fazla altı ay); `.p8` anahtarını depoya eklemeyin.

Apple hesap silme sırasında yetkilendirme de iptal edilir. Bunun için
Supabase Edge Function secrets bölümünde şu değerleri tanımlayın:

| Değişken | Değer |
| --- | --- |
| `APPLE_TEAM_ID` | Apple Developer Team ID |
| `APPLE_KEY_ID` | Sign in with Apple anahtarının Key ID'si |
| `APPLE_PRIVATE_KEY` | `.p8` dosyasının PEM içeriği |
| `APPLE_NATIVE_CLIENT_ID` | iOS bundle ID |
| `APPLE_WEB_CLIENT_ID` | Android tarayıcı girişinde kullanılan Services ID |

`SUPABASE_URL` ve `SUPABASE_SERVICE_ROLE_KEY` dağıtılmış Edge Function ortamında
Supabase tarafından sağlanır. **Service-role anahtarı ve Apple sırları hiçbir
zaman Flutter yapılandırmasına konmaz.** iOS'ta silme için yeni Apple
yetkilendirmesi, Android'de Apple sağlayıcı refresh token'ı gerekir; gerekirse
Apple ile yeniden giriş yapılır. Apple doğrulaması veya iptal işlemi başarısızsa
hesap silinmiş gibi gösterilmez.

### Mobil callback ve çalıştırma

Supabase Dashboard > Authentication > URL Configuration > Redirect URLs
izin listesine tam olarak şu adresi ekleyin:

```text
com.mythosforgelabs.atlasworkout://login-callback
```

Bu adres hem Android manifestinde hem iOS URL scheme ayarlarında kayıtlıdır.
Flutter'ın yerleşik deep-link yönlendirmesi kapalıdır; auth callback'lerini
Supabase/app_links işler. Callback'i değiştirirseniz Flutter yapılandırmasını,
iki platformun native dosyalarını ve Supabase izin listesini birlikte güncelleyin.

```powershell
flutter run -d <device-id> `
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=<publishable-or-anon-key>
```

İsteğe bağlı `SUPABASE_AUTH_REDIRECT_URL` varsayılan callback'i değiştirebilir.
Release build komutlarına da aynı `--dart-define` değerlerini verin.
Publishable/anon anahtar istemciye dağıtılabilir; veri erişiminin sınırı
veritabanındaki kullanıcıya özel RLS politikalarıdır.

### Veri davranışı ve doğrulama

Misafir veritabanı ile her hesabın yerel veritabanı ayrıdır. Çıkış yapmak misafir
kayıtlarını başka hesabın verileriyle değiştirmez. Takvim tarihleri gün olarak
saklanır; saat dilimi değişiminde başka güne kaydırılmaz. Özel programların yerel
sayısal kimlikleri cihazlar arası kimlik olarak kullanılmaz.

Yedek dosyaları kişisel ölçümler ve antrenman geçmişi içerebilir; paylaşmadan önce
alıcıyı kontrol edin. Yedek içe aktarma ve veri sıfırlama aktif çalışma alanına
uygulanır; hesap açıkken bulut verilerine etkisi onay ekranında açıklanır.
Kimlik doğrulama token'ları ve sunucu sırları yedeklere dahil edilmez.

Üretime geçmeden önce ayrı iki kullanıcıyla özel verilerin birbirine kapalı
olduğunu, misafir aktarımını, çevrimdışı değişiklikleri, iki cihaz çakışmalarını
ve hesabın gerçekten silindiğini deneyin. Google/Apple akışlarını uygulama hem
kapalıyken hem açıkken Android/iOS cihazlarında doğrulayın. iOS imzalama ve
cihaz doğrulaması macOS/Xcode gerektirir; yalnızca yapılandırma dosyalarının
depoda bulunması sağlayıcıların canlı ortamda etkin olduğu anlamına gelmez.

Hesap silme Edge Function'ının yerel testleri (Deno):

```powershell
deno test --allow-env supabase\functions\delete-account\handler_test.ts
deno check supabase\functions\delete-account\index.ts
```

Migration uygulanmış, **yalnızca denemeye ayrılmış** bir PostgreSQL/Supabase
veritabanında sahiplik, yeniden deneme ve çakışma senaryoları:

```powershell
psql $env:TEST_DATABASE_URL -v ON_ERROR_STOP=1 -f test\supabase_account_sync_test.sql
```

Bu SQL dosyası veritabanı sahibi olarak çalıştırılır; senaryolarını `authenticated`
ve `anon` rolleriyle yürütür ve sonunda oluşturduğu kayıtları geri alır.

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
