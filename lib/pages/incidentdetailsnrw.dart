// ignore_for_file: prefer_typing_uninitialized_variables

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:um_collect/components/MyDrawer.dart';
import 'package:um_collect/components/Utils.dart';

class IncidentDetailsNRW extends StatefulWidget {
  final String incidentid;
  const IncidentDetailsNRW({super.key, required this.incidentid});

  @override
  State<IncidentDetailsNRW> createState() => _IncidentDetailsNRWState();
}

class _IncidentDetailsNRWState extends State<IncidentDetailsNRW> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String erid = '';
  String serial = '';
  String type = '';
  String description = '';
  String latitude = '0';
  String longitude = '0';
  String? status = '';
  String imageUrl = '';
  dynamic userData = [];
  var isLoading;

  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    loadIncidentDetails(widget.incidentid);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  loadIncidentDetails(String id) async {
    print("incident id: $id");

    setState(() {
      isLoading = LoadingAnimationWidget.staggeredDotsWave(
        color: const Color(0xff0288D1),
        size: 100,
      );
    });

    final response = await get(
      Uri.parse("${getUrl()}nrw_leakages/$id"),
    );

    var data = json.decode(response.body);
    print("incident data: $data");
    setState(() {
      userData = data;
      type = data["Type"];
      description = data["Description"];
      status = data["Status"];
      serial = data["SerialNo"].toString();
      latitude = data["Latitude"];
      longitude = data["Longitude"];
      status = data["Status"];
      imageUrl = data["TaskImage"] ?? '';
      isLoading = null;
    });
  }

  DateTime parsePostgresTimestamp(String timestamp) {
    return DateTime.parse(timestamp).toLocal();
  }

  @override
  Widget build(BuildContext context) {
    final String fullImageUrl = imageUrl.isNotEmpty
        ? "${getUrl()}uploads/${imageUrl.replaceAll("uploads/", "")}"
        : '';
    print("imageurl full: $fullImageUrl");
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Row(
          children: [
            Flexible(
              flex: 1,
              fit: FlexFit.tight,
              child: Row(
                children: [
                  Text(
                    userData.isNotEmpty
                        ? userData["Type"]
                        : "Reported Incident",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: const Icon(Icons.arrow_back),
            )
          ],
        ),
        backgroundColor: const Color(0xff0288D1),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const MyDrawer(),
      body: Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              userData.isNotEmpty
                  ? Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.grey.withOpacity(0.1), width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromARGB(82, 158, 158, 158),
                            offset: Offset(2.0, 2.0),
                            blurRadius: 5.0,
                            spreadRadius: 2.0,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: Color(0xff0288D1),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8)),
                              ),
                              child: Text(
                                userData.isNotEmpty
                                    ? userData["SerialNo"].toString()
                                    : "",
                                style: const TextStyle(
                                  fontSize: 24,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "${DateFormat('EEEE, MMMM d, y').format(parsePostgresTimestamp(userData["createdAt"]))} \n${DateFormat('HH:mm').format(parsePostgresTimestamp(userData["createdAt"]))}",
                                style: const TextStyle(
                                  color: Color(0xff0288D1),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            )
                          ],
                        ),
                      ),
                    )
                  : Center(child: isLoading),
              const SizedBox(height: 16),
              if (imageUrl.isNotEmpty)
                Container(
                  width: double.infinity,
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.grey.withOpacity(0.1), width: 0),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromARGB(82, 158, 158, 158),
                        offset: Offset(2.0, 2.0),
                        blurRadius: 5.0,
                        spreadRadius: 2.0,
                      ),
                    ],
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      fullImageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Text('Image not available'),
                        );
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              const Text(
                "Technical Report",
                style: TextStyle(
                  color: Color(0xff0288D1),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
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
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.category,
                            color: Color(0xff0288D1),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Category: $type',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xff0288D1),
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.comment,
                            color: Color(0xff0288D1),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Description: $description",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xff0288D1),
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 3,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          const Icon(
                            Icons.line_axis,
                            color: Color(0xff0288D1),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Status: $status",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xff0288D1),
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
