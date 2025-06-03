// ignore_for_file: file_names, library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:um_collect/components/MyDrawer.dart';
import 'package:um_collect/components/MyTextInput.dart';
import 'package:um_collect/pages/TextOakar.dart';
import 'package:um_collect/pages/home.dart';
import 'package:um_collect/pages/login.dart';
import 'package:um_collect/pages/stafflogin.dart';
import '../Components/SubmitButton.dart';
import '../Components/Utils.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<StatefulWidget> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  Color mpurple = const Color.fromRGBO(90, 66, 92, 1);
  String date = '';
  final storage = const FlutterSecureStorage();
  bool checkedin = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  var userDetails;
  String oldPass = "";
  String nePass = "";
  String cPass = "";
  String error = '';
  var isLoading;
  bool successful = false;

  @override
  initState() {
    super.initState();
    getUserDetails();
  }

  //Fetch user details from API
  getUserDetails() async {
    try {
      var token = await storage.read(key: "mwstaffjwt");
      if (token == null) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const Login()));
        return;
      }

      final response = await http.get(
        Uri.parse("${getUrl()}admin/mydetails"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        var decoded = jsonDecode(response.body);
        print("decoded: $decoded");
        setState(() {
          userDetails = decoded;
        });
      } else {
        print(
            "Failed to fetch user details. Status code: ${response.statusCode}");
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const Login()));
      }
    } catch (e) {
      print("Error fetching user details: $e");
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const Login()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xff0288D1),
        title: const Text(
          "My Account",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Home()),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xff0288D1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: Color(0xff0288D1),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userDetails?["name"] ?? "",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    userDetails?["position"] ?? "",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoSection("Personal Information", [
                    _buildInfoTile(
                        Icons.email, "Email", userDetails?["email"] ?? ""),
                    _buildInfoTile(
                        Icons.phone, "Phone", userDetails?["phone"] ?? ""),
                    _buildInfoTile(Icons.work, "Department",
                        userDetails?["department"] ?? ""),
                    _buildInfoTile(Icons.verified_user, "Role",
                        userDetails?["role"] ?? ""),
                    _buildInfoTile(Icons.admin_panel_settings, "Access Level",
                        userDetails?["accessLevel"] ?? ""),
                    _buildInfoTile(
                      Icons.circle,
                      "Status",
                      userDetails?["status"] ?? "",
                      statusColor: userDetails?["status"] == "Active"
                          ? Colors.green
                          : Colors.red,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildPasswordSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xff0288D1),
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value,
      {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: statusColor ?? Colors.grey[600], size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: statusColor ?? Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Change Password",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xff0288D1),
              ),
            ),
            const SizedBox(height: 16),
            MyTextInput(
              title: "Current Password",
              value: "",
              onSubmit: (v) => setState(() => oldPass = v),
              lines: 1,
              type: TextInputType.visiblePassword,
            ),
            MyTextInput(
              title: "New Password",
              value: "",
              onSubmit: (v) => setState(() => nePass = v),
              lines: 1,
              type: TextInputType.visiblePassword,
            ),
            MyTextInput(
              title: "Confirm Password",
              value: "",
              onSubmit: (v) => setState(() => cPass = v),
              lines: 1,
              type: TextInputType.visiblePassword,
            ),
            if (error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: TextOakar(label: error, issuccessful: successful),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handlePasswordChange,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff0288D1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isLoading != null ? "Updating..." : "Update Password",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePasswordChange() {
    setState(() {
      isLoading = LoadingAnimationWidget.staggeredDotsWave(
        color: const Color(0xff0288D1),
        size: 100,
      );
    });
    changePass(oldPass, nePass, cPass, userDetails["id"]).then((res) {
      setState(() {
        isLoading = null;
        if (res.error == null) {
          successful = true;
          error = res.success;
        } else {
          successful = false;
          error = res.error;
        }
      });
      if (res.error == null) {
        storage.write(key: 'mwstaffjwt', value: "");
        Timer(const Duration(seconds: 1), () {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const StaffLogin()));
        });
      }
    });
  }
}

Future<Message> changePass(
    String oldPass, String newPass, String cPass, String id) async {
  if (oldPass.length < 5 || newPass.length < 5 || cPass.length < 5) {
    return Message(
      token: null,
      success: null,
      error: "One of the Passwords is too short!",
    );
  }
  if (newPass != cPass) {
    return Message(
      token: null,
      success: null,
      error: "Passwords do not match!",
    );
  }
  if (id == "") {
    return Message(
      token: null,
      success: null,
      error: "You are not logged in!",
    );
  }

  try {
    final response = await http.put(
      Uri.parse("${getUrl()}mobile/$id"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(
          <String, String>{'NewPassword': newPass, 'Password': oldPass}),
    );
    if (response.statusCode == 200 || response.statusCode == 203) {
      return Message.fromJson(jsonDecode(response.body));
    } else {
      return Message(
        token: null,
        success: null,
        error: "Server error! Contact administrator.",
      );
    }
  } catch (e) {
    return Message(
      token: null,
      success: null,
      error: "Server connection failed! Check your internet.",
    );
  }
}

class Message {
  var token;
  var success;
  var error;

  Message({
    required this.token,
    required this.success,
    required this.error,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      token: json['token'],
      success: json['success'],
      error: json['error'],
    );
  }
}
