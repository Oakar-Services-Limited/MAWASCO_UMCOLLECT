// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:um_collect/components/FootNote.dart';
import 'package:um_collect/pages/incidences.dart';
import 'package:um_collect/pages/privaypolicy.dart';
import 'package:um_collect/pages/stafflogin.dart';

class MyDrawer extends StatefulWidget {
  const MyDrawer({super.key});

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  TextStyle style = const TextStyle(
      color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(color: Color(0xff0288D1)),
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                    child: Column(
                      children: [
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
                            Navigator.push(
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
                        // TextButton(
                        //   onPressed: () {
                        //     Navigator.push(
                        //         context,
                        //         MaterialPageRoute(
                        //             builder: (_) => const PublicSettings()));
                        //   },
                        //   child: const Padding(
                        //     padding: EdgeInsets.all(8),
                        //     child: Row(
                        //       mainAxisAlignment: MainAxisAlignment.start,
                        //       children: [
                        //         Icon(Icons.settings, color: Colors.white),
                        //         SizedBox(
                        //           width: 24,
                        //         ),
                        //         Text(
                        //           'Settings',
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
                            // const store = FlutterSecureStorage();
                            // store.deleteAll();
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const StaffLogin()));
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
                                  'Staff Login',
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
