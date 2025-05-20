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
    return DateTime.parse(timestamp)
        .toLocal(); // Parse timestamp and convert to local time
  }

  @override
  Widget build(BuildContext context) {
    final String fullImageUrl = widget.item["Image"] != null &&
            widget.item["Image"]!.toString().isNotEmpty
        ? "${getUrl()}uploads/${widget.item["Image"]!.toString().replaceAll("uploads/", "")}"
        : '';
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
                    Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
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
                        color: Colors.white70,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(5)),
                        border: Border.all(
                            color: const Color(0xff0288D1), width: 1)),
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        (widget.item["SerialNo"]).toString(),
                        style: const TextStyle(
                            color: Color(0xff0288D1),
                            fontWeight: FontWeight.bold,
                            fontSize: 24),
                      ),
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
                          widget.item["Type"],
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
                          "${widget.item["Description"]}",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff0288D1),
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                            child: Text(
                              "Status: ${widget.item["TaskRemark"] == null ? "Pending" : "Resolved"}",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff0288D1),
                              ),
                            ),
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
              child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
                  decoration: const BoxDecoration(
                      color: Colors.orange,
                      borderRadius:
                          BorderRadius.only(topRight: Radius.circular(5))),
                  child: Text(
                    "${DateFormat('EEEE, MMMM d, y').format(parsePostgresTimestamp(widget.item["createdAt"]))} \n ${DateFormat('HH:mm').format(parsePostgresTimestamp(widget.item["createdAt"]))}",
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ))),
        ],
      ),
    );
  }
}

class Message {
  var token;
  var success;
  var error;

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
