// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:um_collect/pages/NRWComplete.dart';
import 'package:um_collect/pages/NRWpending.dart';

class NRWAssigned extends StatefulWidget {
  final String staffid;
  final int selectedItem;
  const NRWAssigned(
      {super.key, required this.staffid, required this.selectedItem});

  @override
  State<NRWAssigned> createState() => _NRWAssignedState();
}

class _NRWAssignedState extends State<NRWAssigned> {
  late final PageController _pageController;
  final storage = const FlutterSecureStorage();
  int _selectedItem = 0;

  @override
  void initState() {
    super.initState();
    _selectedItem = widget.selectedItem;
    _pageController = PageController(initialPage: _selectedItem);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        onPageChanged: (index) {
          _selectedItem = index;
        },
        controller: _pageController,
        children: [
          NRWPending(staffid: widget.staffid),
          NRWComplete(
            staffid: widget.staffid,
          )
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.login_rounded), label: 'Pending'),
          BottomNavigationBarItem(icon: Icon(Icons.login), label: 'Complete'),
        ],
        currentIndex: _selectedItem,
        onTap: (index) {
          setState(() {
            _selectedItem = index;
            _pageController.animateToPage(_selectedItem,
                duration: const Duration(milliseconds: 200),
                curve: Curves.linear);
          });
        },
        fixedColor: Colors.orange,
      ),
    );
  }
}
