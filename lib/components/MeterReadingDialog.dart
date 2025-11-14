import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:http/http.dart';
import 'package:um_collect/components/MyTextInputII.dart';
import 'package:um_collect/components/SubmitButton.dart';
import 'package:um_collect/components/Utils.dart';
import 'package:um_collect/pages/TextOakar.dart';

class MeterReadingDialog extends StatefulWidget {
  final String accountno;
  final String meterid;
  const MeterReadingDialog(
      {super.key, required this.accountno, required this.meterid});

  @override
  State<MeterReadingDialog> createState() => _ForgetPasswordDialogState();
}

class _ForgetPasswordDialogState extends State<MeterReadingDialog> {
  String meterreading = '';
  var isLoading;
  String error = '';
  final storage = const FlutterSecureStorage();
  bool successful = false;
  late File? _image;
  final imagePicker = ImagePicker();
  String myimage = '';

  Future<String> convertFileToBase64(XFile file) async {
    List<int> fileBytes = await file.readAsBytes();
    String base64String = base64Encode(fileBytes);
    return base64String;
  }

  Future<void> takePhoto() async {
    final pickedFile = await imagePicker.pickImage(
      source: ImageSource.camera, // Open the camera to take a photo
    );

    if (pickedFile != null) {
      String base64Image = await convertFileToBase64(pickedFile);
      setState(() {
        _image = File(pickedFile.path);
        myimage = base64Image;
      });
    }
  }

  @override
  void initState() {
    _image = null;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(2.0),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: double.infinity,
          maxHeight: MediaQuery.of(context).size.height / 2,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Center(
                child: Text(
                  "Meter Reading",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Color(0xff0288D1)),
                ),
              ),
              MyTextInputII(
                lines: 1,
                value: '',
                type: const TextInputType.numberWithOptions(decimal: true),
                customIcon: Icons.account_box_outlined,
                onSubmit: (value) {
                  setState(() {
                    meterreading = value;
                  });
                },
                hint: 'Enter Meter Units',
                mycolor: const Color(0xff0288D1),
                iconcolor: const Color(0xff0288D1),
              ),
              const SizedBox(height: 16),
              const Text(
                'Take a Photo',
                style: TextStyle(
                  color: Color(0xff0288D1),
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Card(
                  elevation: 2,
                  clipBehavior: Clip.hardEdge,
                  child: Stack(
                    children: [
                      SizedBox(
                        height: 250,
                        width: double.infinity,
                        child: _image == null
                            ? const Center(
                                child: Text(
                                  "No image selected",
                                  style: TextStyle(
                                    color: Color(0xff0288D1),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              )
                            : GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Dialog(
                                        child: Container(
                                          color: Colors.black,
                                          child: InteractiveViewer(
                                            child: Image.file(_image!),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                                child: Image.file(
                                  _image!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: IconButton(
                          icon: const Icon(
                            Icons.photo_camera,
                            size: 50,
                            color: Color(0xff0288D1),
                          ),
                          onPressed: () => takePhoto(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              TextOakar(label: error, issuccessful: successful),
              const SizedBox(height: 16),
              SubmitButton(
                label: "Submit",
                onButtonPressed: () async {
                  setState(() {
                    isLoading = LoadingAnimationWidget.horizontalRotatingDots(
                      color: const Color.fromARGB(248, 186, 12, 47),
                      size: 100,
                    );
                  });
                  var res = await submitData(
                      widget.accountno, widget.meterid, meterreading, myimage);
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
              const SizedBox(height: 24),
              if (isLoading != null)
                Center(
                  child: isLoading,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<Message> submitData(
    String accountno, String meterid, String meterreading, String image) async {
  if (meterreading.isEmpty) {
    return Message(
      token: null,
      success: null,
      error: "Enter Meter Reading",
    );
  }

  if (image.isEmpty) {
    return Message(
      token: null,
      success: null,
      error: "Take photo of meter",
    );
  }

  DateTime now = DateTime.now();
  String dateread = DateFormat('yyyy-MM-dd').format(now);
  try {
    final response = await post(
      Uri.parse("${getUrl()}meter-reading/create"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'accountNo': accountno,
        'units': meterreading,
        'dateread': dateread,
        'image': image,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
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
