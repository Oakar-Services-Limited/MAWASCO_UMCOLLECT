// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kiambu_umcollect/components/FootNote.dart';
import 'package:kiambu_umcollect/pages/Settings.dart';
import 'package:kiambu_umcollect/pages/home.dart';
import 'package:kiambu_umcollect/pages/incidences.dart';
import 'package:kiambu_umcollect/pages/incidences_home.dart';
import 'package:kiambu_umcollect/pages/login.dart';
import 'package:kiambu_umcollect/pages/assetnavigation.dart';
import 'package:kiambu_umcollect/pages/privaypolicy.dart';

class StaffDrawer extends StatefulWidget {
  final String staffid;
  const StaffDrawer({super.key, required this.staffid});

  @override
  State<StaffDrawer> createState() => _StaffDrawerState();
}

class _StaffDrawerState extends State<StaffDrawer> {
  TextStyle style = const TextStyle(
      color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xff0288D1),
        ),
        child: Column(
          children: [
            Flexible(
              child: ListView(
                // Important: Remove any padding from the ListView.
                padding: const EdgeInsets.all(0),
                children: [
                  DrawerHeader(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(
                            child: Image.asset(
                          'assets/images/logo.png',
                          width: 100,
                        )),
                        const SizedBox(
                          height: 12,
                        ),
                        const Text(
                          'UM Collect',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 28,
                              color: Color(0xff0288D1),
                              fontWeight: FontWeight.w200),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(context,
                              MaterialPageRoute(builder: (_) => const Home()));
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(Icons.home, color: Colors.white),
                              SizedBox(
                                width: 24,
                              ),
                              Text(
                                'Home',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w400),
                              ),
                            ],
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const Incidences()));
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(Icons.sync_problem, color: Colors.white),
                              SizedBox(
                                width: 24,
                              ),
                              Text(
                                'Report Incident',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w400),
                              ),
                            ],
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => AssetNavigation(
                                        staffid: widget.staffid,
                                      )));
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(Icons.navigation, color: Colors.white),
                              SizedBox(
                                width: 24,
                              ),
                              Text(
                                'Asset Navigation',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w400),
                              ),
                            ],
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => IncidencesHome(
                                        staffid: widget.staffid,
                                        selectedItem: 0,
                                      )));
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(Icons.manage_history, color: Colors.white),
                              SizedBox(
                                width: 24,
                              ),
                              Text(
                                'Incident Management',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w400),
                              ),
                            ],
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          const store = FlutterSecureStorage();
                          store.deleteAll();
                          Navigator.pushReplacement(context,
                              MaterialPageRoute(builder: (_) => const Login()));
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(Icons.gps_fixed, color: Colors.white),
                              SizedBox(
                                width: 24,
                              ),
                              Text(
                                'Asset Mapping',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w400),
                              ),
                            ],
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const Settings()));
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(Icons.settings, color: Colors.white),
                              SizedBox(
                                width: 24,
                              ),
                              Text(
                                'Settings',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w400),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // TextButton(
                      //   onPressed: () {
                      //     Navigator.pushReplacement(
                      //         context,
                      //         MaterialPageRoute(
                      //             builder: (_) => const MyWallet(
                      //                   balance: 0.0,
                      //                 )));
                      //   },
                      //   child: const Padding(
                      //     padding: EdgeInsets.all(8),
                      //     child: Row(
                      //       mainAxisAlignment: MainAxisAlignment.start,
                      //       children: [
                      //         Icon(Icons.wallet, color: Colors.white),
                      //         SizedBox(
                      //           width: 24,
                      //         ),
                      //         Text(
                      //           'MyWallet',
                      //           style: TextStyle(
                      //               color: Colors.white,
                      //               fontSize: 20,
                      //               fontWeight: FontWeight.w400),
                      //         ),
                      //       ],
                      //     ),
                      //   ),
                      // ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const PrivacyPolicy()));
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(Icons.privacy_tip, color: Colors.white),
                              SizedBox(
                                width: 24,
                              ),
                              Text(
                                'Privacy Policy',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w400),
                              ),
                            ],
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          const store = FlutterSecureStorage();
                          store.deleteAll();
                          Navigator.pushReplacement(context,
                              MaterialPageRoute(builder: (_) => const Login()));
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(Icons.logout, color: Colors.white),
                              SizedBox(
                                width: 24,
                              ),
                              Text(
                                'Logout',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w400),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Align(alignment: Alignment.bottomLeft, child: FootNote())
          ],
        ),
      ),
    );
  }
}
