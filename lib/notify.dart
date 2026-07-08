import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Local release reminders — same mechanism as the Ativa app (no push
/// server): a bell on a data release schedules a notification for the 1st
/// of its next release month at 10:00 local time.
final _plugin = FlutterLocalNotificationsPlugin();
bool _ready = false;

/// Release names the user follows, so the UI can show the bell state.
final reminders = ValueNotifier<Set<String>>({});

Future<File?> _remFile() async {
  if (kIsWeb) return null;
  try {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/bd_reminders.json');
  } catch (_) {
    return null;
  }
}

Future<void> initNotify() async {
  if (kIsWeb) return;
  final f = await _remFile();
  if (f != null && await f.exists()) {
    try {
      reminders.value = {
        for (final k in jsonDecode(await f.readAsString()) as List) '$k'
      };
    } catch (_) {}
  }
  tzdata.initializeTimeZones();
  try {
    final info = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(info.identifier));
  } catch (_) {
    tz.setLocalLocation(tz.getLocation('Europe/Lisbon'));
  }
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings();
  await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios));
  _ready = true;
}

Future<bool> _ensurePermission() async {
  final ios = _plugin.resolvePlatformSpecificImplementation<
      IOSFlutterLocalNotificationsPlugin>();
  if (ios != null) {
    return await ios.requestPermissions(
            alert: true, badge: true, sound: true) ??
        false;
  }
  final android = _plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  if (android != null) {
    return await android.requestNotificationsPermission() ?? true;
  }
  return true;
}

int _idFor(String key) => key.hashCode & 0x7fffffff;

bool hasReminder(String key) => reminders.value.contains(key);

void _persist() async {
  final f = await _remFile();
  if (f != null) f.writeAsString(jsonEncode(reminders.value.toList())).ignore();
}

/// The next 1st-of-month at 10:00 for any of [months] (1–12), from now.
tz.TZDateTime? nextOccurrence(List<int> months) {
  if (months.isEmpty) return null;
  final now = tz.TZDateTime.now(tz.local);
  for (var add = 0; add <= 12; add++) {
    final m = DateTime(now.year, now.month + add);
    if (months.contains(m.month)) {
      final when = tz.TZDateTime(tz.local, m.year, m.month, 1, 10);
      if (when.isAfter(now)) return when;
    }
  }
  return null;
}

/// Schedules a reminder for [name]'s next release month. Returns false if
/// permission was denied or no upcoming month exists.
Future<bool> setReminder(String name, List<int> months) async {
  if (!_ready) return false;
  if (!await _ensurePermission()) return false;
  final when = nextOccurrence(months);
  if (when == null) return false;

  const details = NotificationDetails(
    android: AndroidNotificationDetails('releases', 'Data release reminders',
        channelDescription: 'Reminders for data releases you follow',
        importance: Importance.high),
    iOS: DarwinNotificationDetails(),
  );
  await _plugin.zonedSchedule(
    id: _idFor(name),
    title: 'BullDozer Stats',
    body: 'Out this month: $name',
    scheduledDate: when,
    notificationDetails: details,
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
  );
  reminders.value = {...reminders.value, name};
  _persist();
  return true;
}

Future<void> cancelReminder(String name) async {
  await _plugin.cancel(id: _idFor(name));
  reminders.value = {...reminders.value}..remove(name);
  _persist();
}
