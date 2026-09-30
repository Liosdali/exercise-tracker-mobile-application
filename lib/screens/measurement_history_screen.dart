import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/body_measurement.dart';
import '../services/user_account_service.dart';
import 'body_measurement_form.dart';

/// The one-line summary shown under a measurement's date.
///
/// Only the parts that were actually recorded appear, so a weight-only entry
/// reads as "82 kg" rather than carrying empty fields. Kept top level so the
/// formatting can be tested without building a widget tree.
String measurementSummary(AppLocalizations l10n, BodyMeasurement measurement) =>
    [
      if (measurement.weightKg != null)
        l10n.measurementWeightValue('${measurement.weightKg}'),
      if (measurement.heightCm != null)
        l10n.measurementHeightValue('${measurement.heightCm}'),
      if (measurement.calculatedBodyFat != null)
        l10n.measurementBodyFatValue(
          measurement.calculatedBodyFat!.toStringAsFixed(1),
        ),
      if (measurement.chestCm != null)
        l10n.measurementChestValue('${measurement.chestCm}'),
      if (measurement.waistCm != null)
        l10n.measurementWaistValue('${measurement.waistCm}'),
    ].join(' • ');

/// The logged body measurements, newest first.
///
/// Shared by the Profile tab, which renders it inline beneath its own
/// heading, and by [MeasurementHistoryScreen], which the profile editor
/// opens. Both need the same rows and the same reload behaviour, and the
/// list previously existed only inside the Profile tab.
///
/// Reloading is driven by [UserAccountService]: every write path that
/// touches measurements refreshes it, so the list does not need to be told
/// when a new entry is saved, nor to be reloaded by whoever pushed the form.
class MeasurementHistoryList extends StatefulWidget {
  const MeasurementHistoryList({super.key});

  @override
  State<MeasurementHistoryList> createState() => _MeasurementHistoryListState();
}

class _MeasurementHistoryListState extends State<MeasurementHistoryList> {
  List<BodyMeasurement> _measurements = [];
  late final UserAccountService _accounts;

  @override
  void initState() {
    super.initState();
    _accounts = context.read<UserAccountService>();
    _accounts.addListener(_reload);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final measurements = await DatabaseHelper.instance.allMeasurements();
    if (mounted) setState(() => _measurements = measurements);
  }

  void _reload() {
    if (mounted) _load();
  }

  @override
  void dispose() {
    _accounts.removeListener(_reload);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_measurements.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(l10n.profileNoMeasurements),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final measurement in _measurements)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              DateFormat.yMMMd().format(DateTime.parse(measurement.date)),
            ),
            subtitle: Text(measurementSummary(l10n, measurement)),
          ),
      ],
    );
  }
}

/// Full-screen measurement history, reached from the profile editor.
///
/// The editor writes weight and height into the same history, so someone
/// changing those values has a way to see what that produced without
/// hunting through the Profile tab.
class MeasurementHistoryScreen extends StatelessWidget {
  const MeasurementHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileBodyMeasurementsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [MeasurementHistoryList()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<bool>(builder: (_) => const BodyMeasurementForm()),
        ),
        icon: const Icon(Icons.add),
        label: Text(l10n.commonAdd),
      ),
    );
  }
}
