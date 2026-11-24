import 'package:flutter/foundation.dart';

import '../services/reminder_scheduler.dart';
import '../services/reminder_store.dart';

class ReminderProvider extends ChangeNotifier {
  ReminderProvider(this._scheduler, this._store);

  final ReminderScheduler _scheduler;
  final ReminderStore _store;

  String? _uid;
  ReminderSettings _settings = const ReminderSettings();
  bool _busy = false;
  bool _permissionDenied = false;
  String? _error;
  bool _disposed = false;

  ReminderSettings get settings => _settings;
  bool get enabled => _settings.enabled;
  bool get busy => _busy;
  bool get permissionDenied => _permissionDenied;
  String? get error => _error;

  /// Dipanggil dari ProxyProvider saat UID berubah.
  void updateUser(String? uid) {
    if (uid == _uid) return;
    _uid = uid;
    _settings = const ReminderSettings();
    _permissionDenied = false;
    _error = null;
    if (uid == null) {
      // Logout: hentikan pengingat milik user sebelumnya di perangkat ini.
      Future.microtask(() async {
        try {
          await _scheduler.cancel();
        } catch (_) {}
      });
      return;
    }
    Future.microtask(() => _load(uid));
  }

  bool _stale(String uid) => _disposed || _uid != uid;

  Future<void> _load(String uid) async {
    try {
      final loaded = await _store.load(uid);
      if (_stale(uid)) return;
      _settings = loaded;
      if (loaded.enabled) {
        await _scheduler.initialize();
        await _scheduler.schedule(loaded.hour, loaded.minute);
      }
    } catch (e) {
      if (_stale(uid)) return;
      _error = e.toString();
    }
    _notify();
  }

  Future<void> setEnabled(bool value) async {
    final uid = _uid;
    if (uid == null || _busy) return;
    _busy = true;
    _error = null;
    _notify();
    try {
      await _scheduler.initialize();
      if (value) {
        if (!await _scheduler.requestPermission()) {
          _permissionDenied = true;
          return;
        }
        _permissionDenied = false;
        await _scheduler.schedule(_settings.hour, _settings.minute);
      } else {
        await _scheduler.cancel();
      }
      final next = _settings.copyWith(enabled: value);
      await _store.save(uid, next);
      if (!_stale(uid)) _settings = next;
    } catch (e) {
      _error = e.toString();
    } finally {
      _busy = false;
      _notify();
    }
  }

  Future<void> setTime(int hour, int minute) async {
    final uid = _uid;
    if (uid == null || _busy) return;
    _busy = true;
    _error = null;
    _notify();
    try {
      final next = _settings.copyWith(hour: hour, minute: minute);
      if (next.enabled) {
        await _scheduler.initialize();
        await _scheduler.schedule(hour, minute);
      }
      await _store.save(uid, next);
      if (!_stale(uid)) _settings = next;
    } catch (e) {
      _error = e.toString();
    } finally {
      _busy = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
