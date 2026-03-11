import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:um_collect/pages/OfflineSubmissionsPage.dart';
import 'package:um_collect/services/database_helper.dart';

class OfflinePendingCard extends StatelessWidget {
  final List<String> types;
  final String label;

  const OfflinePendingCard({
    super.key,
    required this.types,
    required this.label,
  });

  Future<int> _countPending() async {
    final rows = await DatabaseHelper().getUnsyncedSubmissions();
    int count = 0;
    for (final r in rows) {
      try {
        final responses =
            jsonDecode(r['responses'] as String) as Map<String, dynamic>;
        final t = responses['_type']?.toString();
        if (t != null && types.contains(t)) count++;
      } catch (_) {
        // ignore rows that aren't valid JSON
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _countPending(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        if (count <= 0) return const SizedBox.shrink();

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OfflineSubmissionsPage(),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.cloud_off, color: Color(0xff0288D1)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$label: $count waiting to be synced',
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
      },
    );
  }
}

