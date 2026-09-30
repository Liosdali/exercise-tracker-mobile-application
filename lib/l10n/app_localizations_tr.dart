// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Atlas Workout';

  @override
  String get navHome => 'Ana Sayfa';

  @override
  String get navWorkouts => 'Antrenmanlar';

  @override
  String get navTeam => 'Ekip';

  @override
  String get navCalendar => 'Takvim';

  @override
  String get navExercises => 'Egzersizler';

  @override
  String get navProfile => 'Profil';

  @override
  String get commonSave => 'Kaydet';

  @override
  String get commonCancel => 'Vazgeç';

  @override
  String get commonDelete => 'Sil';

  @override
  String get commonEdit => 'Düzenle';

  @override
  String get commonAdd => 'Ekle';

  @override
  String get commonConfirm => 'Onayla';

  @override
  String get commonCopy => 'Kopyala';

  @override
  String get errorDetailsCopied => 'Hata ayrıntıları panoya kopyalandı';

  @override
  String get commonClose => 'Kapat';

  @override
  String get dashboardGreeting => 'Merhaba';

  @override
  String dashboardGreetingWithName(String name) {
    return 'Merhaba, $name';
  }

  @override
  String dashboardStreakActive(int count) {
    return '$count gün üst üste antrenman!';
  }

  @override
  String get dashboardStreakStart => 'Bugün antrenman yaparak seriye başla!';

  @override
  String get dashboardWeeklyGoalTitle => 'Haftalık Hedef';

  @override
  String dashboardWeeklyGoalCount(int done, int goal) {
    return '$done / $goal antrenman';
  }

  @override
  String get dashboardTodaysWorkoutTitle => 'Bugünün Antrenmanı';

  @override
  String get dashboardCompletedLabel => 'Tamamlandı';

  @override
  String get dashboardNoProgramSelected =>
      'Henüz bir program seçilmedi. Antrenmanlar sekmesinden bir program seçin.';

  @override
  String get dashboardManualAssignmentSubtitle =>
      'Bugün için atanmış antrenman';

  @override
  String get dashboardNextWorkoutSubtitle => 'Sıradaki antrenman';

  @override
  String get dashboardStartButton => 'Başla';

  @override
  String get dashboardTotalWorkoutsLabel => 'Toplam Antrenman';

  @override
  String get dashboardTotalVolumeLabel => 'Toplam Kaldırılan Ağırlık';

  @override
  String get dashboardMaxStreakLabel => 'En Uzun Seri';

  @override
  String get dashboardTotalDurationLabel => 'Toplam Yapılan Spor Süresi';

  @override
  String get profileTitle => 'Profil & İstatistikler';

  @override
  String get profileBadgesLabel => 'Rozetler';

  @override
  String get profileStreakLabel => 'Seri';

  @override
  String get profileWeeklyVolumeChartTitle =>
      'Haftalık Antrenman Süresi (Dakika)';

  @override
  String get profileAchievementsTitle => 'Başarımlar';

  @override
  String get profileCalendarLinkTitle => 'Antrenman Takvimi / Geçmiş';

  @override
  String get profileBodyMeasurementsTitle => 'Vücut Ölçümleri';

  @override
  String get profileNoMeasurements => 'Henüz ölçüm kaydı yok.';

  @override
  String measurementWeightValue(String value) {
    return '$value kg';
  }

  @override
  String measurementHeightValue(String value) {
    return '$value cm boy';
  }

  @override
  String measurementBodyFatValue(String value) {
    return '%$value yağ';
  }

  @override
  String measurementChestValue(String value) {
    return 'Göğüs $value cm';
  }

  @override
  String measurementWaistValue(String value) {
    return 'Bel $value cm';
  }

  @override
  String get accountViewMeasurementHistory => 'Ölçüm geçmişini görüntüle';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsLanguageSection => 'Dil';

  @override
  String get settingsLanguageSystem => 'Sistem varsayılanı';

  @override
  String get settingsLanguageTurkish => 'Türkçe';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsThemeSection => 'Tema';

  @override
  String get settingsThemeSystem => 'Sistem varsayılanı';

  @override
  String get settingsThemeLight => 'Açık';

  @override
  String get settingsThemeDark => 'Koyu';

  @override
  String get settingsWeeklyGoalLabel => 'Haftalık hedef (antrenman sayısı)';

  @override
  String get settingsRestTimerSound => 'Dinlenme sayacı sesi';

  @override
  String get settingsRestTimerVibration => 'Dinlenme sayacı titreşimi';

  @override
  String get settingsResetDataSection => 'Veriler';

  @override
  String get settingsResetDataButton => 'Verileri Sıfırla';

  @override
  String get settingsResetDataConfirmTitle => 'Emin misiniz?';

  @override
  String get settingsResetDataConfirmMessage =>
      'Bu işlem tüm antrenman geçmişini, özel program/rutinleri, vücut ölçümlerini ve başarımları kalıcı olarak siler. Bu işlem geri alınamaz.';

  @override
  String get settingsResetDataSuccess => 'Tüm veriler sıfırlandı.';

  @override
  String get settingsBackupSection => 'Yedekleme & Geri Yükleme';

  @override
  String get settingsBackupPrivacyNote =>
      'Verileriniz tamamen bu cihazda saklanmaktadır. Hesap veya bulut senkronizasyonu yoktur — telefonunuzu değiştirdiğinizde veya kaybettiğinizde geçmişinizi kaybetmemek için düzenli olarak yedek alın.';

  @override
  String get settingsBackupExportButton => 'Verileri Dışa Aktar (JSON)';

  @override
  String get settingsBackupExportSuccess =>
      'Yedek dosyası oluşturuldu — kaydetmek veya paylaşmak için bir konum seçin.';

  @override
  String get settingsBackupExportError =>
      'Yedek dosyası oluşturulamadı. Lütfen tekrar deneyin.';

  @override
  String get settingsBackupImportButton => 'Verileri İçe Aktar (JSON)';

  @override
  String get settingsBackupImportConfirmTitle =>
      'Tüm yerel veriler değiştirilsin mi?';

  @override
  String settingsBackupImportConfirmMessage(String counts) {
    return 'Bu yedeği içe aktarmak, mevcut antrenman geçmişinizi, programlarınızı ve ölçümlerinizi kalıcı olarak yedekteki verilerle ($counts) değiştirir. Bu işlem geri alınamaz.';
  }

  @override
  String get settingsBackupImportSuccess => 'Yedek başarıyla geri yüklendi.';

  @override
  String get settingsBackupImportInvalidFile =>
      'Bu dosya geçerli bir Atlas Workout yedeği değil.';

  @override
  String get settingsBackupImportError =>
      'Yedek geri yüklenemedi. Lütfen tekrar deneyin.';

  @override
  String get settingsAboutTitle => 'Hakkında';

  @override
  String get settingsDisclaimerButton => 'Sağlık & Sorumluluk Reddi';

  @override
  String get settingsDisclaimerTitle => 'Sağlık & Sorumluluk Reddi';

  @override
  String get settingsDisclaimerBody =>
      'Bu uygulama yalnızca genel fitness bilgisi ve antrenman takip araçları sunar; tıbbi tavsiye niteliği taşımaz. Herhangi bir yeni egzersiz programına başlamadan önce, özellikle mevcut bir sağlık probleminiz varsa, bir hekime danışın. Egzersiz doğası gereği yaralanma riski taşır — güvenli ve kendi sınırlarınız dahilinde egzersiz yapmaktan yalnızca siz sorumlusunuz. Geliştirici, bu uygulamanın kullanımından kaynaklanan herhangi bir yaralanma, kayıp veya zarardan sorumlu tutulamaz.';

  @override
  String get settingsDisclaimerClose => 'Anladım';

  @override
  String get settingsNotificationsSection => 'Bildirim Ayarları';

  @override
  String get settingsNotificationsMasterToggle => 'Bildirimleri Etkinleştir';

  @override
  String get settingsNotificationsStreakToggle => 'Seri kaybı uyarıları';

  @override
  String get settingsNotificationsStreakSubtitle =>
      'Serin sıfırlanmadan 2 gün ve 1 gün önce seni uyarır';

  @override
  String get settingsNotificationsDailyToggle =>
      'Günlük antrenman hatırlatıcısı';

  @override
  String get settingsNotificationsDailySubtitle =>
      'Bugünün antrenmanı tamamlanmadıysa saat 07:00\'de hatırlatır';

  @override
  String get settingsTutorialSection => 'Yardım';

  @override
  String get settingsReplayTutorialButton => 'Tanıtım Turunu Tekrar Göster';

  @override
  String get tutorialStartWorkoutTitle => 'Antrenman Başlat';

  @override
  String get tutorialStartWorkoutDescription =>
      'Günün önerilen antrenmanını buradan başlatıp setlerini kaydedebilirsin.';

  @override
  String get tutorialWorkoutsTabTitle => 'Antrenmanlar';

  @override
  String get tutorialWorkoutsTabDescription =>
      'Hazır programlara göz atabilir, kendi rutinini veya çok günlük programını oluşturabilirsin.';

  @override
  String get tutorialTeamTabTitle => 'Ekip';

  @override
  String get tutorialTeamTabDescription =>
      'Arkadaşlarınla bağlan, ilerlemenizi paylaş ve topluluğumuzda motivasyon bul.';

  @override
  String get tutorialCalendarTabTitle => 'Takvim';

  @override
  String get tutorialCalendarTabDescription =>
      'Antrenman geçmişini görebilir, gelecek antrenmanlarını takvimde planlayabilirsin.';

  @override
  String get tutorialExercisesTabTitle => 'Egzersizler';

  @override
  String get tutorialExercisesTabDescription =>
      'Kas gruplarına göre ayrılmış egzersiz kütüphanesine buradan ulaşabilirsin.';

  @override
  String get tutorialProfileTabTitle => 'Profil ve İstatistikler';

  @override
  String get tutorialProfileTabDescription =>
      'Serilerini, rozetlerini ve genel ilerlemeni burada takip edebilirsin.';

  @override
  String get tutorialSkipButton => 'Turu Atla';

  @override
  String get notificationStreakWarning2DaysTitle => 'Serin risk altında! 🔥';

  @override
  String notificationStreakWarning2DaysBody(int count) {
    return '$count günlük serin var. Serini kaybetmemek için 2 gün içinde antrenman yap!';
  }

  @override
  String get notificationStreakWarningLastDayTitle =>
      'Serini kurtarmak için son şans! ⚠️';

  @override
  String notificationStreakWarningLastDayBody(int count) {
    return '$count günlük serin, bugün antrenman yapmazsan yarın sıfırlanacak!';
  }

  @override
  String get notificationDailyReminderTitle =>
      'Bugünün antrenmanı seni bekliyor';

  @override
  String notificationDailyReminderBody(String programTitle, String dayName) {
    return '$programTitle - $dayName bugün için planlandı. Hadi tamamlayalım!';
  }

  @override
  String get aboutBodyText =>
      'Uygulama geliştirilme aşamasındadır. Düşünce ve fikirlerinizi [baykal246@gmail.com] mail adresine iletebilirsiniz. Geliştirici ve Yayınlayıcı Mete Baykal';

  @override
  String get calendarScreenTitle => 'Antrenman Takvimi';

  @override
  String get calendarAssignProgramButton => 'Program Ata';

  @override
  String get calendarClearAssignmentButton => 'Atamayı kaldır';

  @override
  String get calendarPlannedLabel => 'Planlandı';

  @override
  String get calendarChangeAssignmentButton => 'Atamayı Değiştir';

  @override
  String get calendarAddExerciseButton => 'Egzersiz Ekle';

  @override
  String get calendarCompletedChip => 'Tamamlandı';

  @override
  String get calendarNoProgramsSnackbar =>
      'Önce Antrenmanlar sekmesinden bir program oluşturun.';

  @override
  String get calendarChooseProgramTitle => 'Bir program seçin';

  @override
  String get calendarChooseDayTitle => 'Hangi gün?';

  @override
  String calendarAssignedLabel(String dayName) {
    return 'Atanmış: $dayName';
  }

  @override
  String get calendarNoEntriesMessage => 'Bu gün için kayıtlı egzersiz yok.';

  @override
  String calendarTotalDaysLabel(int count) {
    return '$count gün';
  }

  @override
  String exerciseDetailTargetLabel(String target) {
    return 'Hedef: $target';
  }

  @override
  String get exerciseDetailSecondaryMusclesTitle => 'İkincil kaslar';

  @override
  String get exerciseDetailInstructionsTitle => 'Nasıl Yapılır?';

  @override
  String get exerciseDetailLogButton => 'Egzersizi Kaydet';

  @override
  String get exercisePickerTitle => 'Egzersiz Seç';

  @override
  String get exerciseSearchLabel => 'Egzersiz ara';

  @override
  String get exercisePickerAllChip => 'Tümü';

  @override
  String get exerciseSearchNoResults => 'Egzersiz bulunamadı.';

  @override
  String get logEntryTitleAdd => 'Antrenman Kaydet';

  @override
  String get logEntryTitleEdit => 'Kaydı Düzenle';

  @override
  String get logEntryDateLabel => 'Tarih';

  @override
  String get logEntrySetsLabel => 'Set';

  @override
  String get logEntryRepsLabel => 'Tekrar';

  @override
  String get logEntryWeightLabel => 'Ağırlık (kg, opsiyonel)';

  @override
  String get logEntryNotesLabel => 'Notlar (opsiyonel)';

  @override
  String get logEntrySaveEntryButton => 'Kaydı Kaydet';

  @override
  String get logEntrySaveChangesButton => 'Değişiklikleri Kaydet';

  @override
  String get programBuilderPickerTitle => 'Egzersiz Seç';

  @override
  String get programBuilderSetsLabel => 'Set';

  @override
  String get programBuilderRepsLabel => 'Tekrar';

  @override
  String get programBuilderRemoveButton => 'Kaldır';

  @override
  String get achievementFirstWorkoutTitle => 'İlk Adım';

  @override
  String get achievementFirstWorkoutDesc => 'İlk antrenmanını kaydet.';

  @override
  String get achievementTenWorkoutsTitle => 'Kararlılık';

  @override
  String get achievementTenWorkoutsDesc => '10 antrenman günü tamamla.';

  @override
  String get achievementFiftyWorkoutsTitle => 'Alışkanlık';

  @override
  String get achievementFiftyWorkoutsDesc => '50 antrenman günü tamamla.';

  @override
  String get achievementHundredWorkoutsTitle => 'Yüzler Kulübü';

  @override
  String get achievementHundredWorkoutsDesc => '100 antrenman günü tamamla.';

  @override
  String get achievementStreak3Title => '3 Gün Üst Üste!';

  @override
  String get achievementStreak3Desc => '3 gün üst üste antrenman yap.';

  @override
  String get achievementStreak7Title => 'Haftalık Seri';

  @override
  String get achievementStreak7Desc => '7 gün üst üste antrenman yap.';

  @override
  String get achievementStreak30Title => 'Demir İrade';

  @override
  String get achievementStreak30Desc => '30 gün üst üste antrenman yap.';

  @override
  String get achievementVolume10000Title => 'İlk 10.000 kg';

  @override
  String get achievementVolume10000Desc => 'Toplamda 10.000 kg hacim kaldır.';

  @override
  String get achievementVolume100000Title => 'İlk 100.000 kg';

  @override
  String get achievementVolume100000Desc => 'Toplamda 100.000 kg hacim kaldır.';

  @override
  String get achievementMinutes60Title => 'İlk Saat';

  @override
  String get achievementMinutes60Desc => 'Toplamda 60 dakika antrenman yap.';

  @override
  String get achievementMinutes600Title => 'Zaman Ustası';

  @override
  String get achievementMinutes600Desc => 'Toplamda 600 dakika antrenman yap.';

  @override
  String get achievementCalories1000Title => 'İlk 1000 kalori';

  @override
  String get achievementCalories1000Desc => 'Toplamda 1000 kalori yak.';

  @override
  String get achievementCalories10000Title => '10.000 Kalori Kulübü';

  @override
  String get achievementCalories10000Desc => 'Toplamda 10.000 kalori yak.';

  @override
  String get achievementSets100Title => 'Yüz Set';

  @override
  String get achievementSets100Desc => 'Toplamda 100 set tamamla.';

  @override
  String get achievementSets1000Title => 'Bin Set';

  @override
  String get achievementSets1000Desc => 'Toplamda 1000 set tamamla.';

  @override
  String get programLevelBeginner => 'Başlangıç';

  @override
  String get programLevelIntermediate => 'Orta';

  @override
  String get programLevelAdvanced => 'İleri';

  @override
  String get programFullBodyName => 'Full Body (Başlangıç)';

  @override
  String get programFullBodyDescription =>
      'Haftada 2-3 kez uygulanabilecek, tüm vücudu çalıştıran temel bir antrenman programı. Barbell ve dumbbell ekipmanı gerektirir.';

  @override
  String get programFullBodyDay1 => 'Tüm Vücut';

  @override
  String get programHomeBodyweightName => 'Evde Ekipmansız (Orta)';

  @override
  String get programHomeBodyweightDescription =>
      'Hiçbir ekipman gerektirmeyen, evde uygulanabilecek 3 günlük vücut ağırlığı antrenman programı.';

  @override
  String get programHomeBodyweightDay1 => 'Gün 1 - Üst Vücut';

  @override
  String get programHomeBodyweightDay2 => 'Gün 2 - Alt Vücut & Core';

  @override
  String get programHomeBodyweightDay3 => 'Gün 3 - Kardiyo & Tüm Vücut';

  @override
  String get programPplName => 'Push-Pull-Legs (İleri)';

  @override
  String get programPplDescription =>
      'Haftada 3-6 kez uygulanabilecek, itiş/çekiş/bacak olarak ayrılmış ileri seviye bir split antrenman programı.';

  @override
  String get programPplDay1 => 'Push (İtiş)';

  @override
  String get programPplDay2 => 'Pull (Çekiş)';

  @override
  String get programPplDay3 => 'Legs (Bacak)';

  @override
  String workoutsAddedSnackbar(String name) {
    return '\"$name\" programı eklendi.';
  }

  @override
  String workoutsDaysCountLabel(int count) {
    return '$count günlük program';
  }

  @override
  String get workoutsProgramsSectionTitle => 'Programlar';

  @override
  String get workoutsMyProgramsSectionTitle => 'Programlarım';

  @override
  String get workoutsMyRoutinesSectionTitle => 'Rutinlerim';

  @override
  String get workoutsNewProgramButton => 'Yeni Program';

  @override
  String get workoutsNewRoutineButton => 'Yeni Rutin';

  @override
  String get workoutsImportCodeButton => 'Kod ile Ekle';

  @override
  String get workoutsImportDialogTitle => 'Kod ile Program Ekle';

  @override
  String get workoutsImportDialogHint => 'Program kodunu buraya yapıştırın';

  @override
  String get workoutsImportConfirmButton => 'İçe Aktar';

  @override
  String get workoutsNoCustomProgramsMessage =>
      'Henüz çok günlü bir program oluşturmadınız.';

  @override
  String get workoutsNoCustomRoutinesMessage =>
      'Henüz özel bir rutin oluşturmadınız.';

  @override
  String get workoutsActivateProgramMenuItem => 'Aktif Program Yap';

  @override
  String get workoutsEditMenuItem => 'Düzenle';

  @override
  String get workoutsDeleteMenuItem => 'Sil';

  @override
  String workoutsExerciseCountLabel(int count) {
    return '$count egzersiz';
  }

  @override
  String get programDetailShareTooltip => 'Programı Paylaş';

  @override
  String get programDetailActiveProgramChip => 'Aktif Program';

  @override
  String get programDetailAlreadyActiveButton => 'Bu program aktif';

  @override
  String get programDetailTodayDoneLabel => 'Bugün tamamlandı';

  @override
  String get programDetailSuggestedSuffix => ' (Sıradaki)';

  @override
  String programDetailCustomDescription(int count) {
    return 'Kullanıcı tarafından oluşturulan $count günlük program.';
  }

  @override
  String programDetailShareMessage(String name) {
    return 'Atlas Workout antrenman programımı deneyin: \"$name\"';
  }

  @override
  String programBuilderDayDefaultName(int number) {
    return 'Gün $number';
  }

  @override
  String get programBuilderValidationMessage =>
      'Bir program adı girin ve en az bir güne egzersiz ekleyin.';

  @override
  String get programBuilderNewProgramTitle => 'Yeni Program';

  @override
  String get programBuilderEditProgramTitle => 'Programı Düzenle';

  @override
  String get programBuilderAddDayButton => 'Gün Ekle';

  @override
  String get programBuilderProgramNameLabel => 'Program adı';

  @override
  String get programBuilderDayNameLabel => 'Gün adı';

  @override
  String programBuilderExercisesSelectedLabel(int count) {
    return '$count egzersiz seçildi';
  }

  @override
  String get programBuilderEditExercisesButton => 'Egzersizleri Düzenle';

  @override
  String get routineBuilderValidationMessage =>
      'Bir isim girin ve en az bir egzersiz seçin.';

  @override
  String get routineBuilderNewRoutineTitle => 'Yeni Rutin';

  @override
  String get routineBuilderEditRoutineTitle => 'Rutini Düzenle';

  @override
  String get routineBuilderNameLabel => 'Rutin adı';

  @override
  String activeWorkoutExerciseCountLabel(int current, int total) {
    return 'Egzersiz $current/$total';
  }

  @override
  String activeWorkoutSetProgressLabel(int current, int total, int reps) {
    return 'Set $current/$total • Hedef: $reps tekrar';
  }

  @override
  String get activeWorkoutRepsLabel => 'Tekrar';

  @override
  String get activeWorkoutWeightLabel => 'Ağırlık (kg)';

  @override
  String get activeWorkoutFinishButton => 'Antrenmanı Bitir';

  @override
  String get activeWorkoutCompleteSetButton => 'Seti Tamamla';

  @override
  String activeWorkoutNotesLabel(String title) {
    return 'Antrenman: $title';
  }

  @override
  String get workoutSummaryTitle => 'Antrenman Tamamlandı';

  @override
  String get workoutSummaryDurationLabel => 'Süre';

  @override
  String workoutSummaryDurationValue(int minutes) {
    return '$minutes dk';
  }

  @override
  String get workoutSummaryCaloriesLabel => 'Tahmini kalori';

  @override
  String feedCaloriesValue(int calories) {
    return '$calories kcal';
  }

  @override
  String get workoutSummaryBackHomeButton => 'Ana Sayfaya Dön';

  @override
  String get accountTitle => 'Hesap';

  @override
  String get accountGuest => 'Misafir';

  @override
  String get accountGuestDescription =>
      'Misafir verileriniz bu cihazda kalır. Cihazlar arasında özel eşitleme için giriş yapın.';

  @override
  String get accountSignedIn => 'Giriş yapıldı';

  @override
  String get accountEditProfile => 'Kişisel profili düzenle';

  @override
  String get accountGoogle => 'Google ile devam et';

  @override
  String get accountApple => 'Apple ile devam et';

  @override
  String get accountConfigurationError =>
      'Hesap özelliği kullanılamıyor: SUPABASE_URL ve SUPABASE_ANON_KEY doğru yapılandırılmalıdır. Misafir modunu çevrimdışı kullanabilirsiniz.';

  @override
  String get accountMobileOnly =>
      'Google ve Apple ile giriş Android ve iOS\'ta kullanılabilir.';

  @override
  String get accountLoginError =>
      'Giriş başarısız. Bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get accountLoginCancelled =>
      'Giriş iptal edildi veya zaman aşımına uğradı. Yerel verileriniz değişmedi.';

  @override
  String get accountSessionExpired =>
      'Oturumunuz yenilenmeli. Eşitlemek için tekrar giriş yapın; kayıtlı verileriniz çevrimdışı kullanılabilir.';

  @override
  String get accountOperationError =>
      'İşlem tamamlanamadı. Kayıtlı verileriniz korunuyor. Lütfen tekrar deneyin.';

  @override
  String get accountWorkspaceError =>
      'Yerel çalışma alanınız açılamadı. Verilerinizi güvenle yüklemek için tekrar deneyin.';

  @override
  String get accountRetry => 'Tekrar dene';

  @override
  String get accountBrowserWaiting =>
      'Girişi tarayıcınızda tamamlayın. Tarayıcıyı kapattıysanız tekrar denemek için buradan iptal edin.';

  @override
  String get accountGuestImportTitle => 'Misafir verileri aktarılsın mı?';

  @override
  String get accountGuestImportMessage =>
      'Bu cihazdaki misafir antrenmanları, programları, profili ve geçmişi bu hesaba kopyalansın mı? Yalnızca size ait verileri aktarın. Misafir verileri ayrı tutulur; aktarılan veriler özel hesabınıza yüklenebilir.';

  @override
  String get accountGuestImportAccept => 'Misafir verilerimi aktar';

  @override
  String get accountGuestImportDecline => 'Misafir verilerini ayrı tut';

  @override
  String get accountSyncing => 'Özel hesap verileri eşitleniyor…';

  @override
  String accountPending(int count) {
    return '$count bekleyen değişiklik';
  }

  @override
  String get accountSyncError =>
      'Eşitleme başarısız. Değişiklikleriniz bu cihazda kayıtlı. Bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get accountSyncNow => 'Eşitle / tekrar dene';

  @override
  String accountConflicts(int count) {
    return 'Çakışmaları çöz ($count)';
  }

  @override
  String get accountSignOut => 'Çıkış yap';

  @override
  String accountSignOutWarning(int count, int conflicts) {
    return '$count bekleyen değişiklik ve $conflicts çözülmemiş çakışma var. Eşitlenmemiş veriler ve çakışmaların her iki sürümü bu cihazdaki hesabınıza ait alanda kalır, ancak henüz diğer cihazlarda bulunmayabilir. Çıkış yapıp ayrı misafir alanına dönmek istiyor musunuz?';
  }

  @override
  String get accountProfileOptional =>
      'Tüm alanlar isteğe bağlıdır. Giriş için yaş ve ölçüler gerekli değildir. Değişiklikler geçerli çalışma alanınıza kaydedilir.';

  @override
  String get accountName => 'İsim';

  @override
  String get accountAge => 'Yaş (isteğe bağlı)';

  @override
  String get accountWeight => 'Kilo (kg, isteğe bağlı)';

  @override
  String get accountHeight => 'Boy (cm, isteğe bağlı)';

  @override
  String get accountGender => 'Cinsiyet (isteğe bağlı)';

  @override
  String get accountGenderUnspecified => 'Belirtmek istemiyorum';

  @override
  String get accountGenderFemale => 'Kadın';

  @override
  String get accountGenderMale => 'Erkek';

  @override
  String get accountGenderOther => 'Diğer';

  @override
  String get accountAgeInvalid =>
      'Negatif olmayan bir tam sayı girin veya boş bırakın.';

  @override
  String get accountMeasurementInvalid =>
      'Sıfırdan büyük, sonlu bir sayı girin veya boş bırakın.';

  @override
  String get accountDelete => 'Hesabı sil';

  @override
  String get accountDeleteSummary =>
      'Hesabınızı ve sunucudaki verilerinizi kalıcı olarak silin.';

  @override
  String get accountDeleteWarning =>
      'Bu hesap ve sunucudaki tüm özel ve sosyal verileri kalıcı olarak silinsin mi? Bekleyen yerel değişiklikler de silinir. Misafir verileri ayrıdır. Bu işlem geri alınamaz ve bağlantı gerektirir. Apple\'a bağlıysa silme tamamlanmadan önce Apple yetkisinin sunucuda iptal edilmesi gerekir.';

  @override
  String get accountDeleteError =>
      'Hesap silme tamamlanamadı. Başarı onaylanmadı. Bağlanıp tekrar deneyin; Apple yetkisi iptal edilemiyorsa destekle iletişime geçin.';

  @override
  String get accountCloudResetWarning =>
      'Yalnızca giriş yapılan hesabın çalışma alanı sıfırlanır. Silme işlemleri bu hesabın diğer cihazlarına eşitlenir. Misafir verileri ve diğer hesaplar etkilenmez.';

  @override
  String get accountCloudImportWarning =>
      'Giriş yapılan hesabın çalışma alanındaki veriler değiştirilir. Aktarılan değişiklikler ve silmeler bu hesabın diğer cihazlarına eşitlenir. Misafir verileri ve diğer hesaplar etkilenmez.';

  @override
  String accountPendingLossWarning(int count, int conflicts) {
    return '$count değişiklik henüz buluta ulaşmadı ve $conflicts çakışma çözülmedi. Bunlar burada silinir ve diğer cihazlarınıza hiçbir zaman ulaşmaz. Korumak istiyorsanız önce eşitleyin.';
  }

  @override
  String get accountGuestResetWarning =>
      'Yalnızca bu cihazın misafir çalışma alanı etkilenir. Giriş yapılan hesapların alanları değişmez.';

  @override
  String get accountBackupScope =>
      'Dışa aktarma yalnızca geçerli çalışma alanını içerir; giriş belirteçlerini veya kimlik bilgilerini içermez. Yedekleri gizli tutun: kişisel profil ve sağlık verileri içerebilir.';

  @override
  String get accountWelcome => 'Hoş geldin!';

  @override
  String get accountOnboardingName => 'Sana nasıl hitap edelim? (İsteğe bağlı)';

  @override
  String get accountContinue => 'Devam et';

  @override
  String get accountSkip => 'Atla';

  @override
  String get accountDeletionCleanupError =>
      'Sunucudaki hesabınız silindi, ancak cihaz temizliği tamamlanamadı. Yerel verilerini ve giriş bilgilerini güvenle kaldırmak için tekrar deneyin.';

  @override
  String get syncConflictsTitle => 'Eşitleme çakışmalarını çöz';

  @override
  String get syncConflictResolveError =>
      'Çakışma çözülemedi. Her iki sürüm de korunuyor; bağlanıp tekrar deneyin.';

  @override
  String get syncNoConflicts => 'Çözülmemiş çakışma yok.';

  @override
  String get syncConflictDeleted => 'Silinen kayıt';

  @override
  String get syncLocalVersion => 'Bu cihazdaki sürüm';

  @override
  String get syncRemoteVersion => 'Hesabın sunucudaki sürümü';

  @override
  String get syncKeepLocal => 'Cihaz sürümünü kullan';

  @override
  String get syncKeepRemote => 'Sunucu sürümünü kullan';

  @override
  String get accountDeletedSuccess =>
      'Hesabınız sunucudan silindi ve yerel verileri kaldırıldı. Ayrı misafir verileriniz değişmedi.';

  @override
  String get accountContinueAsGuest => 'Misafir olarak devam et';

  @override
  String get accountAppleReauthentication =>
      'Silmeden önce Apple yetkisi iptal edilmelidir. Android\'de tekrar Apple ile giriş yapın, ardından hesabı silmeyi tekrar deneyin. Apple yenileme belirteci sağlamazsa iOS cihazı kullanın veya destekle iletişime geçin. Hesap verileri silinmedi.';

  @override
  String get accountAppleReauthenticateButton => 'Apple ile yeniden doğrula';

  @override
  String get accountDeletionCancelled =>
      'Hesap silme iptal edildi. Hesabınız ve verileriniz değişmedi.';

  @override
  String get accountDeletionUnavailable =>
      'Sunucuda hesap silme yapılandırılmamış. Silmeyi tamamlamak için destekle iletişime geçin. Hesabınız ve verileriniz silinmedi.';

  @override
  String get accountAppleMismatch =>
      'Bu Apple hesabı, geçerli hesabınıza bağlı Apple kimliğiyle eşleşmiyor. Doğru Apple hesabıyla yeniden doğrulayıp tekrar deneyin. Hiçbir veri silinmedi.';

  @override
  String get syncRelatedRecordsNotice =>
      'Bu çakışma, ilişkili antrenman kayıtlarını da içerir. Seçtiğiniz sürüm grubun tamamına uygulanır.';

  @override
  String get conflictFieldName => 'İsim';

  @override
  String get conflictFieldTitle => 'Başlık';

  @override
  String get conflictFieldNotes => 'Not';

  @override
  String get conflictFieldWeight => 'Kilo';

  @override
  String get conflictFieldHeight => 'Boy';

  @override
  String get conflictFieldAge => 'Yaş';

  @override
  String get conflictFieldGender => 'Cinsiyet';

  @override
  String get conflictFieldBodyFat => 'Vücut yağı';

  @override
  String get conflictFieldChest => 'Göğüs';

  @override
  String get conflictFieldWaist => 'Bel';

  @override
  String get conflictFieldNeck => 'Boyun';

  @override
  String get conflictFieldHip => 'Kalça';

  @override
  String get conflictFieldExercise => 'Egzersiz';

  @override
  String get conflictFieldCategory => 'Kategori';

  @override
  String get conflictFieldDuration => 'Süre (dakika)';

  @override
  String get conflictFieldDays => 'Günler';

  @override
  String get conflictFieldExercises => 'Egzersizler';

  @override
  String get conflictFieldDayName => 'Gün';

  @override
  String get conflictFieldValue => 'Değer';

  @override
  String get conflictFieldUnlockedAt => 'Kazanıldı';

  @override
  String get conflictFieldProgram => 'Program';

  @override
  String get conflictFieldNextDay => 'Sonraki gün';

  @override
  String get conflictFieldLastCompleted => 'Son tamamlanan';

  @override
  String get syncConflictOriginBoth =>
      'Her iki sürüm de son eşitlemeden beri değişti.';

  @override
  String get syncConflictOriginLocalOnly =>
      'Bu kaydı yalnızca bu cihaz değiştirdi.';

  @override
  String get syncConflictOriginRemoteOnly =>
      'Bu kaydı yalnızca sunucu değiştirdi.';

  @override
  String syncConflictFieldsDiffer(int count, String fields) {
    return '$count alan farklı ($fields)';
  }

  @override
  String get syncConflictNoVisibleDifference =>
      'Görünen bilgiler aynı; yalnızca dahili eşitleme verisi farklı.';

  @override
  String get syncConflictDeletedLocally =>
      'Bu cihazda silindi · Sunucuda duruyor';

  @override
  String get syncConflictDeletedRemotely =>
      'Sunucuda silindi · Bu cihazda duruyor';

  @override
  String get syncConflictDeletedBoth => 'Her iki sürüm de bu kaydı siliyor.';

  @override
  String get syncConflictDeleteWarning =>
      'Silinmiş sürümü seçmek bu kaydı kalıcı olarak kaldırır.';

  @override
  String syncConflictCollectionCount(String from, String to) {
    return '$from → $to';
  }

  @override
  String get syncConflictCollectionOrder => 'Sıra değişti';

  @override
  String syncConflictCollectionMembers(String removed, String added) {
    return '$removed yerine $added';
  }

  @override
  String syncConflictCollectionContent(int count, String names) {
    return '$count tanesi değişti ($names)';
  }

  @override
  String syncConflictGroupSummary(int count) {
    return 'Bu seçim ilişkili $count kaydın tamamına uygulanır.';
  }

  @override
  String get syncConflictShowDetails => 'Ayrıntıları göster';

  @override
  String syncConflictDetailsWithCount(int count) {
    return 'Ayrıntılar ($count kayıt)';
  }

  @override
  String get syncConflictRawData => 'Ham veri';

  @override
  String syncConflictModifiedOn(String date) {
    return '$date tarihinde düzenlendi';
  }

  @override
  String get syncConflictNewer => 'daha yeni';

  @override
  String get syncConflictValueOn => 'Açık';

  @override
  String get syncConflictValueOff => 'Kapalı';

  @override
  String get teamCreateTeam => 'Ekip Oluştur';

  @override
  String get teamJoinTeam => 'Ekibe Katıl';

  @override
  String get teamEmptyTitle => 'Henüz Ekip Yok';

  @override
  String get teamEmptyDescription =>
      'Arkadaşlarla bağlantı kurmak için yeni bir ekip oluşturun veya davet koduyla mevcut bir ekibe katılın.';

  @override
  String get teamCreateDescription =>
      'Arkadaşlarla işbirliği yapmak ve antrenmanları birlikte takip etmek için yeni bir ekip oluşturun.';

  @override
  String get teamNameLabel => 'Ekip Adı';

  @override
  String get teamNameRequired => 'Lütfen bir ekip adı girin';

  @override
  String get teamDescriptionLabel => 'Ekip Açıklaması';

  @override
  String get teamCreatedSuccess => 'Ekip başarıyla oluşturuldu!';

  @override
  String get teamCreateNote =>
      'Siz otomatik olarak ekip yöneticisi olarak eklenir ve paylaşabileceğiniz bir davet kodu alırsınız.';

  @override
  String get teamColorLabel => 'Takım rengi';

  @override
  String get teamColorHint =>
      'Takımının sıralamalarda ve akışta taşıyacağı rengi seç.';

  @override
  String get teamColorChangeAction => 'Rengi değiştir';

  @override
  String get teamColorUpdated => 'Takım rengi güncellendi';

  @override
  String get teamColorUpdateError => 'Takım rengi güncellenemedi';

  @override
  String get kitColorCrimson => 'Kızıl';

  @override
  String get kitColorClaret => 'Bordo';

  @override
  String get kitColorViolet => 'Mor';

  @override
  String get kitColorRoyal => 'Kraliyet mavisi';

  @override
  String get kitColorTeal => 'Camgöbeği';

  @override
  String get kitColorForest => 'Orman yeşili';

  @override
  String get kitColorGold => 'Altın';

  @override
  String get kitColorSteel => 'Çelik';

  @override
  String get teamJoinDescription =>
      'Mevcut bir ekibe katılmak için davet kodunu girin. Bu kodu ekip sahibinden alabilirsiniz.';

  @override
  String get teamInviteCodeLabel => 'Davet Kodu';

  @override
  String get teamCodeRequired => 'Lütfen bir davet kodu girin';

  @override
  String get teamInviteCodeHint =>
      'Başkalarını ekibinize davet etmek için bu kodu paylaşın';

  @override
  String get teamInviteCodeTip => 'Davet kodunu bulma ipuçları:';

  @override
  String get teamInviteCodeTip1 =>
      'Ekip sahibinden ekip ayarlarından davet kodunu paylaşmasını isteyin';

  @override
  String get teamInviteCodeTip2 =>
      'Kod genellikle 8 karakter uzunluğunda ve tümü büyük harftir';

  @override
  String get teamCodeInvalid =>
      'Geçersiz davet kodu. Lütfen kontrol edin ve tekrar deneyin.';

  @override
  String get teamAlreadyMember => 'Zaten bu ekibin üyesisiniz.';

  @override
  String get teamJoinError =>
      'Ekibe katılırken hata oluştu. Lütfen tekrar deneyin.';

  @override
  String teamJoinedSuccess(String teamName) {
    return '$teamName adlı ekibe başarıyla katıldınız!';
  }

  @override
  String get teamMembers => 'Üyeler';

  @override
  String teamMemberCount(num count) {
    return '$count üye';
  }

  @override
  String get teamNoMembers => 'Henüz üye yok';

  @override
  String get teamAdmin => 'Yönetici';

  @override
  String get teamInviteMembers => 'Üyeleri Davet Et';

  @override
  String get teamInviteCode => 'Davet Kodu';

  @override
  String get teamInviteLink => 'Davet Linki';

  @override
  String get teamCodeCopied => 'Davet kodu panoya kopyalandı';

  @override
  String get teamLeave => 'Ekipten Çık';

  @override
  String get teamLeaveConfirmTitle => 'Ekipten Çık';

  @override
  String teamLeaveConfirmMessage(String teamName) {
    return '$teamName adlı ekipten çıkmak istediğinizden emin misiniz?';
  }

  @override
  String get teamLeftSuccess => 'Ekipten çıktınız';

  @override
  String get teamLeaveError =>
      'Ekipten çıkarken hata oluştu. Lütfen tekrar deneyin.';

  @override
  String get teamDeleteConfirmTitle => 'Ekibi Sil';

  @override
  String teamDeleteConfirmMessage(String teamName) {
    return '$teamName adlı ekibi silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.';
  }

  @override
  String get teamDeletedSuccess => 'Ekip başarıyla silindi';

  @override
  String get teamDeleteError =>
      'Ekip silinirken hata oluştu. Lütfen tekrar deneyin.';

  @override
  String get teamSelectTeam => 'Bir ekip seçin';

  @override
  String get teamSignInRequired =>
      'Ekip kurmak veya bir ekibe katılmak için giriş yapın. Misafir antrenmanlarınız bu cihazda kalır.';

  @override
  String get teamLoadError =>
      'Ekipleriniz yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get teamFeedError =>
      'Aktivite akışı yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get teamMyTeams => 'Ekiplerim';

  @override
  String get teamShareInvite => 'Davet Linkini Paylaş';

  @override
  String get teamLinkCopied => 'Davet linki panoya kopyalandı';

  @override
  String get suggestionInbox => 'Öneriler';

  @override
  String teamInviteMessage(String teamName) {
    return 'Atlas Workout\'ta $teamName ekibime katıl!';
  }

  @override
  String get teamAllMembers => 'Tüm Üyeler';

  @override
  String get teamNoActivity =>
      'Henüz sosyal aktivite yok.\nBir ekibe katılın veya arkadaş davet edin!';

  @override
  String get teamActivity => 'Ekip Aktivitesi';

  @override
  String get teamActivityWorkouts => 'Antrenmanlar';

  @override
  String get teamActivityCalories => 'Kalori';

  @override
  String get teamActivityMinutes => 'Dakika';

  @override
  String get memberActivityDetail => 'Üye Aktivite Detayları';

  @override
  String get teamMember => 'Ekip Üyesi';

  @override
  String get actionSuggest => 'Öner';

  @override
  String get suggestionTitle => 'Program Değişikliği Öner';

  @override
  String get teamLeaderboard => 'Liderlik Tablosu';

  @override
  String get leaderboardWeekly => 'Haftalık';

  @override
  String get leaderboardMonthly => 'Aylık';

  @override
  String get leaderboardMetricWorkouts => 'Antrenmanlar';

  @override
  String get leaderboardMetricWeight => 'Kaldırılan Ağırlık';

  @override
  String get leaderboardMetricCalories => 'Kalori';

  @override
  String get leaderboardEmpty => 'Liderlik tablosu boş';

  @override
  String get leaderboardWorkouts => 'antrenman';

  @override
  String get leaderboardRank => 'Sıra';

  @override
  String get leaderboardStats => 'İstatistikler';

  @override
  String get actionCancel => 'İptal';

  @override
  String get suggestionPending => 'Beklemede';

  @override
  String get suggestionAccepted => 'Kabul Edildi';

  @override
  String get suggestionRejected => 'Reddedildi';

  @override
  String get suggestionNoPending => 'Beklemede olan öneri yok';

  @override
  String get suggestionNone => 'Öneri yok';

  @override
  String get suggestionNoMessage => '(Mesaj sağlanmadı)';

  @override
  String get suggestionStatusPending => 'Beklemede';

  @override
  String get suggestionStatusAccepted => 'Kabul Edildi';

  @override
  String get suggestionStatusRejected => 'Reddedildi';

  @override
  String get suggestionDetail => 'Öneri Detayları';

  @override
  String get suggestionType => 'Tür';

  @override
  String get suggestionMessage => 'Mesaj';

  @override
  String get suggestionYourResponse => 'Sizin Cevabınız';

  @override
  String get suggestionResponseHint => 'İsteğe bağlı bir cevap ekleyin';

  @override
  String get suggestionTheirResponse => 'Onların Cevabı';

  @override
  String get suggestionReject => 'Reddet';

  @override
  String get suggestionAccept => 'Kabul Et';

  @override
  String get suggestionAcceptedSuccess => 'Öneri kabul edildi!';

  @override
  String get suggestionRejectedSuccess => 'Öneri reddedildi!';

  @override
  String get suggestionTypeExercise => 'Egzersiz';

  @override
  String get suggestionTypeProgram => 'Program Değişikliği';

  @override
  String get suggestionTypeFeedback => 'Geri Bildirim';

  @override
  String feedReportUser(String userName) {
    return '$userName kullanıcısını şikayet et';
  }

  @override
  String feedBlockUser(String userName) {
    return '$userName kullanıcısını engelle';
  }

  @override
  String get feedReportSuccess =>
      'Kullanıcı şikayet edildi. Şikayetler 24 saat içinde incelenir.';

  @override
  String get feedBlockSuccess =>
      'Kullanıcı engellendi. Artık etkinliklerini görmeyeceksin.';

  @override
  String get feedReportError => 'Şikayet gönderilemedi. Lütfen tekrar dene.';

  @override
  String get feedBlockError => 'Kullanıcı engellenemedi. Lütfen tekrar dene.';

  @override
  String get settingsPrivacyPolicy => 'Gizlilik politikası';

  @override
  String get settingsTermsOfUse => 'Kullanım koşulları';

  @override
  String get legalLinkOpenError =>
      'Sayfa açılamadı. Bağlantını kontrol edip tekrar dene.';

  @override
  String get communityTermsTitle => 'Topluluk kuralları';

  @override
  String get communityTermsBody =>
      'Ekipler, etkinliklerini başka kişilerle paylaşmanı sağlar. Devam etmeden önce kullanım koşullarını kabul edersin: taciz edici, nefret içeren, cinsel ya da başka şekilde uygunsuz içerik ve taciz kesinlikle yasaktır. Bu kuralları ihlal eden içerik kaldırılır, ilgili hesaplar kapatılabilir. Akıştaki herhangi bir kullanıcıyı, gönderisinden şikayet edebilir veya engelleyebilirsin.';

  @override
  String get communityTermsRead => 'Kullanım koşullarını oku';

  @override
  String get communityTermsAccept => 'Kabul ediyorum';

  @override
  String get communityTermsDecline => 'Şimdi değil';
}
