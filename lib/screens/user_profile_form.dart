import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_profile_provider.dart';

/// Form for the user's current body profile (Boy/Kilo/Yaş/Cinsiyet/Yağ
/// Oranı), used as the primary weight source for MET-based calorie
/// calculation. Distinct from [BodyMeasurementForm], which logs a dated
/// history of measurements instead of a single current snapshot.
class UserProfileForm extends StatefulWidget {
  const UserProfileForm({super.key});

  @override
  State<UserProfileForm> createState() => _UserProfileFormState();
}

class _UserProfileFormState extends State<UserProfileForm> {
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();
  final _bodyFatController = TextEditingController();
  String? _gender;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final profile = context.read<UserProfileProvider>().profile;
    if (profile != null) {
      _heightController.text = profile.heightCm?.toString() ?? '';
      _weightController.text = profile.weightKg?.toString() ?? '';
      _ageController.text = profile.age?.toString() ?? '';
      _bodyFatController.text = profile.bodyFatPercent?.toString() ?? '';
      _gender = profile.gender;
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    _bodyFatController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await context.read<UserProfileProvider>().saveProfile(
          heightCm: double.tryParse(_heightController.text),
          weightKg: double.tryParse(_weightController.text),
          age: int.tryParse(_ageController.text),
          bodyFatPercent: double.tryParse(_bodyFatController.text),
          gender: _gender,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vücut bilgileri kaydedildi.')),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vücut Bilgilerim')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              'Bu bilgiler MET tabanlı kalori hesaplamasında ve istatistiklerde kullanılır.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _heightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Boy (cm)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Kilo (kg)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Yaş'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: const InputDecoration(labelText: 'Cinsiyet'),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Erkek')),
                DropdownMenuItem(value: 'female', child: Text('Kadın')),
                DropdownMenuItem(value: 'other', child: Text('Belirtmek istemiyorum')),
              ],
              onChanged: (value) => setState(() => _gender = value),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bodyFatController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Yağ oranı (%) - opsiyonel'),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: const Text('Kaydet')),
          ],
        ),
      ),
    );
  }
}
