// ignore_for_file: file_names, prefer_typing_uninitialized_variables
import 'dart:async';
import 'dart:convert';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:http/http.dart';
import 'package:um_collect/components/MyTextInputII.dart';
import 'package:um_collect/components/SubmitButton.dart';
import 'package:um_collect/components/Utils.dart';
import 'package:um_collect/pages/TextOakar.dart';

class ForgotPasswordDialog extends StatefulWidget {
  const ForgotPasswordDialog({super.key});

  @override
  State<ForgotPasswordDialog> createState() => _ForgetPasswordDialogState();
}

class _ForgetPasswordDialogState extends State<ForgotPasswordDialog> {
  String email = '';
  var isLoading;
  String error = '';
  final storage = const FlutterSecureStorage();
  bool successful = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(2.0),
      ),
      child: SizedBox(
        width: double.infinity,
        height: MediaQuery.of(context).size.height / 3.6,
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(color: Colors.white54),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Center(
                      child: Text(
                        "Change Password",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: Color(0xff0288D1)),
                      ),
                    ),
                    MyTextInputII(
                      lines: 1,
                      value: '',
                      type: TextInputType.emailAddress,
                      customIcon: Icons.email,
                      onSubmit: (value) {
                        setState(() {
                          email = value;
                        });
                      },
                      hint: 'Email',
                      mycolor: const Color(0xff0288D1),
                      iconcolor: const Color(0xff0288D1),
                    ),
                    TextOakar(label: error, issuccessful: successful),
                    const SizedBox(
                      height: 16,
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: SubmitButton(
                        label: "Submit",
                        onButtonPressed: () async {
                          setState(() {
                            isLoading =
                                LoadingAnimationWidget.horizontalRotatingDots(
                              color: const Color.fromARGB(248, 186, 12, 47),
                              size: 100,
                            );
                          });
                          var res = await recoverPassword(email);
                          setState(() {
                            isLoading = null;
                            if (res.error == null) {
                              error = res.success;
                              successful = true;
                              Timer(const Duration(seconds: 1), () {
                                Navigator.of(context).pop();
                              });
                            } else {
                              error = res.error;
                              successful = false;
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: isLoading,
            ),
          ],
        ),
      ),
    );
  }
}

Future<Message> recoverPassword(String email) async {
  if (email.isEmpty || !EmailValidator.validate(email)) {
    return Message(
      token: null,
      success: null,
      error: "Please Enter Your Email",
    );
  }

  try {
    final response = await post(
      Uri.parse("${getUrl()}publicusers/forgot"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'Email': email,
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
      error: "Connection failed! Check your internet connection.",
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
