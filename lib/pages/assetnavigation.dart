// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names, unused_import, empty_catches

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:um_collect/components/MyDrawer.dart';
import 'package:um_collect/components/MyRow.dart';
import 'package:um_collect/components/MyRowIII.dart';
import 'package:um_collect/components/StaffDrawer.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:um_collect/pages/navigatetoasset.dart';
import 'package:um_collect/pages/home.dart';
import 'package:um_collect/pages/login.dart';
import '../Components/Utils.dart';

class AssetNavigation extends StatefulWidget {
  final String staffid;
  const AssetNavigation({super.key, required this.staffid});

  @override
  State<AssetNavigation> createState() => _AssetNavigationState();
}

class _AssetNavigationState extends State<AssetNavigation> {
  final storage = const FlutterSecureStorage();
  String staffid = '';
  String name = '';
  String phone = '';
  String station = '';
  String total_farmers = '';
  String reached_farmers = '';
  String workplans = '';
  String active = 'Pending';
  String id = '';
  String status = 'Pending';
  String nationalId = '';
  String formattedDate = '';
  String activities = '';
  String reports = '';
  String updates = '';
  String mapped = '';
  String user = '';

  List stats = [];

  @override
  void initState() {
    getDefaultValues();
    super.initState();
  }

  Future<void> getDefaultValues() async {
    var token = await storage.read(key: "mwstaffjwt");
    var decoded = parseJwt(token.toString());

    formattedDate = DateFormat('MMMM dd, yyyy').format(DateTime.now());
    if (decoded["error"] == "Invalid token") {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const Login()));
    } else {
      setState(() {
        user = decoded["name"];
        staffid = decoded["id"];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UM Navigator',
      home: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Home()),
              );
            },
          ),
          title: const Text(
            "Asset Navigation",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xff0288D1),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        drawer: StaffDrawer(
          staffid: widget.staffid,
        ),
        body: Container(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
          child: Column(
            children: <Widget>[
              Stack(
                children: [
                  Positioned(child: extendAppBar()),
                  Positioned(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                      child: displayUserInfo(),
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 44,
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Column(
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text("Asset Navigation",
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff0288D1),
                              )),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => NavigateToAsset(
                                                label: 'Tanks',
                                                staffid: widget.staffid,
                                              )));
                                },
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return MyRowIII(
                                      no: workplans,
                                      title: 'Tanks',
                                      image: 'assets/images/water-tank.png',
                                      availableWidth: constraints.maxWidth,
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 16,
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => NavigateToAsset(
                                                label: 'Valves',
                                                staffid: widget.staffid,
                                              )));
                                },
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return MyRowIII(
                                      no: reports,
                                      title: 'Valves',
                                      image: 'assets/images/valve.png',
                                      availableWidth: constraints.maxWidth,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => NavigateToAsset(
                                                label: 'Washouts',
                                                staffid: widget.staffid,
                                              )));
                                },
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return MyRowIII(
                                      no: total_farmers,
                                      title: 'Washouts',
                                      image: 'assets/images/bulkmeter.png',
                                      availableWidth: constraints.maxWidth,
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 16,
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => NavigateToAsset(
                                                label: 'Master Meters',
                                                staffid: widget.staffid,
                                              )));
                                },
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return MyRowIII(
                                      no: mapped,
                                      title: 'Master Meters',
                                      image: 'assets/images/water-meter.png',
                                      availableWidth: constraints.maxWidth,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => NavigateToAsset(
                                                label: 'Offtakers',
                                                staffid: widget.staffid,
                                              )));
                                },
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return MyRowIII(
                                      no: total_farmers,
                                      title: 'Offtakers',
                                      image: 'assets/images/offtaker.png',
                                      availableWidth: constraints.maxWidth,
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 16,
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => NavigateToAsset(
                                                label: 'Boreholes',
                                                staffid: widget.staffid,
                                              )));
                                },
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return MyRowIII(
                                      no: mapped,
                                      title: 'Boreholes',
                                      image: 'assets/images/borehole.png',
                                      availableWidth: constraints.maxWidth,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => NavigateToAsset(
                                                label: 'Manholes',
                                                staffid: widget.staffid,
                                              )));
                                },
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return MyRowIII(
                                      no: total_farmers,
                                      title: 'Manholes',
                                      image: 'assets/images/manhole.png',
                                      availableWidth: constraints.maxWidth,
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 16,
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => NavigateToAsset(
                                                label: 'Appurtenances',
                                                staffid: widget.staffid,
                                              )));
                                },
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return MyRowIII(
                                      no: mapped,
                                      title: 'Appurtenances',
                                      image: 'assets/images/appurtenance.png',
                                      availableWidth: constraints.maxWidth,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => NavigateToAsset(
                                                label: 'Connection Chamber',
                                                staffid: widget.staffid,
                                              )));
                                },
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return MyRowIII(
                                      no: total_farmers,
                                      title: 'Connection Chamber',
                                      image:
                                          'assets/images/connectionchamber.png',
                                      availableWidth: constraints.maxWidth,
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 16,
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => NavigateToAsset(
                                                label: 'Customer Chambers',
                                                staffid: widget.staffid,
                                              )));
                                },
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return MyRowIII(
                                      no: mapped,
                                      title: 'Customer Chambers',
                                      image: 'assets/images/sewerchamber.png',
                                      availableWidth: constraints.maxWidth,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => NavigateToAsset(
                                                label: 'Facilities',
                                                staffid: widget.staffid,
                                              )));
                                },
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return MyRowIII(
                                      no: total_farmers,
                                      title: 'Facilities',
                                      image: 'assets/images/facility.png',
                                      availableWidth: constraints.maxWidth,
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 16,
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => NavigateToAsset(
                                                label: 'Incidences',
                                                staffid: widget.staffid,
                                              )));
                                },
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return MyRowIII(
                                      no: mapped,
                                      title: 'Incidences',
                                      image: 'assets/images/incident.png',
                                      availableWidth: constraints.maxWidth,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => NavigateToAsset(
                                                label: 'Water Connection',
                                                staffid: widget.staffid,
                                              )));
                                },
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return MyRowIII(
                                      no: total_farmers,
                                      title: 'Water Connection',
                                      image: 'assets/images/customer-meter.png',
                                      availableWidth: constraints.maxWidth,
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 16,
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => NavigateToAsset(
                                                label: 'Sanitation Connection',
                                                staffid: widget.staffid,
                                              )));
                                },
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return MyRowIII(
                                      no: mapped,
                                      title: 'Sanitation Connection',
                                      image: 'assets/images/sewer.png',
                                      availableWidth: constraints.maxWidth,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 48,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Container extendAppBar() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xff0288D1), // Set solid green color directly
      ),
      child: const Padding(
        padding: EdgeInsets.all(40),
      ),
    );
  }

  Container displayUserInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color.fromARGB(137, 158, 158, 158),
              offset: Offset(2.0, 2.0),
              blurRadius: 5.0,
              spreadRadius: 2.0,
            ),
          ],
          borderRadius: BorderRadius.all(Radius.circular(5))),
      child: Column(
        children: [
          Row(
            children: [
              Flexible(
                flex: 1,
                fit: FlexFit.tight,
                child: Column(
                  children: [
                    const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Welcome",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800))),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        name,
                        style: const TextStyle(
                            color: Color(0xff0288D1),
                            fontSize: 24,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formattedDate,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                        )),
                    const SizedBox(
                      height: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Image.asset(
                'assets/images/stat1.png', width: 84, // Set width of the image
                height: 84, // Set height of the image
                color: Colors.orange,
              )
            ],
          ),
          Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$activities Activity Today',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff0288D1),
                ),
              )),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
