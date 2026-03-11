// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names, file_names, prefer_typing_uninitialized_variables

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:um_collect/components/MySelectInput.dart';
import 'package:um_collect/components/MyTextInput.dart';
import 'package:um_collect/components/offline_pending_card.dart';
import 'package:um_collect/components/StaffDrawer.dart';
import 'package:um_collect/components/SubmitButton.dart';
import 'package:um_collect/components/TextResponse.dart';
import 'package:um_collect/components/Utils.dart';
import 'package:um_collect/models/Map.dart';
import 'package:um_collect/pages/Assets.dart';
import 'package:um_collect/services/connectivity_helper.dart';
import 'package:um_collect/services/database_helper.dart';
import 'package:geolocator/geolocator.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:http/http.dart' as http;

/// Form to register a dormant (billing) account as a new customer meter.
/// Prefilled from bl_customer_billings data; submit creates a new wt_customer_meters record.
class DormantMeterForm extends StatefulWidget {
  final Map<String, dynamic> dormantData;

  const DormantMeterForm({super.key, required this.dormantData});

  @override
  State<DormantMeterForm> createState() => _DormantMeterFormState();
}

class _DormantMeterFormState extends State<DormantMeterForm> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final storage = const FlutterSecureStorage();

  var long = 36.0, lat = -0.5, acc = 100.0;
  String error = '';
  String accountNumberError = '';
  String staffid = '';
  String accnum = '';
  String meterserial = '';
  String metertype = '';
  String meterclass = '';
  String size = '';
  String brandname = '';
  String material = '';
  String meterlocation = '';
  String status = '';
  String remarks = '';
  String name = '';
  String phone = '';
  String accstatus = '';
  String acctype = '';
  String instituteMeterType = '';
  String schemename = '';
  String zone = '';
  String route = '';
  String dma = '';
  String location = '';
  String parcelno = '';
  String userid = '';

  var isLoading;
  late File? _image;
  final ImagePicker imagePicker = ImagePicker();
  String myimage = '';

  @override
  void initState() {
    super.initState();
    _image = null;
    getLocation();
    _fetchUserAndPrefill();
  }

  Future<String> convertFileToBase64(XFile file) async {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  Future<void> takePhoto() async {
    final pickedFile = await imagePicker.pickImage(
      source: ImageSource.camera,
    );

    if (pickedFile != null) {
      final base64Image = await convertFileToBase64(pickedFile);
      setState(() {
        _image = File(pickedFile.path);
        myimage = base64Image;
      });
    }
  }

  Future<void> getLocation() async {
    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );
    Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      if (mounted) {
        setState(() {
          long = position.longitude;
          lat = position.latitude;
          acc = position.accuracy;
        });
      }
    });
  }

  Future<void> _fetchUserAndPrefill() async {
    try {
      final token = await storage.read(key: "mwstaffjwt");
      if (token != null && token.isNotEmpty) {
        final decoded = parseJwt(token);
        setState(() {
          userid = decoded["id"]?.toString() ?? '';
        });
      }
      if (widget.dormantData.isNotEmpty) {
        _prefillFromDormant(widget.dormantData);
      }
    } catch (_) {}
  }

  void _prefillFromDormant(Map<String, dynamic> data) {
    setState(() {
      accnum = data["accountNo"]?.toString() ?? "";
      meterserial = data["meterNo"]?.toString() ?? "";
      status = data["meterStatus"]?.toString() ?? "";
      size = data["meterSize"]?.toString() ?? "";
      brandname = data["brand"]?.toString() ?? "";
      material = data["material"]?.toString() ?? "";
      meterlocation = data["location"]?.toString() ?? "";
      remarks = data["remarks"]?.toString() ?? "";
      name = data["name"]?.toString() ?? "";
      phone = data["phone"]?.toString() ?? "";
      accstatus = data["accountStatus"]?.toString() ?? "";
      acctype = data["accountType"]?.toString() ?? "";
      instituteMeterType = data["institution"]?.toString() ?? "";
      schemename = data["schemeName"]?.toString() ?? "";
      zone = data["zone"]?.toString() ?? "";
      route = data["route"]?.toString() ?? "";
      dma = data["dma"]?.toString() ?? "";
      location = data["location"]?.toString() ?? "";
      parcelno = data["parcelNo"]?.toString() ?? "";
      meterclass = data["meterClass"]?.toString() ?? "";
      lat = double.tryParse(data["latitude"]?.toString() ?? "") ?? lat;
      long = double.tryParse(data["longitude"]?.toString() ?? "") ?? long;
    });
  }

  Future<Message> _submitAsNewCustomerMeter() async {
    if (accnum.isEmpty) {
      return Message(token: null, success: null, error: "Account number must be filled!");
    }
    if (accnum.length != 5 || !RegExp(r'^[0-9]{5}$').hasMatch(accnum)) {
      return Message(token: null, success: null, error: "Account number must be exactly 5 digits");
    }
    if (zone == "--Select--" || zone.isEmpty) {
      return Message(token: null, success: null, error: "Select Zone!");
    }
    if (dma == "--Select--" || dma.isEmpty) {
      return Message(token: null, success: null, error: "Select DMA!");
    }
    if (name.isEmpty) {
      return Message(token: null, success: null, error: "Name must be filled!");
    }

    final db = DatabaseHelper();
    final isOnline = await ConnectivityHelper().checkConnectivity();

    Future<Message> queueOffline(Map<String, dynamic> payload, String reason) async {
      await db.saveSubmission(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        formId: 'asset_dormant_meter_register',
        formName: 'Dormant meter registration',
        responses: {
          '_type': 'asset_dormant_meter_register',
          '_endpoint': 'wt/dormant-customer-meters',
          '_method': 'POST',
          '_body': payload,
        },
      );
      return Message(
        token: null,
        success: "Saved offline. Will sync when you have internet. ($reason)",
        error: null,
      );
    }

    try {
      final token = await storage.read(key: "mwstaffjwt");
      final payload = <String, dynamic>{
        'name': name,
        'phone': phone,
        'accountNo': accnum,
        'meterNo': meterserial,
        'accountStatus': accstatus.isEmpty ? 'ACTIVE' : accstatus,
        'accountType': acctype,
        'institution': instituteMeterType,
        'meterStatus': status,
        'brand': brandname,
        'material': material,
        'meterClass': meterclass,
        'schemeName': schemename,
        'zone': zone,
        'route': route,
        'dma': dma,
        'location': location,
        'parcelNo': parcelno,
        'meterSize': size,
        'remarks': remarks,
        'userId': userid,
        'latitude': lat.toString(),
        'longitude': long.toString(),
      };
      if (myimage.isNotEmpty) {
        payload['image'] = myimage;
      }

      if (!isOnline) {
        return await queueOffline(payload, 'Offline');
      }

      final response = await http.post(
        Uri.parse("${getUrl()}wt/dormant-customer-meters"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] != null) {
          return Message(token: null, success: "Dormant meter registered successfully.", error: null);
        }
        return Message(
          token: null,
          success: null,
          error: responseData['error']?.toString() ?? "Invalid response format",
        );
      }
      final responseBody = jsonDecode(response.body);
      return Message(
        token: null,
        success: null,
        error: responseBody['error']?.toString() ?? "Server error. Please try again.",
      );
    } catch (e) {
      // Network error: queue for later
      try {
        final payload = <String, dynamic>{
          'name': name,
          'phone': phone,
          'accountNo': accnum,
          'meterNo': meterserial,
          'accountStatus': accstatus.isEmpty ? 'ACTIVE' : accstatus,
          'accountType': acctype,
          'institution': instituteMeterType,
          'meterStatus': status,
          'brand': brandname,
          'material': material,
          'meterClass': meterclass,
          'schemeName': schemename,
          'zone': zone,
          'route': route,
          'dma': dma,
          'location': location,
          'parcelNo': parcelno,
          'meterSize': size,
          'remarks': remarks,
          'userId': userid,
          'latitude': lat.toString(),
          'longitude': long.toString(),
          if (myimage.isNotEmpty) 'image': myimage,
        };
        return await queueOffline(payload, 'Network error');
      } catch (_) {
        return Message(
          token: null,
          success: null,
          error: "Connection failed. Error: $e",
        );
      }
    }
  }

  void _showSnackBar(String message, bool isSuccess) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => Assets(staffid: staffid)),
            );
          },
        ),
        title: const Text('Register Dormant Meter', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xff0288D1),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: StaffDrawer(staffid: staffid),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(color: Colors.white),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Prefilled from dormant account. Review, complete required fields, then submit to add as customer meter.",
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  const OfflinePendingCard(
                    types: ['asset_dormant_meter_register'],
                    label: 'Dormant meter registrations',
                  ),
                  SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: MyMap(lat: lat, lon: long, acc: acc),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      const Text(
                        'Take a Photo',
                        style: TextStyle(
                          color: Color(0xff0288D1),
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
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
                                          color:
                                              Color.fromARGB(255, 28, 100, 140),
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
                  const SizedBox(height: 12),
                  MyTextInput(
                    lines: 1,
                    value: name,
                    type: TextInputType.text,
                    onSubmit: (value) => setState(() => name = value),
                    title: 'Name *',
                  ),
                  MyTextInput(
                    lines: 1,
                    value: phone,
                    type: TextInputType.phone,
                    onSubmit: (value) => setState(() => phone = value),
                    title: 'Phone',
                  ),
                  MyTextInput(
                    lines: 1,
                    value: accnum,
                    type: TextInputType.number,
                    maxLength: 5,
                    onSubmit: (value) {
                      setState(() {
                        accnum = value;
                        if (value.isEmpty) {
                          accountNumberError = '';
                        } else if (value.length < 5) {
                          accountNumberError = 'Enter ${5 - value.length} more digit(s)';
                        } else {
                          accountNumberError = '';
                        }
                      });
                    },
                    title: 'Account Number *',
                  ),
                  if (accountNumberError.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 4),
                      child: Text(accountNumberError, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  MyTextInput(
                    lines: 1,
                    value: meterserial,
                    type: TextInputType.text,
                    onSubmit: (value) => setState(() => meterserial = value),
                    title: 'Meter Number',
                  ),
                  MySelectInput(
                    onSubmit: (value) => setState(() => size = value),
                    list: const ["--Select--", "0.5", "0.75", "1", "1.25", "1.5", "2", "3"],
                    label: 'Meter Size',
                    value: size,
                  ),
                  MySelectInput(
                    onSubmit: (value) => setState(() => status = value),
                    list: const ["--Select--", "Metered", "Unmetered"],
                    label: 'Meter Status',
                    value: status,
                  ),
                  MySelectInput(
                    onSubmit: (value) => setState(() => accstatus = value),
                    list: const ["--Select--", "ACTIVE", "INACTIVE", "DISCONNECTED", "SEALED", "DORMANT", "CLOSED"],
                    label: 'Account Status',
                    value: accstatus,
                  ),
                  MySelectInput(
                    onSubmit: (value) => setState(() => acctype = value),
                    list: const ["--Select--", "Domestic", "Commercial"],
                    label: 'Account Type',
                    value: acctype,
                  ),
                  MySelectInput(
                    onSubmit: (value) => setState(() => instituteMeterType = value),
                    list: const ["--Select--", "Large", "Medium", "Small"],
                    label: 'Institution meter type (if applicable)',
                    value: instituteMeterType,
                  ),
                  MySelectInput(
                    onSubmit: (value) => setState(() => brandname = value),
                    list: const ["--Select--", "YUONSO", "Honey Well", "Diehl", "Lianli", "Elstar Kent", "Wesan-Wottman", "Janz", "Other"],
                    label: 'Meter Brand',
                    value: brandname,
                  ),
                  MySelectInput(
                    onSubmit: (value) => setState(() => material = value),
                    list: const ["--Select--", "Polymer", "Brass", "Plastic"],
                    label: 'Meter Material',
                    value: material,
                  ),
                  MySelectInput(
                    onSubmit: (value) => setState(() => meterclass = value),
                    list: const ["--Select--", "A", "B", "C", "R160", "R200", "R250"],
                    label: 'Meter Class',
                    value: meterclass,
                  ),
                  MySelectInput(
                    onSubmit: (value) => setState(() => schemename = value),
                    list: const ["--Select--", "Rural", "Urban"],
                    label: 'Scheme Name',
                    value: schemename,
                  ),
                  MySelectInput(
                    onSubmit: (value) => setState(() => zone = value),
                    list: getZones(),
                    label: 'Zone *',
                    value: zone,
                  ),
                  MyTextInput(
                    lines: 1,
                    value: route,
                    type: TextInputType.text,
                    onSubmit: (value) => setState(() => route = value),
                    title: 'Route',
                  ),
                  MySelectInput(
                    onSubmit: (value) => setState(() => dma = value),
                    list: getDMAs(),
                    label: 'DMA *',
                    value: dma,
                  ),
                  MyTextInput(
                    lines: 1,
                    value: location,
                    type: TextInputType.text,
                    onSubmit: (value) => setState(() => location = value),
                    title: 'Location',
                  ),
                  MyTextInput(
                    lines: 1,
                    value: parcelno,
                    type: TextInputType.text,
                    onSubmit: (value) => setState(() => parcelno = value),
                    title: 'Parcel Number',
                  ),
                  MyTextInput(
                    lines: 1,
                    value: remarks,
                    type: TextInputType.text,
                    onSubmit: (value) => setState(() => remarks = value),
                    title: 'Remarks',
                  ),
                  Center(child: TextResponse(label: error)),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: SubmitButton(
                      label: "Register Dormant Meter",
                      onButtonPressed: () async {
                        setState(() {
                          isLoading = LoadingAnimationWidget.staggeredDotsWave(
                            color: const Color(0xff0288D1),
                            size: 100,
                          );
                        });
                        final res = await _submitAsNewCustomerMeter();
                        if (!mounted) return;
                        setState(() {
                          isLoading = null;
                          if (res.success != null) {
                            error = "";
                            accountNumberError = "";
                            _showSnackBar(res.success!, true);
                          } else {
                            error = res.error ?? "Unknown error";
                            _showSnackBar(error, false);
                          }
                        });
                        if (res.success != null) {
                          Future.delayed(const Duration(seconds: 2), () {
                            if (mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => Assets(staffid: staffid)),
                              );
                            }
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Center(child: isLoading ?? const SizedBox()),
        ],
      ),
    );
  }
}

class Message {
  final dynamic token;
  final dynamic success;
  final dynamic error;

  Message({required this.token, required this.success, required this.error});
}
