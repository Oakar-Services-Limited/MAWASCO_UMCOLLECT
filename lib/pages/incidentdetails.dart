// ignore_for_file: prefer_typing_uninitialized_variables

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:kiambu_umcollect/components/MyDrawer.dart';
import 'package:kiambu_umcollect/components/Utils.dart';

class IncidentDetails extends StatefulWidget {
  final String incidentid;
  const IncidentDetails({super.key, required this.incidentid});

  @override
  State<IncidentDetails> createState() => _IncidentDetailsState();
}

class _IncidentDetailsState extends State<IncidentDetails> {
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
      Uri.parse("${getUrl()}reports/$id"),
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
      imageUrl = data["TaskImage"];
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
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 16,
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  Column(
                    children: [
                      imageUrl.isNotEmpty
                          ? Container(
                              width: double.infinity,
                              clipBehavior: Clip.hardEdge,
                              decoration: BoxDecoration(
                                color: Colors.white, // Cream color
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.grey.withOpacity(0.1),
                                    width: 0),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color.fromARGB(82, 158, 158, 158),
                                    offset: Offset(2.0, 2.0),
                                    blurRadius: 5.0,
                                    spreadRadius: 2.0,
                                  ),
                                ],
                              ),
                              child: SizedBox(
                                height: 250,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
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
                                                      loadingBuilder: (context,
                                                          child,
                                                          loadingProgress) {
                                                        if (loadingProgress ==
                                                            null) return child;
                                                        return const Center(
                                                          child:
                                                              CircularProgressIndicator(),
                                                        );
                                                      },
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        return const Center(
                                                          child: Text(
                                                              'Failed to load image'),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          }
                                        },
                                        child: Image.network(
                                          fullImageUrl,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child,
                                              loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }
                                            return const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            );
                                          },
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Center(
                                              child:
                                                  Text('Image not available'),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          : const SizedBox(),
                    ],
                  ),
                  const SizedBox(
                    height: 16,
                  ),
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
                              children: [
                                Material(
                                  color: const Color(0xff0288D1),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
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
                                ),
                                const SizedBox(
                                  width: 12,
                                ),
                                Column(
                                  children: [
                                    Text(
                                      "${DateFormat('EEEE, MMMM d, y').format(parsePostgresTimestamp(userData["createdAt"]))} \n${DateFormat('HH:mm').format(parsePostgresTimestamp(userData["createdAt"]))}",
                                      style: const TextStyle(
                                          color: Color(0xff0288D1),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w400),
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                        )
                      : Center(child: isLoading),
                  const SizedBox(
                    height: 16,
                  ),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Technical Report",
                      style: TextStyle(
                          color: Color(0xff0288D1),
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.grey.withOpacity(0.1), width: 1),
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
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.category,
                                color: Color(0xff0288D1),
                              ),
                              const SizedBox(
                                width: 4,
                              ),
                              Expanded(
                                child: Text(
                                  ' Category: $type',
                                  softWrap: true,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      color: Color(0xff0288D1),
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Text(""),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.comment,
                                color: Color(0xff0288D1),
                              ),
                              const SizedBox(
                                width: 4,
                              ),
                              Expanded(
                                child: Text(
                                  "Description: $description",
                                  softWrap: true,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      color: Color(0xff0288D1),
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Text(""),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.line_axis,
                                color: Color(0xff0288D1),
                              ),
                              const SizedBox(
                                width: 4,
                              ),
                              Expanded(
                                child: Text(
                                  "Status: $status",
                                  softWrap: true,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      color: Color(0xff0288D1),
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Text(""),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
