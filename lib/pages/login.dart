// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kiambu_umcollect/pages/publiclogin.dart';
import 'package:kiambu_umcollect/pages/stafflogin.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  int _selectedItem = 0;
  final _pageController = PageController();
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    checkSelection();
    super.initState();
  }

  checkSelection() async {
    var index = await storage.read(key: "login_option");
    if (index == null) {
      setState(() {
        index = '0';
      });
    }
    setState(() {
      _selectedItem = int.parse(index as String);
      _pageController.animateToPage(_selectedItem,
          duration: const Duration(milliseconds: 200), curve: Curves.linear);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        onPageChanged: (index) {
          storage.write(key: "login_option", value: index.toString());
          setState(() {
            _selectedItem = index;
          });
        },
        controller: _pageController,
        children: const [PublicLogin(), StaffLogin()],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Public',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings_outlined),
              activeIcon: Icon(Icons.admin_panel_settings),
              label: 'Staff',
            ),
          ],
          currentIndex: _selectedItem,
          onTap: (index) {
            storage.write(key: "login_option", value: index.toString());
            setState(() {
              _selectedItem = index;
              _pageController.animateToPage(_selectedItem,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.linear);
            });
          },
          selectedItemColor: const Color(0xff0288D1),
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
      ),
    );
  }
}
