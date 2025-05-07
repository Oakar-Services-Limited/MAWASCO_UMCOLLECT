// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names, file_names

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kiambu_umcollect/components/MySelectInput.dart';
import 'package:kiambu_umcollect/components/MyTextInput.dart';
import 'package:kiambu_umcollect/components/MyTextInputII.dart';
import 'package:kiambu_umcollect/components/StaffDrawer.dart';
import 'package:kiambu_umcollect/components/SubmitButton.dart';
import 'package:kiambu_umcollect/components/TextResponse.dart';
import 'package:kiambu_umcollect/components/Utils.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kiambu_umcollect/models/Map.dart';
import 'package:kiambu_umcollect/pages/NRW.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:http/http.dart' as http;

class NRWMeterReading extends StatefulWidget {
  const NRWMeterReading({
    super.key,
  });

  @override
  State<NRWMeterReading> createState() => _NRWMeterReadingState();
}

class _NRWMeterReadingState extends State<NRWMeterReading> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final storage = const FlutterSecureStorage();
  late Position position;
  String foundFirstReading = '';
  Timer? _debounceTimer;

  var long = 36.0, lat = -2.0, acc = 100.0;
  String error = '';
  String staffid = '';
  String interval = '';
  String dmaname = '';
  String metertype = '';
  String account = '';
  String firstreading = '';
  String secondreading = '';
  String meterstatus = '';
  String remarks = '';
  String firstdate = '';
  String seconddate = '';

  late File? _image;
  final imagePicker = ImagePicker();
  String myimage = '';
  dynamic data;
  var isLoading;

  // Add these variables to store the fetched data
  TextEditingController firstReadingController = TextEditingController();
  TextEditingController dmaNameController = TextEditingController();
  TextEditingController meterTypeController = TextEditingController();

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

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
    } else {}
  }

  @override
  void initState() {
    _image = null;
    fetchStoredData();
    _initializeDateVariables();
    getLocation();
    super.initState();
  }

  Future<void> fetchStoredData() async {
    try {
      var token = await storage.read(key: "mwstaffjwt");
      var decoded = parseJwt(token.toString());

      setState(() {
        staffid = decoded["id"];
      });
    } catch (e) {}
  }

  void _initializeDateVariables() {
    DateTime today = DateTime.now();

    firstdate =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    setState(() {
      firstdate = firstdate;
    });
  }

  getLocation() async {
    position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      long = position.longitude;
      lat = position.latitude;
      acc = position.accuracy;
    });
  }

  Future<void> searchAccount(String value) async {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        setState(() {
          isLoading = LoadingAnimationWidget.staggeredDotsWave(
            color: const Color(0xff0288D1),
            size: 100,
          );
          error = '';
        });

        final response = await http.get(
          Uri.parse("${getUrl()}nrwreading/search/$value"),
        );

        setState(() {
          isLoading = null;
        });

        if (response.statusCode == 200) {
          var data = json.decode(response.body);
          if (data['data'] != null) {
            setState(() {
              // Populate the controllers with fetched data
              firstReadingController.text = data['data']['FirstReading'] ?? '';
              dmaNameController.text = data['data']['DMAName'] ?? '';
              meterTypeController.text = data['data']['MeterType'] ?? '';

              // Also store in state variables if needed elsewhere
              foundFirstReading = data['data']['FirstReading'] ?? '';
              dmaname = data['data']['DMAName'] ?? '';
              metertype = data['data']['MeterType'] ?? '';
              error = '';
            });
          } else {
            setState(() {
              // Clear the fields if no data found
              firstReadingController.text = '';
              dmaNameController.text = '';
              meterTypeController.text = '';
              foundFirstReading = '';
              dmaname = '';
              metertype = '';
              error = 'No matching record found';
            });
          }
        }
      } catch (e) {
        setState(() {
          isLoading = null;
          error = "Search failed. Please try again.";
        });
      }
    });
  }

  Future<Message> submitData(
    String lat,
    String long,
    String interval,
    String dmaname,
    String metertype,
    String account,
    String firstreading,
    String secondreading,
    String meterstatus,
    String remarks,
    String firstdate,
    String seconddate,
    String myimage,
  ) async {
    // For Second Reading
    if (interval == "Second Reading") {
      if (account.isEmpty) {
        return Message(
          token: null,
          success: null,
          error: "Account No cannot be empty!",
        );
      }

      if (foundFirstReading.isEmpty) {
        return Message(
          token: null,
          success: null,
          error: "No valid first reading found!",
        );
      }

      if (secondreading.isEmpty) {
        return Message(
          token: null,
          success: null,
          error: "Second Reading cannot be empty!",
        );
      }

      if (myimage.isEmpty) {
        return Message(
          token: null,
          success: null,
          error: "Take Second Reading Photo!",
        );
      }

      try {
        final response = await http.put(
          Uri.parse("${getUrl()}nrw_dmareadings/update/secondreading"),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, dynamic>{
            'AccountNo': account,
            'SecondReading': secondreading,
            'SR_Image': myimage,
          }),
        );

        if (response.statusCode == 200 || response.statusCode == 203) {
          return Message.fromJson(jsonDecode(response.body));
        } else {
          print('Second Reading Update Error: ${response.body}');
          return Message(
            token: null,
            success: null,
            error: "Server error! Contact administrator.",
          );
        }
      } catch (e) {
        print('Second Reading Update Exception: $e');
        return Message(
          token: null,
          success: null,
          error: "Connection failed! Check your internet connection.",
        );
      }
    }

    // For First Reading
    if (interval.isEmpty) {
      return Message(
        token: null,
        success: null,
        error: "Reading Interval cannot be empty!",
      );
    }
    if (dmaname.isEmpty) {
      return Message(
        token: null,
        success: null,
        error: "DMA Name cannot be empty!",
      );
    }
    if (metertype.isEmpty) {
      return Message(
        token: null,
        success: null,
        error: "Meter Type cannot be empty!",
      );
    }
    if (account.isEmpty) {
      return Message(
        token: null,
        success: null,
        error: "Account No cannot be empty!",
      );
    }
    if (firstreading.isEmpty) {
      return Message(
        token: null,
        success: null,
        error: "First Reading cannot be empty!",
      );
    }
    if (meterstatus.isEmpty) {
      return Message(
        token: null,
        success: null,
        error: "Meter Status cannot be empty!",
      );
    }
    if (meterstatus == "Not Okay" && remarks.isEmpty) {
      return Message(
        token: null,
        success: null,
        error: "Remarks cannot be empty when Meter Status is 'Not Okay'!",
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
      // Prepare the request body
      final requestBody = {
        'dma_name': dmaname,
        'units': firstreading,
        'meter_status': meterstatus,
        'remarks': remarks,
        'date': firstdate,
        'image': myimage,
        'user_id': staffid,
      };

      print('Sending request with body: $requestBody');

      final response = await http.post(
        Uri.parse("${getUrl()}nrw_dmareadings/"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(requestBody),
      );

      print('Server response: ${response.body}');

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 203) {
        return Message.fromJson(jsonDecode(response.body));
      } else {
        print('First Reading Create Error: ${response.body}');
        return Message(
          token: null,
          success: null,
          error: "Server error! Contact administrator.",
        );
      }
    } catch (e) {
      print('First Reading Create Exception: $e');
      return Message(
        token: null,
        success: null,
        error: "Connection failed! Check your internet connection.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        actions: <Widget>[
          IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => const NRW()));
            },
          ),
        ],
        title: const Text(
          'NRW Meter Reading',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        backgroundColor: const Color(0xff0288D1),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: StaffDrawer(
        staffid: staffid,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(color: Colors.white),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      "All fields marked with * are required",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                      child: SizedBox(
                        height: 250,
                        child: MyMap(
                          lat: lat,
                          lon: long,
                          acc: acc,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Reading Interval Field
                    MySelectInput(
                      onSubmit: (value) {
                        setState(() {
                          interval = value;
                          // Clear fields when interval changes
                          if (interval == "First Reading") {
                            dmaname = '';
                            metertype = '';
                            account = '';
                            firstreading = '';
                            meterstatus = '';
                            remarks = '';
                            _image = null;
                            myimage = '';
                          } else if (interval == "Second Reading") {
                            account = '';
                            foundFirstReading = '';
                            dmaname = '';
                            metertype = '';
                            meterstatus = '';
                            secondreading = '';
                          }
                        });
                      },
                      list: const [
                        "--Select--",
                        "First Reading",
                        "Second Reading",
                      ],
                      label: 'Reading Interval',
                      value: interval,
                    ),
                    const SizedBox(height: 10),
                    // First Reading Workflow
                    if (interval == "First Reading") ...[
                      MySelectInput(
                        onSubmit: (value) {
                          setState(() {
                            dmaname = value;
                          });
                        },
                        list: const [
                          "--Select--",
                          "Kamiti A",
                          "Kamiti B",
                          "Samaki 1",
                          "Samaki 2",
                          "Makanja 1",
                          "Makanja 2",
                          "Kiu River",
                          "Kiu Kenda",
                          "Kanjata",
                          "Kiambu Golf Club"
                        ],
                        label: 'DMA Name',
                        value: dmaname,
                      ),
                      MySelectInput(
                        onSubmit: (value) {
                          setState(() {
                            metertype = value;
                          });
                        },
                        list: const [
                          "--Select--",
                          "Master Meter",
                          "Customer Meter",
                        ],
                        label: 'Meter Type',
                        value: metertype,
                      ),
                      MyTextInput(
                        lines: 1,
                        value: account,
                        type: const TextInputType.numberWithOptions(
                            decimal: false),
                        onSubmit: (value) {
                          setState(() {
                            account = value;
                          });
                        },
                        title: 'Account Number',
                      ),
                      MyTextInput(
                        lines: 1,
                        value: firstreading,
                        type: const TextInputType.numberWithOptions(
                            decimal: true),
                        onSubmit: (value) {
                          setState(() {
                            firstreading = value;
                          });
                        },
                        title: 'Enter First Reading',
                      ),
                      MySelectInput(
                        onSubmit: (value) {
                          setState(() {
                            meterstatus = value;
                          });
                        },
                        list: const [
                          "--Select--",
                          "Okay",
                          "Not Okay",
                        ],
                        label: 'Meter Status',
                        value: meterstatus,
                      ),
                      if (meterstatus == "Not Okay")
                        MySelectInput(
                          onSubmit: (value) {
                            setState(() {
                              remarks = value;
                            });
                          },
                          list: const [
                            "--Select--",
                            "Inside Compound",
                            "Leaking Liners/Meter",
                            "Leaking Gatevalve",
                            "Not Raised",
                            "Misty Dial",
                            "Vertical Installation",
                            "Diagonal/Inclined",
                            "Denied Access",
                            "Cemented On the Wall",
                            "Other Remarks",
                          ],
                          label: 'Remarks',
                          value: remarks,
                        ),
                      const SizedBox(height: 12),
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
                          Card(
                            elevation: 2,
                            clipBehavior: Clip.hardEdge,
                            child: Stack(
                              children: [
                                SizedBox(
                                  height: 250,
                                  width: double.infinity,
                                  child: _image == null
                                      ? const Align(
                                          alignment: Alignment.center,
                                          child: Text(
                                            "No image selected",
                                            style: TextStyle(
                                              color: Color.fromARGB(
                                                  255, 28, 100, 140),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        )
                                      : Stack(
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => Dialog(
                                                    child: Container(
                                                      color: Colors.black,
                                                      child: Stack(
                                                        children: [
                                                          InteractiveViewer(
                                                            child: Image.file(
                                                              _image!,
                                                              fit: BoxFit
                                                                  .contain,
                                                            ),
                                                          ),
                                                          FutureBuilder<void>(
                                                            future: _image!
                                                                .length(),
                                                            builder: (context,
                                                                snapshot) {
                                                              if (snapshot
                                                                      .connectionState ==
                                                                  ConnectionState
                                                                      .done) {
                                                                return const SizedBox();
                                                              }
                                                              return Center(
                                                                child: LoadingAnimationWidget
                                                                    .staggeredDotsWave(
                                                                  color: const Color(
                                                                      0xff0288D1),
                                                                  size: 50,
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Stack(
                                                children: [
                                                  Image.file(
                                                    _image!,
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                    height: 250,
                                                  ),
                                                  FutureBuilder<void>(
                                                    future: _image!.length(),
                                                    builder:
                                                        (context, snapshot) {
                                                      if (snapshot
                                                              .connectionState ==
                                                          ConnectionState
                                                              .done) {
                                                        return const SizedBox();
                                                      }
                                                      return Center(
                                                        child: LoadingAnimationWidget
                                                            .staggeredDotsWave(
                                                          color: const Color(
                                                              0xff0288D1),
                                                          size: 50,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
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
                        ],
                      ),
                    ],
                    // Second Reading Workflow
                    if (interval == "Second Reading") ...[
                      MyTextInputII(
                        hint: 'Search Account Number',
                        lines: 1,
                        value: account,
                        type: const TextInputType.numberWithOptions(
                            decimal: false),
                        onSubmit: (value) {
                          setState(() {
                            account = value;
                          });
                          if (value.length >= 3) {
                            searchAccount(value);
                          }
                        },
                        mycolor: const Color(0xff0288D1),
                        iconcolor: const Color(0xff0288D1),
                        customIcon: Icons.search,
                      ),
                      if (foundFirstReading.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        // Display fetched data in read-only fields
                        TextFormField(
                          controller: dmaNameController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'DMA Name',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Color(0xFFF5F5F5),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: meterTypeController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Meter Type',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Color(0xFFF5F5F5),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: firstReadingController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'First Reading',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Color(0xFFF5F5F5),
                          ),
                        ),
                        const SizedBox(height: 16),
                        MyTextInput(
                          lines: 1,
                          value: secondreading,
                          type: const TextInputType.numberWithOptions(
                              decimal: true),
                          onSubmit: (value) {
                            setState(() {
                              secondreading = value;
                            });
                          },
                          title: 'Enter Second Reading',
                        ),
                        const SizedBox(height: 12),
                        Column(
                          children: [
                            const Text(
                              'Take Second Reading Photo',
                              style: TextStyle(
                                color: Color(0xff0288D1),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Card(
                              elevation: 2,
                              clipBehavior: Clip.hardEdge,
                              child: Stack(
                                children: [
                                  SizedBox(
                                    height: 250,
                                    width: double.infinity,
                                    child: _image == null
                                        ? const Align(
                                            alignment: Alignment.center,
                                            child: Text(
                                              "No image selected",
                                              style: TextStyle(
                                                color: Color.fromARGB(
                                                    255, 28, 100, 140),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          )
                                        : Stack(
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) =>
                                                        Dialog(
                                                      child: Container(
                                                        color: Colors.black,
                                                        child: Stack(
                                                          children: [
                                                            InteractiveViewer(
                                                              child: Image.file(
                                                                _image!,
                                                                fit: BoxFit
                                                                    .contain,
                                                              ),
                                                            ),
                                                            FutureBuilder<void>(
                                                              future: _image!
                                                                  .length(),
                                                              builder: (context,
                                                                  snapshot) {
                                                                if (snapshot
                                                                        .connectionState ==
                                                                    ConnectionState
                                                                        .done) {
                                                                  return const SizedBox();
                                                                }
                                                                return Center(
                                                                  child: LoadingAnimationWidget
                                                                      .staggeredDotsWave(
                                                                    color: const Color(
                                                                        0xff0288D1),
                                                                    size: 50,
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Stack(
                                                  children: [
                                                    Image.file(
                                                      _image!,
                                                      fit: BoxFit.cover,
                                                      width: double.infinity,
                                                      height: 250,
                                                    ),
                                                    FutureBuilder<void>(
                                                      future: _image!.length(),
                                                      builder:
                                                          (context, snapshot) {
                                                        if (snapshot
                                                                .connectionState ==
                                                            ConnectionState
                                                                .done) {
                                                          return const SizedBox();
                                                        }
                                                        return Center(
                                                          child: LoadingAnimationWidget
                                                              .staggeredDotsWave(
                                                            color: const Color(
                                                                0xff0288D1),
                                                            size: 50,
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
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
                          ],
                        ),
                      ],
                    ],
                    Center(
                      child: TextResponse(
                        label: error,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: SubmitButton(
                        label: "Submit",
                        onButtonPressed: () async {
                          setState(() {
                            isLoading =
                                LoadingAnimationWidget.staggeredDotsWave(
                                    color: const Color(0xff0288D1), size: 100);
                          });
                          var res = await submitData(
                              lat.toString(),
                              long.toString(),
                              interval,
                              dmaname,
                              metertype,
                              account,
                              firstreading,
                              secondreading,
                              meterstatus,
                              remarks,
                              firstdate,
                              seconddate,
                              myimage);

                          setState(() {
                            isLoading = null;
                            if (res.error == null) {
                              error = res.success;
                            } else {
                              error = res.error;
                            }
                          });
                          if (res.error == null) {
                            Timer(const Duration(seconds: 2), () {
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const NRW()));
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: isLoading ?? const SizedBox(),
          ),
        ],
      ),
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
