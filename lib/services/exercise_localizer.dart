/// Dynamic language layer for the (English-only) bundled exercise dataset.
///
/// The local dataset stores exercise `body_part`/`category` and `equipment`
/// as a small fixed set of English enum-like values, and per-exercise
/// `instructions`/`instruction_steps` are already authored in multiple
/// languages (including Turkish) directly in `exercises.json`. This service
/// centralizes the "SELECT CASE WHEN language = 'tr' THEN ... ELSE ..."
/// style lookup so screens can request a localized label for the current
/// app language without duplicating translation tables everywhere.
///
/// Exercise *names* are not pre-translated in the dataset (~1300 entries),
/// so [localizedName] applies a best-effort dictionary-based term
/// substitution for common gym vocabulary when Turkish is active, falling
/// back to the original English name for any term it doesn't recognize.
class ExerciseLocalizer {
  ExerciseLocalizer._();

  static const Map<String, String> _bodyPartTr = {
    'waist': 'Karın / Bel',
    'upper legs': 'Üst Bacak',
    'lower legs': 'Alt Bacak',
    'back': 'Sırt',
    'chest': 'Göğüs',
    'upper arms': 'Üst Kol',
    'lower arms': 'Alt Kol',
    'cardio': 'Kardiyo',
    'shoulders': 'Omuz',
    'neck': 'Boyun',
  };

  static const Map<String, String> _equipmentTr = {
    'body weight': 'Vücut Ağırlığı',
    'cable': 'Kablo',
    'leverage machine': 'Kaldıraç Makinesi',
    'assisted': 'Destekli',
    'medicine ball': 'Sağlık Topu',
    'stability ball': 'Denge Topu',
    'band': 'Direnç Bandı',
    'barbell': 'Halter',
    'rope': 'Halat',
    'dumbbell': 'Dambıl',
    'ez barbell': 'EZ Bar',
    'sled machine': 'Kızak Makinesi',
    'upper body ergometer': 'Üst Vücut Ergometresi',
    'kettlebell': 'Kettlebell',
    'olympic barbell': 'Olimpik Halter',
    'weighted': 'Ağırlıklı',
    'bosu ball': 'Bosu Topu',
    'resistance band': 'Direnç Lastiği',
    'roller': 'Silindir',
    'skierg machine': 'SkiErg Makinesi',
    'hammer': 'Çekiç Tipi Makine',
    'smith machine': 'Smith Makinesi',
    'wheel roller': 'Tekerlekli Silindir',
    'stationary bike': 'Sabit Bisiklet',
    'tire': 'Lastik',
    'trap bar': 'Trap Bar',
    'elliptical machine': 'Eliptik Makine',
    'stepmill machine': 'Stepmill Makinesi',
  };

  /// Common gym-vocabulary term substitutions used to derive a best-effort
  /// Turkish rendering of an exercise name when no curated translation
  /// exists. Longer/more specific phrases are listed before their shorter
  /// substrings so they match first.
  static const Map<String, String> _nameTermsTr = {
    'push-up': 'Şınav',
    'push up': 'Şınav',
    'pull-up': 'Barfiks',
    'pull up': 'Barfiks',
    'sit-up': 'Mekik',
    'sit up': 'Mekik',
    'crunch': 'Mekik',
    'deadlift': 'Ölü Kaldırış',
    'bench press': 'Bench Press',
    'squat': 'Squat',
    'lunge': 'Hamle',
    'curl': 'Curl',
    'press': 'Presi',
    'raise': 'Kaldırma',
    'extension': 'Ekstansiyon',
    'row': 'Çekiş',
    'fly': 'Açma',
    'shrug': 'Omuz Silkme',
    'plank': 'Plank',
    'twist': 'Bükülme',
    'kickback': 'Geri Tekme',
    'stretch': 'Esneme',
    'jump': 'Sıçrama',
    'dip': 'Dip',
    'incline': 'Eğimli',
    'decline': 'Ters Eğimli',
    'seated': 'Oturarak',
    'standing': 'Ayakta',
    'lying': 'Yatarak',
    'one arm': 'Tek Kol',
    'single leg': 'Tek Bacak',
    'alternate': 'Değişimli',
    'reverse': 'Ters',
    'wide': 'Geniş',
    'close': 'Dar',
    'grip': 'Tutuş',
  };

  static String localizedBodyPart(String bodyPart, String langCode) {
    if (langCode != 'tr') return bodyPart;
    return _bodyPartTr[bodyPart] ?? bodyPart;
  }

  static String localizedEquipment(String equipment, String langCode) {
    if (langCode != 'tr') return equipment;
    return _equipmentTr[equipment] ?? equipment;
  }

  /// Best-effort Turkish rendering of an exercise name via term
  /// substitution; returns the original English name unchanged for any
  /// other language or when no known terms are matched.
  static String localizedName(String name, String langCode) {
    if (langCode != 'tr') return name;
    var result = name;
    for (final entry in _nameTermsTr.entries) {
      result = result.replaceAll(RegExp(entry.key, caseSensitive: false), entry.value);
    }
    return result;
  }
}
