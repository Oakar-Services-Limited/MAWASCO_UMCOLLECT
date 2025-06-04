// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:um_collect/components/FootNote.dart';
import 'package:um_collect/pages/Assets.dart';
import 'package:um_collect/pages/Settings.dart';
import 'package:um_collect/pages/home.dart';
import 'package:um_collect/pages/incidences.dart';
import 'package:um_collect/pages/incidences_home.dart';
import 'package:um_collect/pages/login.dart';
import 'package:um_collect/pages/assetnavigation.dart';
import 'package:um_collect/pages/privaypolicy.dart';

class StaffDrawer extends StatefulWidget {
  final String staffid;
  const StaffDrawer({super.key, required this.staffid});

  @override
  State<StaffDrawer> createState() => _StaffDrawerState();
}

class _StaffDrawerState extends State<StaffDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xff0288D1), Color(0xff03A9F4)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 80,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'UM Collect',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildDrawerItem(
                      icon: Icons.home,
                      title: 'Home',
                      onTap: () => Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (_) => const Home())),
                    ),

                    _buildDrawerItem(
                      icon: Icons.sync_problem,
                      title: 'Report Incidence',
                      onTap: () => Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (_) => const Incidences())),
                    ),
                  
                    _buildDrawerItem(
                      icon: Icons.settings,
                      title: 'Settings',
                      onTap: () => Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (_) => const Settings())),
                    ),
                    _buildDrawerItem(
                      icon: Icons.privacy_tip,
                      title: 'Privacy Policy',
                      onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PrivacyPolicy())),
                    ),
                    _buildDrawerItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      onTap: () {
                        const store = FlutterSecureStorage();
                        store.deleteAll();
                        Navigator.pushReplacement(context,
                            MaterialPageRoute(builder: (_) => const Login()));
                      },
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child:
                    Align(alignment: Alignment.bottomLeft, child: FootNote()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      tileColor: Colors.white.withOpacity(0.1),
      hoverColor: Colors.white.withOpacity(0.2),
    );
  }
}
