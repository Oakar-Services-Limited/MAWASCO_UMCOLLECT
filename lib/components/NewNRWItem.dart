import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:um_collect/pages/incidentdetailsnrw.dart';
import 'package:um_collect/pages/navigatenrw.dart';
import 'package:intl/intl.dart';

class NewNRWItem extends StatefulWidget {
  final Map<String, dynamic> item;
  final int index;
  const NewNRWItem({
    super.key,
    required this.item,
    required this.index,
  });

  @override
  State<NewNRWItem> createState() => _NewNRWItemState();
}

class _NewNRWItemState extends State<NewNRWItem> {
  Map<String, dynamic> data = {};
  final storage = const FlutterSecureStorage();

  DateTime parsePostgresTimestamp(String timestamp) {
    return DateTime.parse(timestamp).toLocal();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.item["Status"] == "Resolved"
            ? Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => IncidentDetailsNRW(
                          incidentid: widget.item["ID"],
                        )))
            : Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => NavigateNRW(item: widget.item)));
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey.shade50,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '#${widget.item['SerialNo'] ?? widget.item['ID']}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xff0288D1),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xff0288D1).withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.item['Status']}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xff0288D1),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('MMM d, y')
                      .format(parsePostgresTimestamp(widget.item['createdAt'])),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.item['Description']}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[800],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[900],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Message {
  dynamic token;
  dynamic success;
  dynamic error;

  Message({
    required this.token,
    required this.success,
    required this.error,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      token: json['token'],
      success: json['success'],
      error: json['error'],
    );
  }
}
