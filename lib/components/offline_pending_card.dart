import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:um_collect/pages/OfflineSubmissionsPage.dart';
import 'package:um_collect/services/database_helper.dart';
import 'package:um_collect/services/offline_queue_notifier.dart';

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
  int _count = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    OfflineQueueNotifier.instance.addListener(_onQueueChanged);
    _refreshCount();
  }

  @override
  void dispose() {
    OfflineQueueNotifier.instance.removeListener(_onQueueChanged);
    super.dispose();
  }

  void _onQueueChanged() {
    _refreshCount();
  }

  Future<int> _countPending() async {
    final rows = await DatabaseHelper().getUnsyncedSubmissions();
    int count = 0;
    for (final r in rows) {
      try {
        final responses =
            jsonDecode(r['responses'] as String) as Map<String, dynamic>;
        final t = responses['_type']?.toString();
        if (widget.allTypes || (t != null && widget.types.contains(t))) {
          count++;
        }
      } catch (_) {
        // ignore rows that aren't valid JSON
      }
    }
    return count;
  }

  Future<void> _refreshCount() async {
    final count = await _countPending();
    if (!mounted) return;
    setState(() {
      _count = count;
      _loading = false;
    });
  }

  Future<void> _openOfflinePage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const OfflineSubmissionsPage(),
      ),
    );
    await _refreshCount();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _count <= 0) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _openOfflinePage,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.cloud_off, color: Color(0xff0288D1)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${widget.label}: $_count waiting to be synced',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
