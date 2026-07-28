import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/database_helper.dart';
import '../models/body_measurement.dart';
import '../services/body_fat_calculator_service.dart';

/// Form to add a new body-measurement log entry: weight, height, and
/// circumferences (waist/neck/hip), from which the body fat percentage is
/// automatically computed via the U.S. Navy method - no manual body fat
/// entry needed.
class BodyMeasurementForm extends StatefulWidget {
  const BodyMeasurementForm({super.key});

  @override
  State<BodyMeasurementForm> createState() => _BodyMeasurementFormState();
}

class _BodyMeasurementFormState extends State<BodyMeasurementForm> {
  DateTime _date = DateTime.now();
  String _gender = 'male';
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _neckController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipController = TextEditingController();
  final _chestController = TextEditingController();
  final _notesController = TextEditingController();

  double? get _liveCalculatedBodyFat {
    final height = double.tryParse(_heightController.text);
    final waist = double.tryParse(_waistController.text);
    final neck = double.tryParse(_neckController.text);
    final hip = double.tryParse(_hipController.text);
    if (height == null || waist == null || neck == null) return null;
    return BodyFatCalculatorService.calculate(
      gender: _gender,
      heightCm: height,
      waistCm: waist,
      neckCm: neck,
      hipCm: hip,
    );
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _neckController.dispose();
    _waistController.dispose();
    _hipController.dispose();
    _chestController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final measurement = BodyMeasurement(
      date: DateFormat('yyyy-MM-dd').format(_date),
      weightKg: double.tryParse(_weightController.text),
      heightCm: double.tryParse(_heightController.text),
      gender: _gender,
      neckCm: double.tryParse(_neckController.text),
      hipCm: double.tryParse(_hipController.text),
      calculatedBodyFat: _liveCalculatedBodyFat,
      chestCm: double.tryParse(_chestController.text),
      waistCm: double.tryParse(_waistController.text),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: DateTime.now().toIso8601String(),
    );
    await DatabaseHelper.instance.insertMeasurement(measurement);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final bodyFat = _liveCalculatedBodyFat;
    return Scaffold(
      appBar: AppBar(title: const Text('Ölçüm Ekle')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tarih'),
              subtitle: Text(DateFormat.yMMMMd().format(_date)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: const InputDecoration(labelText: 'Cinsiyet'),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Erkek')),
                DropdownMenuItem(value: 'female', child: Text('Kadın')),
              ],
              onChanged: (value) => setState(() => _gender = value ?? 'male'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _heightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Boy (cm)'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Kilo (kg)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _neckController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Boyun çevresi (cm)'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _waistController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Bel çevresi (cm)'),
              onChanged: (_) => setState(() {}),
            ),
            if (_gender == 'female') ...[
              const SizedBox(height: 8),
              TextField(
                controller: _hipController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Kalça çevresi (cm)'),
                onChanged: (_) => setState(() {}),
              ),
            ],
            const SizedBox(height: 8),
            TextField(
              controller: _chestController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Göğüs çevresi (cm) - opsiyonel'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Not (opsiyonel)'),
            ),
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.calculate_outlined),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bodyFat != null
                            ? 'Otomatik hesaplanan yağ oranı: %${bodyFat.toStringAsFixed(1)}'
                            : 'Yağ oranını hesaplamak için Boy, Bel ve Boyun (kadınlarda Kalça dahil) değerlerini girin.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: const Text('Kaydet')),
          ],
        ),
      ),
    );
  }
}
