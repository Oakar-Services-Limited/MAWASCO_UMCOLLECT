// ignore_for_file: prefer_const_constructors, use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:um_collect/components/Utils.dart';
import 'package:um_collect/pages/home.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:um_collect/pages/login.dart';

class Landing extends StatefulWidget {
  const Landing({super.key});

  @override
  State<Landing> createState() => _LandingState();
}

class _LandingState extends State<Landing> {
  final storage = const FlutterSecureStorage();
  bool permission = false;
  var decoded;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    PermissionStatus status = await Permission.location.status;
    if (status.isGranted) {
      authenticateUser();
      setState(() {
        permission = true;
      });
    } else {
      setState(() {
        permission = false;
      });
    }
  }

  Future<void> authenticateUser() async {
    var token = await storage.read(key: "mwjwt") ??
        await storage.read(key: "mwstaffjwt");

    decoded = parseJwt(token.toString());
    storage.write(key: "userid", value: decoded["id"]);
    if (decoded["error"] == "Invalid token") {
      Timer(const Duration(seconds: 1), () {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => Login()));
      });
    } else {
      Timer(const Duration(seconds: 1), () {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => Home()));
      });
    }
  }

  Future<void> requestLocationPermission() async {
    PermissionStatus status = await Permission.location.request();
    if (status == PermissionStatus.granted) {
      authenticateUser();
    } else if (status == PermissionStatus.denied) {
      openAppSettings();
    } else {
      openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Ambulex',
        home: Scaffold(
          body: Stack(
            children: [
              Container(
                height: double.infinity,
                width: double.infinity,
                decoration: const BoxDecoration(color: Colors.white54),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        width: 250,
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      const Text(
                        "MAWASCO \n UM Collect",
                        style: TextStyle(
                            fontSize: 44,
                            color: Color(0xff0288D1),
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      const Text(
                        "",
                        style: TextStyle(fontSize: 18, color: Colors.black54),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      if (!permission)
                        TextButton(
                            onPressed: () => showDialog<String>(
                                  context: context,
                                  builder: (BuildContext context) =>
                                      AlertDialog(
                                    title: const Text('Location Permission'),
                                    content: const Text(
                                        'This app collects location data to enable route navigation to various assets'),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, 'Cancel'),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          requestLocationPermission();
                                          Navigator.pop(context, 'OK');
                                        },
                                        child: const Text('Grant Permissions'),
                                      ),
                                    ],
                                  ),
                                ),
                            child: Container(
                              padding:
                                  const EdgeInsets.fromLTRB(24, 12, 24, 12),
                              decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(10)),
                              child: const Text(
                                "Review App Permissions",
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white),
                              ),
                            ))
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 12, 64, 24),
                  child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                          color: Color(0xff0288D1),
                          borderRadius: BorderRadius.horizontal(
                              right: Radius.circular(44))),
                      child: const Text(
                        "Powered by \n Oakar Services",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white),
                      )),
                ),
              ),
            ],
          ),
        ));
  }
}
