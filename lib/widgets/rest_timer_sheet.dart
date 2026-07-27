import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';

/// Shows a modal rest-timer bottom sheet, counting down from
/// [initialSeconds]. Plays a system sound / haptic vibration when it
/// finishes (respecting [SettingsProvider] toggles). Returns when the user
/// dismisses it (timer end, skip, or manual close).
Future<void> showRestTimerSheet(
  BuildContext context, {
  required int initialSeconds,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isDismissible: true,
    enableDrag: true,
    builder: (_) => RestTimerSheet(initialSeconds: initialSeconds),
  );
}

class RestTimerSheet extends StatefulWidget {
  final int initialSeconds;

  const RestTimerSheet({super.key, required this.initialSeconds});

  @override
  State<RestTimerSheet> createState() => _RestTimerSheetState();
}

class _RestTimerSheetState extends State<RestTimerSheet> {
  late int _remaining;
  Timer? _timer;
  bool _paused = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.initialSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_paused) return;
      if (_remaining <= 1) {
        setState(() {
          _remaining = 0;
          _finished = true;
        });
        timer.cancel();
        _notifyFinished();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  Future<void> _notifyFinished() async {
    final settings = context.read<SettingsProvider>();
    if (settings.soundEnabled) {
      await SystemSound.play(SystemSoundType.alert);
    }
    if (settings.vibrationEnabled) {
      HapticFeedback.heavyImpact();
    }
  }

  void _addSeconds(int delta) {
    setState(() {
      _remaining = (_remaining + delta).clamp(0, 3600);
      if (_remaining > 0 && _finished) {
        _finished = false;
        _startTimer();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _format(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Dinlenme Süresi', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Text(
              _finished ? 'Hazır!' : _format(_remaining),
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => _addSeconds(-15),
                  child: const Text('-15s'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => _addSeconds(15),
                  child: const Text('+15s'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_finished)
                  TextButton.icon(
                    onPressed: () => setState(() => _paused = !_paused),
                    icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
                    label: Text(_paused ? 'Devam Et' : 'Duraklat'),
                  ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.skip_next),
                  label: Text(_finished ? 'Devam Et' : 'Atla'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
