import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:um_collect/components/StaffDrawer.dart';
import 'package:um_collect/components/Utils.dart';
import 'package:um_collect/components/gridview_assets.dart';
import 'package:um_collect/pages/home.dart';
import 'package:geolocator/geolocator.dart';

class Assets extends StatefulWidget {
  final String staffid;
  const Assets({super.key, required this.staffid});

  @override
  State<Assets> createState() => _AssetsState();
}

class _AssetsState extends State<Assets> {
  final storage = const FlutterSecureStorage();
  String user = '';
  String id = '';
  bool servicestatus = false;

  late LocationPermission permission;
  bool haspermission = false;
  late Position position;

  Future<void> getUserDetails() async {
    var token = await storage.read(key: "mwstaffjwt");
    var decoded = parseJwt(token.toString());

    setState(() {
      user = decoded["name"];
      id = decoded["id"];
      storage.write(key: "UserName", value: user);
      storage.write(key: "UserID", value: id);
    });
  }

  @override
  void initState() {
    getUserDetails();
    storage.delete(key: "updateLocation");
    storage.delete(key: "editing");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Map Assets',
      theme: ThemeData(
        primaryColor: const Color(0xff0288D1),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff0288D1)),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xff0288D1),
          elevation: 0,
          centerTitle: true,
        ),
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
            'Map Assets',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        drawer: StaffDrawer(
          staffid: widget.staffid,
        ),
        body: Container(
          color: Colors.grey[50],
          child: SafeArea(
            child: GridViewAssets(
              staffid: widget.staffid,
            ),
          ),
        ),
      ),
    );
  }
}
