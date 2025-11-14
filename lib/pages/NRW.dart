// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names, unused_import, deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:um_collect/components/MyRowAligned.dart';
import 'package:um_collect/components/MyRowII.dart';
import 'package:um_collect/pages/Forms/MasterMeters.dart';
import 'package:um_collect/pages/Forms/Interventions.dart';
import 'package:um_collect/pages/Forms/NRWMetersReading.dart';
import 'package:um_collect/pages/Forms/Washouts.dart';
import 'package:um_collect/pages/NRW.dart';
import 'package:um_collect/pages/NRWLeakages.dart';
import 'package:um_collect/pages/NRW_assigned.dart';
import 'package:um_collect/pages/NRWComplete.dart';
import 'package:um_collect/pages/home.dart';
import 'package:um_collect/pages/navigatetoasset.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:um_collect/components/MyDrawer.dart';
import 'package:um_collect/components/MyRow.dart';
import 'package:um_collect/components/MyRowIII.dart';
import 'package:um_collect/components/StaffDrawer.dart';
import 'package:um_collect/components/Utils.dart';
import 'package:um_collect/pages/Assets.dart';
import 'package:um_collect/pages/Routing.dart';
import 'package:um_collect/pages/complete.dart';
import 'package:um_collect/pages/incidences.dart';
import 'package:um_collect/pages/incidences_home.dart';
import 'package:um_collect/pages/assetnavigation.dart';
import 'package:um_collect/pages/pending.dart';
import 'package:um_collect/pages/login.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:um_collect/pages/stafflogin.dart';

class NRW extends StatefulWidget {
  const NRW({super.key});

  @override
  State<NRW> createState() => _NRWState();
}

class _NRWState extends State<NRW> {
  final storage = const FlutterSecureStorage();
  String name = '';
  String staffid = '';
  String position = '';
  String pending = '';
  String complete = '';
  String formattedDate = '';
  String offset = '0';
  bool isnew = false;
  var isLoading;
  Timer? _timer;

  List stats = [];

  @override
  void initState() {
    getDefaultValues();
    super.initState();
  }

  Future<void> getDefaultValues() async {
    try {
      var token = await storage.read(key: "mwstaffjwt");
      var decoded = parseJwt(token.toString());
      formattedDate = DateFormat('MMMM dd, yyyy').format(DateTime.now());
      if (decoded["error"] == "Invalid token") {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const Login()));
      } else {
        setState(() {
          name = decoded["name"];
          staffid = decoded["id"];
          position = decoded["position"];
          isnew = true;
        });
        await storage.write(key: 'staffid', value: staffid);

        fetchStats(staffid, isnew);
      }
    } catch (e) {}
  }

  Future<void> fetchStats(String id, bool isnew) async {
    try {
      setState(() {
        isnew
            ? isLoading = LoadingAnimationWidget.horizontalRotatingDots(
                color: const Color(0xff0288D1),
                size: 100,
              )
            : null;
      });
      final response = await get(
        Uri.parse("${getUrl()}nrw_leakages/assigned/$id/0"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 203) {
        var data = json.decode(response.body);
        setState(() {
          pending = data['countP'];
          complete = data['countR'];
          isLoading = null;
        });
      } else {
      }
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UM Collect',
      theme: ThemeData(
        primaryColor: const Color(0xff0288D1),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff0288D1)),
        useMaterial3: true,
      ),
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
            'NRW ACTIVITIES',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: const Color(0xff0288D1),
        ),
        body: Container(
          color: Colors.grey[50],
          child: Column(
            children: <Widget>[
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xff0288D1),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Welcome",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color: Color(0xff0288D1),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    formattedDate,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Image.asset(
                              'assets/images/stat1.png',
                              width: 64,
                              height: 64,
                              color: Colors.white,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Role: $position',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle("Activities"),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildServiceCard(
                                'Metering Activities',
                                'assets/images/nrw.png',
                                () => Navigator.of(context)
                                    .push(MaterialPageRoute(
                                  builder: (context) => const Interventions(),
                                )),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildServiceCard(
                                'Meter Reading',
                                'assets/images/navigation.png',
                                () => Navigator.of(context)
                                    .push(MaterialPageRoute(
                                  builder: (context) => const NRWMeterReading(),
                                )),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildServiceCard(
                                'Leakage Reporting',
                                'assets/images/water-meter.png',
                                () => Navigator.of(context)
                                    .push(MaterialPageRoute(
                                  builder: (context) => const NRWLeakages(),
                                )),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildSectionTitle("Assigned Tasks"),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildServiceCard(
                                'Pending',
                                'assets/images/pending.png',
                                () => Navigator.of(context)
                                    .push(MaterialPageRoute(
                                  builder: (context) => NRWAssigned(
                                    staffid: staffid,
                                    selectedItem: 0,
                                  ),
                                )),
                                count: pending,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildServiceCard(
                                'Completed',
                                'assets/images/complete.png',
                                () => Navigator.of(context)
                                    .push(MaterialPageRoute(
                                  builder: (context) => NRWComplete(
                                    staffid: staffid,
                                  ),
                                )),
                                count: complete,
                              ),
                            ),
                          ],
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xff0288D1),
      ),
    );
  }

  Widget _buildServiceCard(String title, String image, VoidCallback onTap,
      {String? count}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              image,
              width: 40,
              height: 40,
              color: const Color(0xff0288D1),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xff0288D1),
              ),
              textAlign: TextAlign.center,
            ),
            if (count != null) ...[
              const SizedBox(height: 4),
              Text(
                count,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff0288D1),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
