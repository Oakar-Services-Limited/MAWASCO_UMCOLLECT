// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:um_collect/pages/complete.dart';
import 'package:um_collect/pages/pending.dart';

class IncidencesHome extends StatefulWidget {
  final String staffid;
  final int selectedItem;
  const IncidencesHome(
      {super.key, required this.staffid, required this.selectedItem});

  @override
  State<IncidencesHome> createState() => _IncidencesHomeState();
}

class _IncidencesHomeState extends State<IncidencesHome> {
  late final PageController _pageController;
  final storage = const FlutterSecureStorage();
  int _selectedItem = 0;
  int _pendingRefreshNonce = 0;
  int _completeRefreshNonce = 0;

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

  void _onTabSelected(int index) {
    setState(() {
      _selectedItem = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 200),
      curve: Curves.linear,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        onPageChanged: (index) {
          setState(() {
            _selectedItem = index;
            if (index == 0) {
              _pendingRefreshNonce++;
            } else {
              _completeRefreshNonce++;
            }
          });
        },
        controller: _pageController,
        children: [
          PendingIncidences(
            staffid: widget.staffid,
            refreshNonce: _pendingRefreshNonce,
          ),
          CompleteIncidences(
            staffid: widget.staffid,
            refreshNonce: _completeRefreshNonce,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.login_rounded), label: 'Pending'),
          BottomNavigationBarItem(icon: Icon(Icons.login), label: 'Complete'),
        ],
        currentIndex: _selectedItem,
        onTap: _onTabSelected,
        fixedColor: Colors.orange,
      ),
    );
  }
}
