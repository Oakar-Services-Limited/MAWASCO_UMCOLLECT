// ignore_for_file: prefer_typing_uninitialized_variables

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:um_collect/Components/MyTextInput.dart';
import 'package:um_collect/components/SubmitButton.dart';
import 'package:um_collect/components/Utils.dart';
import 'package:um_collect/pages/TextOakar.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:http/http.dart';
import 'package:um_collect/pages/publiclogin.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String error = '';
  String name = '';
  String email = '';
  String phone = '';
  String password = '';
  bool successful = false;

  var isLoading;
  final storage = const FlutterSecureStorage();

  void register() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const Register()));
  }

  void resetPassword() {}

  void goToLogin() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const PublicLogin()));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Register',
      theme: ThemeData(),
      home: Scaffold(
        body: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: Colors.white54),
          child: Center(
            child: SizedBox(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 0, 24),
                      child: Center(
                          child: Image.asset(
                        'assets/images/logo.png',
                        width: 200,
                      )),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'User Registration',
                              style: TextStyle(
                                  fontSize: 44,
                                  color: Colors.deepOrange,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(
                              height: 24,
                            ),
                            Form(
                                key: _formKey,
                                autovalidateMode: AutovalidateMode.always,
                                child: Column(
                                  children: [
                                    MyTextInput(
                                      lines: 1,
                                      value: '',
                                      type: TextInputType.name,
                                      onSubmit: (value) {
                                        setState(() {
                                          name = value;
                                        });
                                      },
                                      title: 'Username',
                                    ),
                                    const SizedBox(
                                      height: 24,
                                    ),
                                    MyTextInput(
                                      lines: 1,
                                      value: '',
                                      type: TextInputType.emailAddress,
                                      onSubmit: (value) {
                                        setState(() {
                                          email = value;
                                        });
                                      },
                                      title: 'Email (Optional)',
                                    ),
                                    const SizedBox(
                                      height: 24,
                                    ),
                                    MyTextInput(
                                      lines: 1,
                                      value: '',
                                      type: TextInputType.phone,
                                      onSubmit: (value) {
                                        setState(() {
                                          phone = value;
                                        });
                                      },
                                      title: 'Phone',
                                    ),
                                    const SizedBox(
                                      height: 24,
                                    ),
                                    MyTextInput(
                                      lines: 1,
                                      value: '',
                                      type: TextInputType.visiblePassword,
                                      onSubmit: (value) {
                                        setState(() {
                                          password = value;
                                        });
                                      },
                                      title: 'Password',
                                    ),
                                    const SizedBox(
                                      height: 12,
                                    ),
                                    TextOakar(
                                        label: error, issuccessful: successful),
                                    const SizedBox(
                                      height: 12,
                                    ),
                                    Center(
                                      child: isLoading ?? const SizedBox(),
                                    ),
                                    Align(
                                      alignment: Alignment.bottomCenter,
                                      child: SubmitButton(
                                        label: "Register",
                                        onButtonPressed: () async {
                                          setState(() {
                                            isLoading = LoadingAnimationWidget
                                                .staggeredDotsWave(
                                              color: const Color.fromARGB(
                                                  255, 6, 67, 75),
                                              size: 50,
                                            );
                                          });
                                          var res = await submitData(
                                              name, email, phone, password);
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
                                            // PROCEED TO NEXT PAGE
                                            await storage.write(
                                                key: 'umjwt', value: res.token);
                                            goToLogin();
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<Message> submitData(
    String name, String email, String phone, String password) async {
  if (name.isEmpty || phone.isEmpty || password.isEmpty) {
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
      Uri.parse("${getUrl()}publicusers/register"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'Name': name,
        'Email': email,
        'Phone': phone,
        'Password': password
      }),
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
      error: "Connection failed! Check your internet connection.!",
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
