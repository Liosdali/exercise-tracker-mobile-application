import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/database_helper.dart';

abstract class AccountChangeNotifier extends ChangeNotifier {
  late final StreamSubscription<void> _subscription;
  bool _disposed = false;
  String? loadError;

  AccountChangeNotifier() {
    _subscription = DatabaseHelper.instance.changes.listen((_) async {
      if (_disposed) return;
      try {
        await reloadAccount();
        loadError = null;
      } catch (error) {
        loadError = error.toString();
        notifyListeners();
      }
    });
  }

  Future<void> reloadAccount();

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription.cancel();
    super.dispose();
  }
}
