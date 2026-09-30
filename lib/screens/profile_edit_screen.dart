import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/user_account_service.dart';
import 'measurement_history_screen.dart';

bool validOptionalAge(String value) {
  if (value.trim().isEmpty) return true;
  final age = int.tryParse(value.trim());
  return age != null && age >= 0;
}

bool validOptionalMeasurement(String value) {
  if (value.trim().isEmpty) return true;
  final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
  return parsed != null && parsed.isFinite && parsed > 0;
}

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});
  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _weight = TextEditingController();
  final _height = TextEditingController();
  String? _gender;
  bool _loaded = false;
  bool _saving = false;
  bool _error = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final profile = context.read<UserAccountService>().profile;
    _name.text = profile?.name ?? '';
    _age.text = profile?.age?.toString() ?? '';
    _weight.text = profile?.weightKg?.toString() ?? '';
    _height.text = profile?.heightCm?.toString() ?? '';
    _gender = profile?.gender;
  }

  @override
  void dispose() {
    for (final controller in [_name, _age, _weight, _height]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() || _saving) return;
    setState(() {
      _saving = true;
      _error = false;
    });
    try {
      await context.read<UserAccountService>().updateProfile(
        name: _name.text.trim(),
        age: int.tryParse(_age.text.trim()),
        weightKg: double.tryParse(_weight.text.trim().replaceAll(',', '.')),
        heightCm: double.tryParse(_height.text.trim().replaceAll(',', '.')),
        gender: _gender,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountEditProfile)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(l10n.accountProfileOptional),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              maxLength: 200,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.accountName),
            ),
            TextFormField(
              controller: _age,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.accountAge),
              validator: (value) =>
                  validOptionalAge(value ?? '') ? null : l10n.accountAgeInvalid,
            ),
            TextFormField(
              controller: _weight,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: l10n.accountWeight),
              validator: (value) => validOptionalMeasurement(value ?? '')
                  ? null
                  : l10n.accountMeasurementInvalid,
            ),
            TextFormField(
              controller: _height,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: l10n.accountHeight),
              validator: (value) => validOptionalMeasurement(value ?? '')
                  ? null
                  : l10n.accountMeasurementInvalid,
            ),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: InputDecoration(labelText: l10n.accountGender),
              items: [
                if (_gender != null &&
                    !['female', 'male', 'other'].contains(_gender))
                  DropdownMenuItem(value: _gender, child: Text(_gender!)),
                DropdownMenuItem(
                  value: null,
                  child: Text(l10n.accountGenderUnspecified),
                ),
                DropdownMenuItem(
                  value: 'female',
                  child: Text(l10n.accountGenderFemale),
                ),
                DropdownMenuItem(
                  value: 'male',
                  child: Text(l10n.accountGenderMale),
                ),
                DropdownMenuItem(
                  value: 'other',
                  child: Text(l10n.accountGenderOther),
                ),
              ],
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _gender = value),
            ),
            // Weight and height edits here are written into the measurement
            // history, so the history is reachable from the place that adds
            // to it rather than only from the Profile tab.
            TextButton.icon(
              onPressed: _saving
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const MeasurementHistoryScreen(),
                      ),
                    ),
              icon: const Icon(Icons.timeline),
              label: Text(l10n.accountViewMeasurementHistory),
            ),
            if (_error) Text(l10n.accountOperationError),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(l10n.commonSave),
            ),
            if (_saving) const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
