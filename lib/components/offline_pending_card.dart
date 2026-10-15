import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:um_collect/components/Utils.dart';
import 'package:um_collect/pages/OfflineSubmissionsPage.dart';
import 'package:um_collect/services/auto_sync_service.dart';
import 'package:um_collect/services/database_helper.dart';
import 'package:um_collect/services/offline_queue_notifier.dart';
import 'package:um_collect/services/sync_service.dart';

class OfflinePendingCard extends StatefulWidget {
  final List<String> types;
  final String label;
  final bool allTypes;

  const OfflinePendingCard({
    super.key,
    required this.types,
    required this.label,
    this.allTypes = false,
  });

  @override
  State<OfflinePendingCard> createState() => _OfflinePendingCardState();
}

class _OfflinePendingCardState extends State<OfflinePendingCard> {
  final _sync = SyncService();
  final _online = AutoSyncService.instance.isOnline;
  int _count = 0;
  int _failed = 0;
  bool _loading = true;
  bool _sessionExpired = false;

  @override
  void initState() {
    super.initState();
    OfflineQueueNotifier.instance.addListener(_onQueueChanged);
    _sync.isSyncing.addListener(_onStatusChanged);
    _online.addListener(_onStatusChanged);
    _refreshCount();
  }

  @override
  void dispose() {
    OfflineQueueNotifier.instance.removeListener(_onQueueChanged);
    _sync.isSyncing.removeListener(_onStatusChanged);
    _online.removeListener(_onStatusChanged);
    super.dispose();
  }

  void _onQueueChanged() => _refreshCount();

  void _onStatusChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshCount() async {
    final rows = await DatabaseHelper().getUnsyncedSubmissions();
    var count = 0;
    var failed = 0;
    for (final r in rows) {
      try {
        final responses =
            jsonDecode(r['responses'] as String) as Map<String, dynamic>;
        final t = responses['_type']?.toString();
        if (widget.allTypes || (t != null && widget.types.contains(t))) {
          count++;
          if (r['sync_status'] == 'failed') failed++;
        }
      } catch (_) {}
    }
    final token = await const FlutterSecureStorage().read(key: 'mwstaffjwt');
    if (!mounted) return;
    setState(() {
      _count = count;
      _failed = failed;
      _sessionExpired = isJwtExpiredOrInvalid(token);
      _loading = false;
    });
  }

  Future<void> _openOfflinePage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OfflineSubmissionsPage()),
    );
    await _refreshCount();
  }

  Future<void> _syncNow() async {
    final message = await _sync.syncAllUnsynced();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String get _statusText {
    if (_sync.isSyncing.value) return 'Uploading…';
    if (!_online.value) {
      return 'No internet — will upload automatically when you reconnect.';
    }
    if (_failed > 0) {
      return '$_failed failed — tap to see details.';
    }
    return 'Online — uploading automatically, or tap Sync now.';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _count <= 0) {
      return const SizedBox.shrink();
    }

    final syncing = _sync.isSyncing.value;
    final online = _online.value;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _openOfflinePage,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: Row(
            children: [
              Icon(
                _sessionExpired
                    ? Icons.lock_clock
                    : online
                        ? Icons.cloud_upload_outlined
                        : Icons.cloud_off,
                color: _sessionExpired
                    ? Colors.orange.shade800
                    : const Color(0xff0288D1),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.label}: $_count waiting to be synced',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _sessionExpired ? kSessionExpiredSyncMessage : _statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: _sessionExpired
                            ? Colors.orange.shade800
                            : _failed > 0 && !syncing
                                ? Colors.red.shade700
                                : Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (syncing)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (online)
                FilledButton.icon(
                  onPressed: _syncNow,
                  icon: const Icon(Icons.sync, size: 18),
                  label: const Text('Sync now'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xff0288D1),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    visualDensity: VisualDensity.compact,
                  ),
                )
              else
                const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
