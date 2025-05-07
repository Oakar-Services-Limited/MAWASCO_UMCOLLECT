// ignore_for_file: file_names, prefer_typing_uninitialized_variables

import 'package:http/http.dart';
import 'package:kiambu_umcollect/pages/incidences.dart';

import '../Components/SubmitButton.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../Components/Utils.dart';

class PublicLogin extends StatefulWidget {
  const PublicLogin({super.key});

  @override
  State<StatefulWidget> createState() => _PublicLoginState();
}

class _PublicLoginState extends State<PublicLogin> {
  String phone = '';
  String password = '';
  String error = '';
  bool successful = false;
  var isLoading;
  final storage = const FlutterSecureStorage();

  String appendIfNotExists(String idString, String newId) {
    List<String> idList = idString.split("=");
    String newIdString = newId.toString();
    if (!idList.contains(newIdString)) {
      idList.add(newIdString);
    }
    return idList.join("=");
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen size
    final size = MediaQuery.of(context).size;

    return MaterialApp(
      title: "UM Collect Staff Login",
      theme: ThemeData(
        primaryColor: const Color(0xff0288D1),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff0288D1)),
        useMaterial3: true,
      ),
      home: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: <Widget>[
            Container(
              height: double.infinity,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Color(0xFFE3F2FD),
                  ],
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.06,
                        vertical: size.height * 0.02,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: size.height * 0.8,
                          minWidth: size.width * 0.9,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Hero(
                              tag: 'logo',
                              child: Container(
                                padding: EdgeInsets.all(size.width * 0.05),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  width: size.width * 0.3,
                                ),
                              ),
                            ),
                            SizedBox(height: size.height * 0.04),
                            Text(
                              "Mathira Water and Sanitation Company",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: size.width * 0.045,
                                color: const Color(0xff0288D1),
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: size.height * 0.02),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: size.width * 0.05,
                                vertical: size.height * 0.01,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xff0288D1).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                "Incident Reporting",
                                style: TextStyle(
                                  fontSize: size.width * 0.04,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xff0288D1),
                                ),
                              ),
                            ),
                            SizedBox(height: size.height * 0.06),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(size.width * 0.06),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Report an Incident",
                                    style: TextStyle(
                                      fontSize: size.width * 0.035,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xff0288D1),
                                    ),
                                  ),
                                  SizedBox(height: size.height * 0.01),
                                  Text(
                                    "Help us improve our services by reporting any water-related incidents in your area.",
                                    style: TextStyle(
                                      fontSize: size.width * 0.032,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  SizedBox(height: size.height * 0.03),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        await storage.write(
                                            key: 'isstaff', value: 'false');
                                        Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const Incidences()));
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xff0288D1),
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                          vertical: size.height * 0.015,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Report Now",
                                            style: TextStyle(
                                              fontSize: size.width * 0.035,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(width: size.width * 0.02),
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            size: size.width * 0.04,
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
                    ),
                  ),
                ),
              ),
            ),
            if (isLoading != null)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(child: isLoading),
              ),
          ],
        ),
      ),
    );
  }
}

Future<Message> publicLogin(String phone, String password) async {
  if (phone.isEmpty || password.isEmpty) {
    return Message(
      token: null,
      success: null,
      error: "Empty Field!!",
    );
  }

  if (password.length < 6) {
    return Message(
      token: null,
      success: null,
      error: "Password is too short!",
    );
  }

  try {
    final response = await post(
      Uri.parse("${getUrl()}publicusers/login"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{'Phone': phone, 'Password': password}),
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
      error: "Connection failed! Check your internet connection.",
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
