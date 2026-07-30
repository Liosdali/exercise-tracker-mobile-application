// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Egzersiz Uygulaması';

  @override
  String get navHome => 'Ana Sayfa';

  @override
  String get navWorkouts => 'Antrenmanlar';

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
      'Bu dosya geçerli bir Exercise App yedeği değil.';

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
  String get workoutSummaryBackHomeButton => 'Ana Sayfaya Dön';
}
