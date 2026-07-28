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
  String get dashboardGreeting => 'Merhaba! 👋';

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
}
