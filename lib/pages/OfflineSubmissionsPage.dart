// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:um_collect/components/Utils.dart';
import 'package:um_collect/pages/login.dart';
import 'package:um_collect/services/database_helper.dart';
import 'package:um_collect/services/offline_queue_notifier.dart';
import 'package:um_collect/services/sync_service.dart';
import 'package:um_collect/theme/app_theme.dart';

class OfflineSubmissionsPage extends StatefulWidget {
  const OfflineSubmissionsPage({super.key});

  @override
  State<OfflineSubmissionsPage> createState() => _OfflineSubmissionsPageState();
}

class _OfflineSubmissionsPageState extends State<OfflineSubmissionsPage> {
  final _db = DatabaseHelper();
  final _syncService = SyncService();
  final _storage = const FlutterSecureStorage();
  bool _isSyncing = false;
  bool _sessionExpired = false;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _refreshSessionState() async {
    final token = await _storage.read(key: 'mwstaffjwt');
    if (!mounted) return;
    setState(() {
      _sessionExpired = isJwtExpiredOrInvalid(token);
    });
  }

  Future<void> _load() async {
    final rows = await _db.getUnsyncedSubmissions();
    await _refreshSessionState();
    if (!mounted) return;
    setState(() {
      _items = rows;
    });
    OfflineQueueNotifier.instance.refresh();
  }

  Future<void> _syncAll() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    final message = await _syncService.syncAllUnsynced();
    await _load();
    if (!mounted) return;
    setState(() => _isSyncing = false);

    final isAuthMsg = message.contains('token has expired') ||
        message.contains('Log in again');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isAuthMsg ? Colors.orange[800] : null,
        behavior: SnackBarBehavior.floating,
        action: isAuthMsg
            ? SnackBarAction(
                label: 'Log in',
                textColor: Colors.white,
                onPressed: _goToLogin,
              )
            : null,
      ),
    );
  }

  Future<void> _goToLogin() async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const Login()),
    );
    await _load();
  }

  Future<void> _deleteAll() async {
    await _db.deleteAllUnsyncedSubmissions();
    await _load();
  }

  Future<void> _deleteOne(String id) async {
    await _db.deleteSubmission(id);
    await _load();
  }

  bool get _hasAuthBlockedItems {
    for (final item in _items) {
      final err = (item['sync_error'] ?? '').toString();
      if (err.contains('token has expired') ||
          err.toLowerCase().contains('login to sync') ||
          err.toLowerCase().contains('log in again')) {
        return true;
      }
    }
    return _sessionExpired && _items.isNotEmpty;
  }

  Widget _sessionBanner() {
    if (!_hasAuthBlockedItems && !_sessionExpired) {
      return const SizedBox.shrink();
    }
    return Material(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_clock, color: Colors.orange.shade800),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kSessionExpiredSyncMessage,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dormant survey, meter replacement, master meter readings, '
                    'incident resolution, and forms need a valid login to sync.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _goToLogin,
                      icon: const Icon(Icons.login, size: 18),
                      label: const Text('Log in again'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange.shade900,
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Offline submissions',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppTheme.primaryMain,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _sessionBanner(),
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.cloud_done, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No pending submissions'),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final formName =
                            (item['form_name'] ?? 'Unknown').toString();
                        final status =
                            (item['sync_status'] ?? 'pending').toString();
                        final createdAt =
                            (item['created_at'] ?? '').toString().trim();

                        String? error;
                        try {
                          error = item['sync_error']?.toString();
                        } catch (_) {}

                        String subtitle = createdAt;
                        try {
                          final responses =
                              jsonDecode(item['responses'] as String) as Map;
                          if (responses['_type'] != null) {
                            subtitle =
                                '${responses['_type']} • ${subtitle.isEmpty ? 'Queued' : subtitle}';
                          }
                        } catch (_) {}

                        Color badgeColor;
                        if (status == 'syncing') {
                          badgeColor = Colors.blue;
                        } else if (status == 'failed') {
                          badgeColor = Colors.red;
                        } else {
                          badgeColor = Colors.orange;
                        }

                        final isAuthError = error != null &&
                            (error.contains('token has expired') ||
                                error.toLowerCase().contains('log in again'));

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(formName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(subtitle),
                                if (error != null && error.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      error,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isAuthError
                                            ? Colors.orange[800]
                                            : Colors.red,
                                        fontWeight: isAuthError
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      color: badgeColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 18),
                                    onPressed: () =>
                                        _deleteOne(item['id'] as String),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints.tightFor(
                                      width: 32,
                                      height: 32,
                                    ),
                                    splashRadius: 16,
                                    tooltip: 'Delete',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _items.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSyncing ? null : _syncAll,
                        icon: const Icon(Icons.cloud_sync),
                        label: Text(_isSyncing ? 'Syncing…' : 'Sync all'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryMain,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.delete_sweep_outlined),
                      tooltip: 'Delete all',
                      onPressed: _deleteAll,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
