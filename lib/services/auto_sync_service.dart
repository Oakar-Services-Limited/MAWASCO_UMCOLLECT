import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:um_collect/services/connectivity_helper.dart';
import 'package:um_collect/services/database_helper.dart';
import 'package:um_collect/services/sync_service.dart';

/// Uploads the offline queue without user action: on reconnect, when the app
/// returns to the foreground, and periodically while items are waiting.
class AutoSyncService with WidgetsBindingObserver {
  AutoSyncService._();
  static final AutoSyncService instance = AutoSyncService._();

  static const Duration _retryInterval = Duration(minutes: 2);

  final _sync = SyncService();
  final _db = DatabaseHelper();
  StreamSubscription<bool>? _connectivitySub;
  Timer? _retryTimer;
  bool _started = false;
  bool _wasOnline = true;

  final ValueNotifier<bool> isOnline = ValueNotifier(true);

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);

    ConnectivityHelper().checkConnectivity().then((online) {
      _wasOnline = online;
      isOnline.value = online;
      _db.resetSyncingToPending().whenComplete(() {
        if (online) _trigger();
      });
    });

    _connectivitySub = ConnectivityHelper().connectivityStream.listen((online) {
      final cameBackOnline = !_wasOnline && online;
      _wasOnline = online;
      isOnline.value = online;
      if (cameBackOnline) {
        // Give the radio a moment to get a working route before uploading.
        Future.delayed(const Duration(seconds: 3), _trigger);
      }
    });

    _retryTimer = Timer.periodic(_retryInterval, (_) => _retryIfPending());
  }

  void stop() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySub?.cancel();
    _retryTimer?.cancel();
    _started = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ConnectivityHelper().checkConnectivity().then((online) {
        isOnline.value = online;
        if (online) _trigger();
      });
    }
  }

  Future<void> _retryIfPending() async {
    if (!isOnline.value || _sync.isSyncing.value) return;
    final waiting = await _db.countRetryableSubmissions();
    if (waiting > 0) _trigger();
  }

  void _trigger() {
    _sync.syncAllUnsynced();
  }
}
