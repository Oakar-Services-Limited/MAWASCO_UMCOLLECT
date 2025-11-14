// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names, file_names, prefer_typing_uninitialized_variables

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:um_collect/components/MySelectInput.dart';
import 'package:um_collect/components/MyTextInput.dart';
import 'package:um_collect/components/StaffDrawer.dart';
import 'package:um_collect/components/SubmitButton.dart';
import 'package:um_collect/components/TextResponse.dart';
import 'package:um_collect/components/Utils.dart';
import 'package:um_collect/models/Map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:um_collect/pages/NRW.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:http/http.dart' as http;

class Interventions extends StatefulWidget {
  const Interventions({
    super.key,
  });

  @override
  State<Interventions> createState() => _InterventionsState();
}

class _InterventionsState extends State<Interventions> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final storage = const FlutterSecureStorage();
  late Position position;

  var long = 36.0, lat = -2.0, acc = 100.0;
  String error = '';
  String? editing = 'false';
  String staffid = '';

  String dma = '';
  String scope = '';
  String account = '';
  String activity = '';
  String model = '';
  String reason = '';
  String highflow = '';
  String lowflow = '';
  String results = '';
  String sreport = '';
  String readings = '';
  String serial = '';
  String oldserial = '';
  String newserial = '';
  String oldreadings = '';
  String newmodel = '';
  String newreadings = '';
  String year = '';
  String user = '';
  String date = '';

  late File? _image;
  late File? _image2;
  final imagePicker = ImagePicker();
  String myimage = '';

  String newold_image = '';

  dynamic data;

  var isLoading;

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

  Future<void> takePhoto2() async {
    final pickedFile = await imagePicker.pickImage(
      source: ImageSource.camera, // Open the camera to take a photo
    );

    if (pickedFile != null) {
      String base64Image = await convertFileToBase64(pickedFile);
      setState(() {
        _image2 = File(pickedFile.path);
        newold_image = base64Image;
      });
    } else {}
  }

  @override
  void initState() {
    _image = null;
    _image2 = null;
    fetchStoredData();
    getLocation();
    _initializeDateVariables();
    super.initState();
  }

  Future<void> fetchStoredData() async {
    try {
      var token = await storage.read(key: "mwstaffjwt");
      var decoded = parseJwt(token.toString());

      setState(() {
        user = decoded["name"];
        staffid = decoded["id"];
      });
    } catch (e) {
      //
    }
  }

  void _initializeDateVariables() {
    DateTime today = DateTime.now();

    date =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    setState(() {
      date = date;
    });
  }

  getLocation() async {
    position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
    ));
    setState(() {
      long = position.longitude;
      lat = position.latitude;
      acc = position.accuracy;
    });
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
          'NRW Interventions',
          style: TextStyle(color: Colors.white, fontSize: 18),
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
                    const SizedBox(
                      height: 8,
                    ),
                    const Text(
                      "All fields marked with * are required",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                        child: SizedBox(
                            height: 250,
                            child: MyMap(
                              lat: lat,
                              lon: long,
                              acc: acc,
                            ))),
                    const SizedBox(
                      height: 10,
                    ),
                    MyTextInput(
                      lines: 1,
                      value: user,
                      type: TextInputType.text,
                      onSubmit: (value) {
                        setState(() {
                          user = value;
                        });
                      },
                      title: 'Staff Name',
                    ),
                    MySelectInput(
                      onSubmit: (value) => setState(() => dma = value),
                      list: getDMAs(),
                      label: 'DMA Name',
                      value: dma,
                    ),
                    MySelectInput(
                      onSubmit: (value) {
                        setState(() {
                          scope = value;
                        });
                      },
                      list: const [
                        "--Select--",
                        "Metering",
                      ],
                      label: 'Scope of Work',
                      value: scope,
                    ),
                    MyTextInput(
                      lines: 1,
                      value: account,
                      type: TextInputType.numberWithOptions(decimal: true),
                      onSubmit: (value) {
                        setState(() {
                          account = value;
                        });
                      },
                      title: 'Account No',
                    ),
                    MySelectInput(
                      onSubmit: (value) {
                        setState(() {
                          activity = value;
                        });
                      },
                      list: const [
                        "--Select--",
                        "Meter Testing",
                        "Meter Inspection",
                        "Meter Replacement",
                        "Meter Relocation",
                        "Meter Re-alignment",
                        "Meter Servicing",
                      ],
                      label: 'Meter Activity',
                      value: activity,
                    ),
                    MySelectInput(
                      onSubmit: (value) {
                        setState(() {
                          model = value;
                        });
                      },
                      list: const [
                        "--Select--",
                        "Diehl",
                        "Honeywell",
                        "Lianli",
                        "Elster Kent",
                        "Kent Others",
                        "JANZ",
                        "AWSB",
                        "KIAWASCO",
                        "Others",
                        "Meter Missing",
                      ],
                      label: 'Meter Model',
                      value: model,
                    ),
                    activity == "Meter Testing"
                        ? MySelectInput(
                            onSubmit: (value) {
                              setState(() {
                                reason = value;
                              });
                            },
                            list: const [
                              "--Select--",
                              "Age of the meter",
                              "Low consumption",
                              "Large Consumer",
                              "Irregular readings",
                            ],
                            label: 'Reason for testing',
                            value: reason,
                          )
                        : activity == "Meter Inspection"
                            ? MySelectInput(
                                onSubmit: (value) {
                                  setState(() {
                                    reason = value;
                                  });
                                },
                                list: const [
                                  "--Select--",
                                  "Low or Zero consumption",
                                  "Inactive Account",
                                ],
                                label: 'Reason for Inspection',
                                value: reason,
                              )
                            : activity == "Meter Replacement"
                                ? MySelectInput(
                                    onSubmit: (value) {
                                      setState(() {
                                        reason = value;
                                      });
                                    },
                                    list: const [
                                      "--Select--",
                                      "Misty Dial",
                                      "Failed Test",
                                      "Meter Age",
                                      "Physical Damage",
                                      "Stolen Meter",
                                    ],
                                    label: 'Reason for Replacement',
                                    value: reason,
                                  )
                                : activity == "Meter Relocation"
                                    ? MySelectInput(
                                        onSubmit: (value) {
                                          setState(() {
                                            reason = value;
                                          });
                                        },
                                        list: const [
                                          "--Select--",
                                          "Inside Compound",
                                          "Buried or Covered",
                                          "Concreted to Surface",
                                        ],
                                        label: 'Reason for Relocation',
                                        value: reason,
                                      )
                                    : activity == "Meter Re-alignment"
                                        ? MySelectInput(
                                            onSubmit: (value) {
                                              setState(() {
                                                reason = value;
                                              });
                                            },
                                            list: const [
                                              "--Select--",
                                              "Vertical",
                                              "Inclined",
                                              "10D/5D Rule",
                                            ],
                                            label: 'Reason for Re-alignment',
                                            value: reason,
                                          )
                                        : activity == "Meter Servicing"
                                            ? MySelectInput(
                                                onSubmit: (value) {
                                                  setState(() {
                                                    reason = value;
                                                  });
                                                },
                                                list: const [
                                                  "--Select--",
                                                  "Meter Stuck",
                                                  "Not clear",
                                                  "Routine Check",
                                                ],
                                                label: 'Reason for Servicing',
                                                value: reason,
                                              )
                                            : const SizedBox(
                                                height: 12,
                                              ),
                    activity == "Meter Servicing"
                        ? MySelectInput(
                            onSubmit: (value) {
                              setState(() {
                                sreport = value;
                              });
                            },
                            list: const [
                              "--Select--",
                              "Good condition",
                              "Not serviceable - Replace Meter",
                            ],
                            label: 'Service report',
                            value: sreport,
                          )
                        : const SizedBox(
                            height: 12,
                          ),
                    activity == "Meter Testing"
                        ? MyTextInput(
                            lines: 1,
                            value: highflow,
                            type:
                                TextInputType.numberWithOptions(decimal: true),
                            onSubmit: (value) {
                              setState(() {
                                highflow = value;
                              });
                            },
                            title: 'High flow results +/-2%',
                          )
                        : const SizedBox(
                            height: 0,
                          ),
                    activity == "Meter Testing"
                        ? MyTextInput(
                            lines: 1,
                            value: lowflow,
                            type:
                                TextInputType.numberWithOptions(decimal: true),
                            onSubmit: (value) {
                              setState(() {
                                lowflow = value;
                              });
                            },
                            title: 'Low flow results +/-5%',
                          )
                        : const SizedBox(
                            height: 0,
                          ),
                    activity == "Meter Testing"
                        ? MySelectInput(
                            onSubmit: (value) {
                              setState(() {
                                results = value;
                              });
                            },
                            list: const [
                              "--Select--",
                              "Pass",
                              "Fail",
                            ],
                            label: 'Test Results',
                            value: results,
                          )
                        : const SizedBox(
                            height: 0,
                          ),
                    activity == "Meter Replacement"
                        ? MyTextInput(
                            lines: 1,
                            value: oldserial,
                            type: TextInputType.text,
                            onSubmit: (value) {
                              setState(() {
                                oldserial = value;
                              });
                            },
                            title: 'Old Meter Serial No',
                          )
                        : const SizedBox(
                            height: 0,
                          ),
                    activity == "Meter Replacement"
                        ? MyTextInput(
                            lines: 1,
                            value: oldreadings,
                            type:
                                TextInputType.numberWithOptions(decimal: true),
                            onSubmit: (value) {
                              setState(() {
                                oldreadings = value;
                              });
                            },
                            title: 'Old Meter Last readings',
                          )
                        : const SizedBox(
                            height: 0,
                          ),
                    activity == "Meter Replacement"
                        ? MySelectInput(
                            onSubmit: (value) {
                              setState(() {
                                newmodel = value;
                              });
                            },
                            list: const [
                              "--Select--",
                              "Diehl",
                              "Honeywell",
                              "Lianli",
                              "Elster Kent",
                              "Kent Others",
                              "JANZ",
                              "AWSB",
                              "KIAWASCO",
                              "Others",
                              "Meter Missing",
                            ],
                            label: 'New Meter Model',
                            value: newmodel,
                          )
                        : const SizedBox(
                            height: 0,
                          ),
                    activity == "Meter Replacement"
                        ? MyTextInput(
                            lines: 1,
                            value: newserial,
                            type: TextInputType.text,
                            onSubmit: (value) {
                              setState(() {
                                newserial = value;
                              });
                            },
                            title: 'New Meter Serial No',
                          )
                        : const SizedBox(
                            height: 0,
                          ),
                    activity == "Meter Replacement"
                        ? MyTextInput(
                            lines: 1,
                            value: newreadings,
                            type:
                                TextInputType.numberWithOptions(decimal: true),
                            onSubmit: (value) {
                              setState(() {
                                newreadings = value;
                              });
                            },
                            title: 'New Meter First Reading',
                          )
                        : const SizedBox(
                            height: 0,
                          ),
                    results == "Fail"
                        ? MyTextInput(
                            lines: 1,
                            value: serial,
                            type: TextInputType.text,
                            onSubmit: (value) {
                              setState(() {
                                serial = value;
                              });
                            },
                            title: 'Meter Serial No',
                          )
                        : const SizedBox(
                            height: 0,
                          ),
                    MyTextInput(
                      lines: 1,
                      value: readings,
                      type: TextInputType.numberWithOptions(decimal: true),
                      onSubmit: (value) {
                        setState(() {
                          readings = value;
                        });
                      },
                      title: 'Meter Readings',
                    ),
                    activity == "Meter Replacement" ||
                            activity == "Meter Relocation" ||
                            activity == "Meter Re-alignment"
                        ? Column(
                            children: [
                              activity == "Meter Replacement"
                                  ? const Text(
                                      'Photos of Old and New Meter',
                                      style: TextStyle(
                                        color: Color(0xff0288D1),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    )
                                  : activity == "Meter Relocation"
                                      ? const Text(
                                          'Photo after Relocation',
                                          style: TextStyle(
                                            color: Color(0xff0288D1),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        )
                                      : const Text(
                                          'Photo after Re-alignment',
                                          style: TextStyle(
                                            color: Color(0xff0288D1),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                              const SizedBox(
                                height: 12,
                              ),
                              Card(
                                elevation: 2,
                                clipBehavior: Clip.hardEdge,
                                child: Stack(
                                  children: [
                                    SizedBox(
                                      height: 150,
                                      width: double.infinity,
                                      child: _image2 == null
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
                                          : GestureDetector(
                                              onTap: () {
                                                showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return Dialog(
                                                      child: Container(
                                                        color: Colors.black,
                                                        child:
                                                            InteractiveViewer(
                                                          child: Image.file(
                                                              _image2!),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                              child: Image.file(
                                                _image2!,
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
                                        onPressed: () => takePhoto2(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : const SizedBox(
                            height: 0,
                          ),
                    const SizedBox(
                      height: 10,
                    ),
                    Column(
                      children: [
                        const Text(
                          'Activity Photo',
                          style: TextStyle(
                            color: Color(0xff0288D1),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Card(
                          elevation: 2,
                          clipBehavior: Clip.hardEdge,
                          child: Stack(
                            children: [
                              SizedBox(
                                height: 150,
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
                      ],
                    ),
                    Center(
                      child: TextResponse(
                        label: error,
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
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
                              dma,
                              scope,
                              account,
                              activity,
                              model,
                              reason,
                              highflow,
                              lowflow,
                              results,
                              sreport,
                              readings,
                              serial,
                              oldserial,
                              newserial,
                              oldreadings,
                              newmodel,
                              newreadings,
                              myimage,
                              newold_image,
                              date,
                              user);

                          if (!mounted) return;
                          setState(() {
                            isLoading = null;
                            if (res.error == null) {
                              error = res.success;
                            } else {
                              error = res.error ?? "An unknown error occurred";
                            }
                          });
                          if (res.error == null) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).clearSnackBars();
                              final snackBar = SnackBar(
                                content: Text(
                                    res.success ?? "Submission Successful"),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 2),
                              );
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(snackBar);
                            }
                            Future.delayed(const Duration(seconds: 2), () {
                              if (mounted) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const NRW()),
                                );
                              }
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
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

Future<Message> submitData(
  String lat,
  String long,
  String dma,
  String scope,
  String account,
  String activity,
  String model,
  String reason,
  String highflow,
  String lowflow,
  String results,
  String sreport,
  String readings,
  String serial,
  String oldserial,
  String newserial,
  String oldreadings,
  String newmodel,
  String newreadings,
  String myimage,
  String newold_image,
  String date,
  String user,
) async {
  try {
    final storage = const FlutterSecureStorage();
    final token = await storage.read(key: "mwstaffjwt");

    if (token == null) {
      return Message(
        token: null,
        success: null,
        error: "Authentication token not found. Please login again.",
      );
    }

    final requestBody = {
      'latitude': lat,
      'longitude': long,
      'DMAName': dma,
      'scope': scope,
      'accountNo': account,
      "meterActivity": activity,
      "meterModel": model,
      'reason': reason,
      "highFlowResult": highflow,
      'lowFlowResult': lowflow,
      "testResult": results,
      'serviceReport': sreport,
      'meterReadings': readings,
      'meterSerial': serial,
      'oldMeterSerial': oldserial,
      'newMeterSerial': newserial,
      'oldMeterReading': oldreadings,
      'newMeterModel': newmodel,
      'newMeterReading': newreadings,
      "activityPhoto": myimage,
      "afterPhoto": newold_image,
      'date': date,
    };

    final response = await http.post(
      Uri.parse("${getUrl()}nrw_interventions/"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(requestBody),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseBody = jsonDecode(response.body);
      return Message(
        token: responseBody['token'],
        success: responseBody['success'],
        error: responseBody['error'],
      );
    } else {
      final errorBody = jsonDecode(response.body);
      return Message(
        token: null,
        success: null,
        error: errorBody['error'] ?? "Server error! Contact administrator.",
      );
    }
  } catch (e) {
    return Message(
      token: null,
      success: null,
      error: "Connection failed! Check your internet connection and try again.",
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
