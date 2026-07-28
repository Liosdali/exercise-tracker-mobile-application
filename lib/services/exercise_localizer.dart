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
/// Exercise *names* (e.g. "Barbell Bench Press") are intentionally NOT
/// localized here - by product decision they always stay in English
/// regardless of the active app language, since that's how exercises are
/// conventionally referred to (even in Turkish-language fitness content).
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

  static String localizedBodyPart(String bodyPart, String langCode) {
    if (langCode != 'tr') return bodyPart;
    return _bodyPartTr[bodyPart] ?? bodyPart;
  }

  static String localizedEquipment(String equipment, String langCode) {
    if (langCode != 'tr') return equipment;
    return _equipmentTr[equipment] ?? equipment;
  }
}
