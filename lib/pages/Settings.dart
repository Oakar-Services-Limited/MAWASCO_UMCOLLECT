// ignore_for_file: file_names, library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:um_collect/components/MyDrawer.dart';
import 'package:um_collect/components/MyTextInput.dart';
import 'package:um_collect/components/StaffDrawer.dart';
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
  bool isLoadingDetails = true;

  @override
  initState() {
    super.initState();
    getUserDetails();
  }

  //Fetch user details from API
  getUserDetails() async {
    setState(() => isLoadingDetails = true);
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
        setState(() {
          userDetails = decoded;
          isLoadingDetails = false;
        });
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const Login()));
      }
    } catch (e) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const Login()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer:
          userDetails != null ? StaffDrawer(staffid: userDetails["id"]) : null,
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
      body: isLoadingDetails
          ? Center(
              child: LoadingAnimationWidget.staggeredDotsWave(
                color: const Color(0xff0288D1),
                size: 50,
              ),
            )
          : SingleChildScrollView(
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
                          _buildInfoTile(Icons.email, "Email",
                              userDetails?["email"] ?? ""),
                          _buildInfoTile(Icons.phone, "Phone",
                              userDetails?["phone"] ?? ""),
                          _buildInfoTile(Icons.work, "Department",
                              userDetails?["department"] ?? ""),
                          _buildInfoTile(Icons.verified_user, "Role",
                              userDetails?["role"] ?? ""),
                          _buildInfoTile(
                              Icons.admin_panel_settings,
                              "Access Level",
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
            if (error.isNotEmpty && isLoading == null)
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
                  backgroundColor: isLoading != null
                      ? Colors.grey[300]
                      : const Color(0xff0288D1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isLoading != null ? "Updating..." : "Update Password",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isLoading != null ? Colors.grey[600] : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePasswordChange() async {
    if (oldPass.length < 5 || nePass.length < 5 || cPass.length < 5) {
      setState(() {
        successful = false;
        error = "One of the Passwords is too short!";
      });
      return;
    }

    if (nePass != cPass) {
      setState(() {
        successful = false;
        error = "Passwords do not match!";
      });
      return;
    }

    setState(() {
      isLoading = LoadingAnimationWidget.staggeredDotsWave(
        color: const Color(0xff0288D1),
        size: 100,
      );
      error = '';
    });

    try {
      final token = await storage.read(key: "mwstaffjwt");
      final response = await http.post(
        Uri.parse("${getUrl()}admin/change-password"),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'newPassword': nePass,
          'oldPassword': oldPass,
        }),
      );

      final data = jsonDecode(response.body);
      print(data);

      if (response.statusCode == 200 || response.statusCode == 203) {
        setState(() {
          successful = true;
          error = data['message'];
        });

        await storage.write(key: 'mwstaffjwt', value: "");
        Timer(const Duration(seconds: 1), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const StaffLogin()),
          );
        });
      } else {
        setState(() {
          successful = false;
          error = data['message'] ?? "Server error! Contact administrator.";
        });
      }
    } catch (e) {
      print(e);
      setState(() {
        successful = false;
        error = "Server connection failed! Check your internet.";
      });
    } finally {
      setState(() => isLoading = null);
    }
  }
}
