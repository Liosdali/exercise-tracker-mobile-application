import 'dart:async';

import 'package:exercise_app/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  const timezoneChannel = MethodChannel('flutter_timezone');
  final calls = <String>[];
  Future<Object?> Function(MethodCall)? onCall;
  late NotificationService service;

  setUpAll(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(timezoneChannel, (_) async => 'UTC');
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'zonedSchedule') {
        calls.add('schedule:${call.arguments['title']}');
      } else if (call.method == 'cancel' || call.method == 'cancelAll') {
        calls.add(call.method);
      }
      if (onCall != null) return onCall!(call);
      return true;
    });
    service = NotificationService.instance;
    await service.init();
  });

  setUp(() async {
    onCall = null;
    await service.cancelAll();
    calls.clear();
  });

  tearDownAll(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, null);
    messenger.setMockMethodCallHandler(timezoneChannel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  Future<void> schedule(String title, int generation) {
    return service.scheduleAt(
      id: NotificationService.idDailyWorkoutReminder,
      title: title,
      body: 'Workout reminder',
      dateTime: DateTime.now().add(const Duration(days: 1)),
      accountGeneration: generation,
    );
  }

  test(
    'stale account cannot schedule or cancel new account reminders',
    () async {
      final previous = service.accountGeneration;
      await service.cancelAll();
      await schedule('previous', previous);
      await service.cancel(
        NotificationService.idDailyWorkoutReminder,
        accountGeneration: previous,
      );
      await schedule('current', service.accountGeneration);
      expect(calls, ['cancelAll', 'schedule:current']);
    },
  );

  test(
    'account switch clears in-flight old schedule before the new one',
    () async {
      final started = Completer<void>();
      final finish = Completer<void>();
      onCall = (call) async {
        if (call.method == 'zonedSchedule' &&
            call.arguments['title'] == 'previous') {
          started.complete();
          await finish.future;
        }
        return true;
      };
      final oldSchedule = schedule('previous', service.accountGeneration);
      await started.future;
      final clear = service.cancelAll();
      final newSchedule = schedule('current', service.accountGeneration);
      finish.complete();
      await Future.wait([oldSchedule, clear, newSchedule]);
      expect(calls, ['schedule:previous', 'cancelAll', 'schedule:current']);
    },
  );

  test(
    'notification errors propagate without poisoning account cleanup',
    () async {
      onCall = (call) async {
        if (call.method == 'zonedSchedule') {
          throw PlatformException(code: 'schedule_failed');
        }
        return true;
      };
      await expectLater(
        schedule('failure', service.accountGeneration),
        throwsA(isA<PlatformException>()),
      );
      await service.cancelAll();
      expect(calls, ['schedule:failure', 'cancelAll']);
    },
  );
}
