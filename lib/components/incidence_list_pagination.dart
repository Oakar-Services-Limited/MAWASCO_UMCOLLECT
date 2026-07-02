import 'package:flutter/material.dart';

class IncidenceListPagination extends StatelessWidget {
  final int currentPage;
  final int itemsPerPage;
  final int totalItems;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const IncidenceListPagination({
    super.key,
    required this.currentPage,
    required this.itemsPerPage,
    required this.totalItems,
    required this.onPrevious,
    required this.onNext,
  });

  int get totalPages =>
      totalItems == 0 ? 1 : (totalItems / itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    final start = totalItems == 0 ? 0 : (currentPage - 1) * itemsPerPage + 1;
    final end = (currentPage * itemsPerPage).clamp(0, totalItems);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          Text(
            'Showing $start–$end of $totalItems',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: currentPage > 1 ? onPrevious : null,
                child: const Text('Previous'),
              ),
              Text(
                'Page $currentPage of $totalPages',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              ElevatedButton(
                onPressed: currentPage < totalPages ? onNext : null,
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
