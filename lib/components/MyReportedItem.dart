import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:um_collect/components/Utils.dart';
import 'package:intl/intl.dart';

class MyReportedItem extends StatefulWidget {
  final Map<String, dynamic> item;
  final int index;
  const MyReportedItem({
    super.key,
    required this.item,
    required this.index,
  });

  @override
  State<MyReportedItem> createState() => _CollectedItemState();
}

class _CollectedItemState extends State<MyReportedItem> {
  Map<String, dynamic> data = {};
  final storage = const FlutterSecureStorage();

  @override
  initState() {
    super.initState();
  }

  DateTime parsePostgresTimestamp(String timestamp) {
    return DateTime.parse(timestamp).toLocal();
  }

  String _getFormattedDateTime() {
    final createdAt = widget.item["createdAt"] ??
        widget.item["CreatedAt"] ??
        widget.item["created_at"];
    if (createdAt == null) return "Date not available";
    try {
      final dateTime = parsePostgresTimestamp(createdAt.toString());
      return "${DateFormat('EEEE, MMMM d, y').format(dateTime)} \n ${DateFormat('HH:mm').format(dateTime)}";
    } catch (e) {
      return "Date not available";
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageField = widget.item["Image"] ?? widget.item["image"];
    final String fullImageUrl = (imageField != null &&
            imageField.toString().isNotEmpty)
        ? "${getUrl()}uploads/${imageField.toString().replaceAll("uploads/", "")}"
        : '';

    final incidentType = widget.item["Type"] ??
        widget.item["incidentType"] ??
        widget.item["type"] ??
        "Incident";
    final description = widget.item["Description"] ??
        widget.item["description"] ??
        "No description available";
    final status =
        widget.item["Status"] ?? widget.item["status"] ?? "Received";
    final lowerStatus = status.toString().toLowerCase();
    final serialNo = widget.item["SerialNo"] ??
        widget.item["serialNo"] ??
        widget.item["id"] ??
        (widget.index + 1);

    return GestureDetector(
      onTap: () {
        if (fullImageUrl.isNotEmpty) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return Dialog(
                child: InteractiveViewer(
                  child: Image.network(
                    fullImageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Text('Failed to load image'),
                      );
                    },
                  ),
                ),
              );
            },
          );
        }
      },
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9F1), // Cream color
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: Colors.grey.withValues(alpha:0.1), width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromARGB(82, 158, 158, 158),
                    offset: Offset(2.0, 2.0),
                    blurRadius: 5.0,
                    spreadRadius: 2.0,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    width: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xffE3F2FD), // Light blue
                      borderRadius: const BorderRadius.all(Radius.circular(5)),
                      border:
                          Border.all(color: const Color(0xff0288D1), width: 1),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "SR No.",
                          style: TextStyle(
                            color: Color(0xff0288D1),
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          serialNo.toString(),
                          style: const TextStyle(
                            color: Color(0xff0288D1),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Flexible(
                    flex: 1,
                    fit: FlexFit.tight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          incidentType,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff0288D1),
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff0288D1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
              alignment: Alignment.topRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
                      decoration: const BoxDecoration(
                          color: Colors.orange,
                          borderRadius:
                              BorderRadius.only(topRight: Radius.circular(5))),
                      child: Text(
                        _getFormattedDateTime(),
                        style:
                            const TextStyle(fontSize: 10, color: Colors.white),
                      )),
                  const SizedBox(height: 2),
                  Container(
                      padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
                      decoration: BoxDecoration(
                          color: lowerStatus.contains('resolved')
                              ? Colors.green
                              : (lowerStatus.contains('draft') ||
                                      lowerStatus.contains('pending'))
                                  ? Colors.orange
                                  : Colors.red,
                          borderRadius: BorderRadius.only(
                              bottomRight: Radius.circular(5))),
                      child: Text(
                        status,
                        style:
                            const TextStyle(fontSize: 10, color: Colors.white),
                      )),
                ],
              )),
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
