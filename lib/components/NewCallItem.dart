import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:um_collect/pages/incidentdetails.dart';
import 'package:um_collect/pages/navigate.dart';
import 'package:intl/intl.dart';

class NewCallItem extends StatefulWidget {
  final Map<String, dynamic> item;
  final int index;
  const NewCallItem({
    super.key,
    required this.item,
    required this.index,
  });

  @override
  State<NewCallItem> createState() => _CollectedItemState();
}

class _CollectedItemState extends State<NewCallItem> {
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
    return GestureDetector(
      onTap: () {
        widget.item["Status"] == "Resolved"
            ? Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => IncidentDetails(
                          incidentid: widget.item["ID"],
                        )))
            : Navigator.push(context,
                MaterialPageRoute(builder: (_) => Navigate(item: widget.item)));
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
                          (widget.item["report"]?["serialNo"] ??
                                  widget.index + 1)
                              .toString(),
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
                          widget.item["report"]?["incidentType"] ?? "Incident",
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
                          widget.item["report"]?["description"] ??
                              "No description available",
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
              child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
                  decoration: const BoxDecoration(
                      color: Colors.orange,
                      borderRadius:
                          BorderRadius.only(topRight: Radius.circular(5))),
                  child: Text(
                    "${DateFormat('EEEE, MMMM d, y').format(parsePostgresTimestamp(widget.item["report"]?["createdAt"] ?? DateTime.now().toIso8601String()))} \n ${DateFormat('HH:mm').format(parsePostgresTimestamp(widget.item["report"]?["createdAt"] ?? DateTime.now().toIso8601String()))}",
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
