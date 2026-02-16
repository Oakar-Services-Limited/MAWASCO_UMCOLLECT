// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names, file_names, prefer_typing_uninitialized_variables

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'package:geolocator/geolocator.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:http/http.dart' as http;
import 'package:um_collect/components/MySearchableSelectInput.dart';
import 'package:um_collect/components/MyTextInput.dart';
import 'package:um_collect/components/StaffDrawer.dart';
import 'package:um_collect/components/Utils.dart';
import 'package:um_collect/pages/home.dart';

class MasterMeterReadings extends StatefulWidget {
  const MasterMeterReadings({
    super.key,
  });

  @override
  State<MasterMeterReadings> createState() => _MasterMeterReadingsState();
}

class _MasterMeterReadingsState extends State<MasterMeterReadings> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final storage = const FlutterSecureStorage();
  late Position position;

  String error = '';
  String staffid = '';
  String metername = '';
  String meterreading = '';
  String myimage = '';
  var isLoading;

  late File? _image;
  final imagePicker = ImagePicker();
  
  List<String> masterMeterNames = ["--Select--"];
  bool isLoadingMeters = false;

  void _showMessage(String message, bool isError) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
      action: SnackBarAction(
        label: 'Dismiss',
        textColor: Colors.white,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<String> convertFileToBase64(XFile file) async {
    List<int> fileBytes = await file.readAsBytes();
    String base64String = base64Encode(fileBytes);
    return base64String;
  }

  Future<void> takePhoto() async {
    final pickedFile = await imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
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
    super.initState();
    _image = null;
    fetchStoredData();
    _loadMasterMeters();
    // Clear any lingering success snackbar from a previous submit when opening the page afresh
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }
    });
  }

  /// List from Utils (preloaded on Home when possible); search on frontend in MySearchableSelectInput.
  Future<void> _loadMasterMeters() async {
    final cached = getMasterMeterNamesCached();
    if (cached != null && cached.isNotEmpty) {
      setState(() {
        masterMeterNames = ["--Select--", ...cached];
        isLoadingMeters = false;
      });
      return;
    }
    setState(() => isLoadingMeters = true);
    final names = await getMasterMeterNames();
    if (!mounted) return;
    setState(() {
      masterMeterNames = ["--Select--", ...names];
      isLoadingMeters = false;
    });
  }

  Future<void> fetchStoredData() async {
    try {
      var token = await storage.read(key: "mwstaffjwt");
      var decoded = parseJwt(token.toString());

      setState(() {
        staffid = decoded["UserID"];
      });
    } catch (e) {
      // 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xff0288D1),
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Master Meter Reading',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      drawer: StaffDrawer(staffid: staffid),
      body: Stack(
        children: [
          Container(
            color: Colors.grey[50],
            child: SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const Text(
                          "All fields marked with * are required",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),
                        isLoadingMeters
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: CircularProgressIndicator(
                                    color: Color(0xff0288D1),
                                  ),
                                ),
                              )
                            : MySearchableSelectInput(
                                onSubmit: (value) {
                                  setState(() {
                                    metername = value;
                                  });
                                },
                                list: masterMeterNames,
                                label: 'Select Meter Name',
                                value: metername,
                              ),
                        const SizedBox(height: 20),
                        MyTextInput(
                          lines: 1,
                          value: meterreading,
                          type: const TextInputType.numberWithOptions(
                              decimal: true),
                          onSubmit: (value) {
                            setState(() {
                              meterreading = value;
                            });
                          },
                          title: 'Enter Meter Reading',
                        ),
                        const SizedBox(height: 20),
                        Column(
                          children: [
                            const Text(
                              'Take Meter Photo',
                              style: TextStyle(
                                color: Color(0xff0288D1),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              height: 250,
                              clipBehavior: Clip.hardEdge,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color:
                                      const Color(0xff0288D1).withValues(alpha:0.1),
                                ),
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (_image != null)
                                    Image.file(
                                      _image!,
                                      fit: BoxFit.cover,
                                    )
                                  else
                                    const Center(
                                      child: Text(
                                        "No image selected",
                                        style: TextStyle(
                                          color: Color(0xff0288D1),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  Positioned(
                                    bottom: 16,
                                    right: 16,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xff0288D1),
                                        borderRadius: BorderRadius.circular(30),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withValues(alpha:0.2),
                                            blurRadius: 6,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.camera_alt_rounded,
                                          color: Colors.white,
                                          size: 26,
                                        ),
                                        onPressed: takePhoto,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () async {
                              setState(() {
                                isLoading =
                                    LoadingAnimationWidget.staggeredDotsWave(
                                  color: const Color(0xff0288D1),
                                  size: 100,
                                );
                              });

                              var res = await submitData(
                                metername,
                                meterreading,
                                myimage,
                              );

                              if (!mounted) return;
                              setState(() {
                                isLoading = null;
                              });

                              if (res.error == null) {
                                _showMessage(
                                    res.success ??
                                        "Reading submitted successfully",
                                    false);
                                Timer(const Duration(seconds: 2), () {
                                  if (!mounted) return;
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const Home()),
                                  );
                                });
                              } else {
                                _showMessage(
                                    res.error ?? "Failed to submit reading",
                                    true);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff0288D1),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Submit',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading != null)
            Container(
              color: Colors.black.withValues(alpha:0.3),
              child: Center(
                child: isLoading,
              ),
            ),
        ],
      ),
    );
  }
}

Future<Message> submitData(
  String metername,
  String meterreading,
  String myimage,
) async {
  if (metername.isEmpty) {
    return Message(
      token: null,
      success: null,
      error: "Meter Name cannot be empty!",
    );
  }

  if (meterreading.isEmpty) {
    return Message(
      token: null,
      success: null,
      error: "Meter Reading cannot be empty!",
    );
  }

  if (myimage.isEmpty) {
    return Message(
      token: null,
      success: null,
      error: "Take Photo!",
    );
  }

  try {
    http.Response response;

    response = await http.post(
      Uri.parse("${getUrl()}master-meter-reading/create"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'meterName': metername,
        'units': meterreading,
        'image': myimage,
      }),
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 203) {
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
