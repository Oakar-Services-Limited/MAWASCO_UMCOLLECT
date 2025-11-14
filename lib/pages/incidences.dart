import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:um_collect/components/IRItem.dart';
import 'package:um_collect/components/MyDrawer.dart';
import 'package:um_collect/components/StaffDrawer.dart';
import 'package:um_collect/pages/home.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Components/Utils.dart';

class Category {
  final String id;
  final String name;
  final String? file;
  final bool status;

  Category({
    required this.id,
    required this.name,
    this.file,
    required this.status,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      file: json['file'],
      status: json['status'] ?? true,
    );
  }
}

class Incidences extends StatefulWidget {
  const Incidences({super.key});

  @override
  State<Incidences> createState() => _IncidencesState();
}

class _IncidencesState extends State<Incidences> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final storage = const FlutterSecureStorage();
  List<Category> categories = [];
  bool isLoading = true;
  String? error;

  var isstaff;
  var staffid;

  @override
  void initState() {
    checkStaff();
    fetchCategories();
    super.initState();
  }

  Future<void> fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse("${getUrl()}om/categories"),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return; // Check if widget is still mounted

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            categories = (data['data'] as List)
                .map((category) => Category.fromJson(category))
                .toList();
            isLoading = false;
            error = null;
          });
        } else {
          setState(() {
            error = 'Unable to load incidents. Please try again.';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          error = 'Unable to load incidents. Please try again.';
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return; // Check if widget is still mounted
      setState(() {
        error =
            'Error loading incidences. Please check your internet connection.';
        isLoading = false;
      });
    }
  }

  checkStaff() async {
    var staff = await storage.read(key: "isstaff");
    var id = await storage.read(key: "staffid");
    if (!mounted) return; // Check if widget is still mounted

    setState(() {
      isstaff = staff;
      staffid = id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Incidences',
      theme: ThemeData(
        primaryColor: const Color(0xff0288D1),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff0288D1),
          brightness: Brightness.light,
          primary: const Color(0xff0288D1),
          secondary: const Color(0xFF90CAF9),
        ),
        useMaterial3: true,
      ),
      home: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xff0288D1).withValues(alpha:0.95),
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          actions: <Widget>[
            IconButton(
              icon: const Icon(
                Icons.home_rounded,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const Home()));
              },
            ),
            const SizedBox(width: 8),
          ],
          centerTitle: true,
        ),
        drawer: isstaff == 'true'
            ? StaffDrawer(staffid: staffid)
            : const MyDrawer(),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xff0288D1).withValues(alpha:0.92),
                const Color(0xFFE3F2FD),
              ],
              stops: const [0.2, 0.9],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Incident Type',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Choose the type of incident you want to report',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xff0288D1).withValues(alpha:0.12),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xff0288D1),
                                ),
                              ),
                            )
                          : error != null
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.wifi_off_rounded,
                                          color: Colors.grey,
                                          size: 64,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          error!,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        ElevatedButton.icon(
                                          onPressed: fetchCategories,
                                          icon: const Icon(
                                            Icons.refresh_rounded,
                                            color: Colors.white,
                                          ),
                                          label: const Text(
                                            'Retry',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xff0288D1),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 32,
                                              vertical: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : GridView.builder(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 1,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                                  itemCount: categories.length,
                                  itemBuilder: (context, index) {
                                    final category = categories[index];
                                    final imageName = category.name
                                        .toLowerCase()
                                        .replaceAll(' ', '');
                                    // final imagePath =
                                    //     'assets/images/$imageName.png';
                                    return IRItem(
                                      incident: category.name,
                                      asset: 'assets/images/$imageName.png',
                                      image: 'assets/images/$imageName.png',
                                      categoryId: category.id,
                                    );
                                  },
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
