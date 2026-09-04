import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsNotifier extends StateNotifier<bool> {
  static const _key = 'notifications_enabled';

  NotificationsNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, bool>(
  (ref) => NotificationsNotifier(),
);
