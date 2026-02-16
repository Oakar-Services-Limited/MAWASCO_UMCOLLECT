// ignore_for_file: file_names, library_private_types_in_public_api, use_build_context_synchronously, prefer_typing_uninitialized_variables

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:um_collect/components/MyDrawer.dart';
import 'package:um_collect/components/MyTextInput.dart';
import 'package:um_collect/pages/TextOakar.dart';
import 'package:um_collect/pages/login.dart';
import 'package:um_collect/pages/publiclogin.dart';
import '../Components/SubmitButton.dart';
import '../Components/Utils.dart';

class PublicSettings extends StatefulWidget {
  const PublicSettings({super.key});

  @override
  State<StatefulWidget> createState() => _PublicSettingsState();
}

class _PublicSettingsState extends State<PublicSettings> {
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
    getToken();
  }

  //Check for Login
  Future<void> getToken() async {
    var token = await storage.read(key: "mwjwt");
    var decoded = parseJwt(token.toString());
    if (decoded["error"] == "Invalid token") {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const Login()));
    } else {
      setState(() {
        userDetails = decoded;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Row(
            children: [
              const Flexible(
                flex: 1,
                fit: FlexFit.tight,
                child: Text(
                  "My Account",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: const Icon(Icons.arrow_back),
              )
            ],
          ),
          backgroundColor: const Color(0xff0288D1),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        drawer: const MyDrawer(),
        body: Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          decoration: const BoxDecoration(color: Colors.white54),
          child: Stack(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(0, 10, 16, 10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "User Details",
                          style: TextStyle(
                              fontSize: 24,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 16, 10),
                      child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Name: ${userDetails != null ? userDetails["Name"] : ""}",
                            style: const TextStyle(
                                color: Color(0xff0288D1), fontSize: 16),
                          )),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 16, 10),
                      child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Phone: ${userDetails != null ? userDetails["Phone"] : ""}",
                            style: const TextStyle(
                                color: Color(0xff0288D1), fontSize: 16),
                          )),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 16, 10),
                      child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Email: ${userDetails != null ? userDetails["Email"] : ""}",
                            style: const TextStyle(
                                color: Color(0xff0288D1), fontSize: 16),
                          )),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 16, 10),
                      child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Status: ${userDetails != null ? userDetails["Status"] : ""}",
                            style: const TextStyle(
                                color: Color(0xff0288D1), fontSize: 16),
                          )),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(0, 0, 16, 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Change Password",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ),
                    MyTextInput(
                      title: "Current Password",
                      value: "",
                      onSubmit: (v) {
                        setState(() {
                          oldPass = v;
                        });
                      },
                      lines: 1,
                      type: TextInputType.visiblePassword,
                    ),
                    MyTextInput(
                      title: "New Password",
                      value: "",
                      onSubmit: (v) {
                        setState(() {
                          nePass = v;
                        });
                      },
                      lines: 1,
                      type: TextInputType.visiblePassword,
                    ),
                    MyTextInput(
                      title: "Confirm Password",
                      value: "",
                      onSubmit: (v) {
                        setState(() {
                          cPass = v;
                        });
                      },
                      lines: 1,
                      type: TextInputType.visiblePassword,
                    ),
                    TextOakar(label: error, issuccessful: successful),
                    const SizedBox(
                      height: 16,
                    ),
                    SubmitButton(
                      label: "Submit",
                      onButtonPressed: () async {
                        setState(() {
                          isLoading = LoadingAnimationWidget.staggeredDotsWave(
                            color: const Color(0xff0288D1),
                            size: 100,
                          );
                        });
                        var res = await changePass(
                            oldPass, nePass, cPass, userDetails["UserID"]);
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
                          await storage.write(key: 'mwjwt', value: "");
                          Timer(const Duration(seconds: 1), () {
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const PublicLogin()));
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            Center(child: isLoading),
          ]),
        ));
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
      Uri.parse("${getUrl()}publicusers/update/$id"),
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
  dynamic token;
  dynamic success;
  dynamic error;

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
