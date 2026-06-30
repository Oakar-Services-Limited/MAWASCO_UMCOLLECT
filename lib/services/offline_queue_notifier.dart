import 'package:flutter/foundation.dart';

/// Notifies UI when the local offline submission queue changes.
class OfflineQueueNotifier extends ChangeNotifier {
  OfflineQueueNotifier._();

  static final OfflineQueueNotifier instance = OfflineQueueNotifier._();

  void refresh() {
    notifyListeners();
  }
}
