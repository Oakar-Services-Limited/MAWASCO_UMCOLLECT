// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names, file_names, prefer_typing_uninitialized_variables

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:http/http.dart' as http;
import 'package:um_collect/components/MySearchableSelectInput.dart';
import 'package:um_collect/components/MySelectInput.dart';
import 'package:um_collect/components/MyTextInput.dart';
import 'package:um_collect/components/StaffDrawer.dart';
import 'package:um_collect/components/offline_pending_card.dart';
import 'package:um_collect/components/Utils.dart';
import 'package:um_collect/pages/home.dart';
import 'package:um_collect/services/connectivity_helper.dart';
import 'package:um_collect/services/database_helper.dart';
import 'package:um_collect/services/sync_service.dart';

class MasterMeterReadings extends StatefulWidget {
  const MasterMeterReadings({
    super.key,
  });

  @override
  State<MasterMeterReadings> createState() => _MasterMeterReadingsState();
}

class _MasterMeterReadingsState extends State<MasterMeterReadings> {
  static const List<String> _remarksOptions = [
    '--Select--',
    'Good/Functional',
    'Buried/Covered (inaccessible)',
    'Chamber Flooded',
    'Foggy/Illegible(estimate)',
    'Meter Stuck',
    'Meter Faulty/Damaged',
  ];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final storage = const FlutterSecureStorage();

  String error = '';
  String staffid = '';
  String metername = '';
  String meterreading = '';
  String remarks = '';
  String myimage = '';
  Widget? isLoading;

  /// Last saved reading for the selected master meter (from API). Consumption = current − previous.
  double? _previousReading;
  bool _loadingLastReading = false;

  late File? _image;
  final imagePicker = ImagePicker();

  List<String> masterMeterNames = ["--Select--"];
  bool isLoadingMeters = false;
  bool _isSyncing = false;
  bool _isOnline = true;
  int _offlineCardEpoch = 0;
  final _syncService = SyncService();
  StreamSubscription<bool>? _connectivitySub;

  bool get _hasPhoto => myimage.isNotEmpty;

  Future<void> _fetchLastReadingForMeter(String name) async {
    if (name.isEmpty || name == '--Select--') {
      setState(() {
        _previousReading = null;
        _loadingLastReading = false;
      });
      return;
    }
    setState(() {
      _loadingLastReading = true;
      _previousReading = null;
    });
    try {
      final uri = Uri.parse('${getUrl()}master-meter-reading/last').replace(
        queryParameters: {'meterName': name},
      );
      final response = await http.get(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      if (!mounted) return;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        setState(() => _loadingLastReading = false);
        return;
      }
      final decoded = jsonDecode(response.body);
      final data = decoded is Map ? decoded['data'] : null;
      final raw = data is Map ? data['previousReading'] : null;
      double? prev;
      if (raw is num) {
        prev = raw.toDouble();
      } else if (raw != null) {
        prev = double.tryParse(raw.toString().replaceAll(',', ''));
      }
      setState(() {
        _previousReading = prev;
        _loadingLastReading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingLastReading = false;
          _previousReading = null;
        });
      }
    }
  }

  String? _formatConsumptionPreview() {
    if (_previousReading == null) return null;
    final s = meterreading.trim();
    if (s.isEmpty) return null;
    final current = double.tryParse(s.replaceAll(',', ''));
    if (current == null) return null;
    final diff = current - _previousReading!;
    return _formatM3Number(diff);
  }

  /// One consistent format for m³ display (whole numbers without decimals when exact).
  static String _formatM3Number(double v) {
    if (v == v.roundToDouble()) {
      return v.toStringAsFixed(0);
    }
    return v.toStringAsFixed(2);
  }

  String _previousReadingLabel() {
    final p = _previousReading;
    if (p == null) {
      return 'Previous reading: — (first read for this meter)';
    }
    return 'Previous reading: ${_formatM3Number(p)} m³';
  }

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
    final fileBytes = await file.readAsBytes();
    return base64Encode(fileBytes);
  }

  Future<void> takePhoto() async {
    final pickedFile = await imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      final base64Image = await convertFileToBase64(pickedFile);
      setState(() {
        _image = File(pickedFile.path);
        myimage = base64Image;
        if (remarks.isEmpty || remarks == '--Select--') {
          remarks = '--Select--';
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _image = null;
    remarks = '--Select--';
    fetchStoredData();
    _loadMasterMeters();
    _listenConnectivity();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  void _listenConnectivity() {
    ConnectivityHelper().checkConnectivity().then((online) {
      if (!mounted) return;
      setState(() => _isOnline = online);
    });
    _connectivitySub =
        ConnectivityHelper().connectivityStream.listen((online) {
      if (!mounted) return;
      setState(() {
        _isOnline = online;
        if (online) _offlineCardEpoch++;
      });
    });
  }

  Future<void> _syncPendingReadings() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    final message = await _syncService.syncAllUnsynced();
    if (!mounted) return;
    setState(() {
      _isSyncing = false;
      _offlineCardEpoch++;
    });
    _showMessage(message, false);
  }

  Future<void> _loadMasterMeters() async {
    final cached = getMasterMeterNamesCached();
    if (cached != null && cached.isNotEmpty) {
      setState(() {
        masterMeterNames = ["--Select--", ...cached];
        isLoadingMeters = false;
      });
      refreshMasterMeterNamesCache().then((freshNames) {
        if (!mounted) return;
        setState(() {
          masterMeterNames = ["--Select--", ...freshNames];
        });
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
      final token = await storage.read(key: "mwstaffjwt");
      final decoded = parseJwt(token.toString());

      setState(() {
        staffid = (decoded["UserID"] ?? decoded["id"] ?? '').toString();
      });
    } catch (_) {}
  }

  String? _validateForm() {
    if (metername.isEmpty || metername == '--Select--') {
      return 'Select a meter name.';
    }
    if (meterreading.trim().isEmpty) {
      return 'Enter the meter reading.';
    }
    if (!_hasPhoto) {
      return 'Take a meter photo.';
    }
    if (remarks.isEmpty || remarks == '--Select--') {
      return 'Select remarks after taking the photo.';
    }
    return null;
  }

  Future<void> _submit({required bool asDraft}) async {
    final validationError = _validateForm();
    if (validationError != null) {
      _showMessage(validationError, true);
      return;
    }

    setState(() {
      isLoading = LoadingAnimationWidget.staggeredDotsWave(
        color: const Color(0xff0288D1),
        size: 100,
      );
    });

    final res = await submitData(
      metername: metername,
      meterreading: meterreading.trim(),
      myimage: myimage,
      remarks: remarks == '--Select--' ? '' : remarks,
      forceOffline: asDraft,
    );

    if (!mounted) return;
    setState(() {
      isLoading = null;
    });

    if (res.error == null) {
      setState(() => _offlineCardEpoch++);
      _showMessage(
        res.success ?? "Reading submitted successfully",
        false,
      );
      if (!asDraft) {
        Timer(const Duration(seconds: 2), () {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Home()),
          );
        });
      } else {
        setState(() {
          metername = '';
          meterreading = '';
          remarks = '--Select--';
          myimage = '';
          _image = null;
          _previousReading = null;
        });
      }
    } else {
      _showMessage(res.error ?? "Failed to submit reading", true);
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
        actions: [
          IconButton(
            icon: _isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.cloud_sync, color: Colors.white),
            tooltip: _isSyncing ? 'Syncing…' : 'Sync pending readings',
            onPressed: _isSyncing ? null : _syncPendingReadings,
          ),
        ],
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
                        const SizedBox(height: 12),
                        if (!_isOnline)
                          Card(
                            color: const Color(0xFFFFF3E0),
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Icon(Icons.cloud_off,
                                      color: Color(0xff0288D1)),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'You are offline. Submit or Save draft stores readings locally; sync when connected.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        OfflinePendingCard(
                          key: ValueKey(_offlineCardEpoch),
                          types: const ['master_meter_reading'],
                          label: 'Master meter readings',
                        ),
                        const SizedBox(height: 8),
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
                                  _fetchLastReadingForMeter(value);
                                },
                                list: masterMeterNames,
                                label: 'Select Meter Name',
                                value: metername,
                              ),
                        const SizedBox(height: 20),
                        if (metername.isNotEmpty &&
                            metername != '--Select--') ...[
                          if (_loadingLastReading)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xff0288D1),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Loading previous reading…',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _previousReadingLabel(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                        ],
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
                          title: 'Reading (m³)',
                        ),
                        if (metername.isNotEmpty &&
                            metername != '--Select--' &&
                            _previousReading != null &&
                            meterreading.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Consumption (m³) for this read: ${_formatConsumptionPreview() ?? "—"}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xff2E7D32),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
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
                                  color: const Color(0xff0288D1)
                                      .withValues(alpha: 0.1),
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
                                            color: Colors.black
                                                .withValues(alpha: 0.2),
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
                        if (_hasPhoto) ...[
                          const SizedBox(height: 20),
                          MySelectInput(
                            onSubmit: (value) {
                              setState(() {
                                remarks = value;
                              });
                            },
                            list: _remarksOptions,
                            label: 'Remarks *',
                            value: remarks.isEmpty ? '--Select--' : remarks,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Select the meter condition observed when taking the photo.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black.withValues(alpha: 0.65),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => _submit(asDraft: false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff0288D1),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              _isOnline
                                  ? 'Submit'
                                  : 'Submit (save offline)',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: () => _submit(asDraft: true),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xff0288D1),
                              side: const BorderSide(color: Color(0xff0288D1)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.save_outlined, size: 20),
                            label: const Text(
                              'Save draft (sync later)',
                              style: TextStyle(fontWeight: FontWeight.w600),
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
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: isLoading,
              ),
            ),
        ],
      ),
    );
  }
}

Future<Message> submitData({
  required String metername,
  required String meterreading,
  required String myimage,
  required String remarks,
  bool forceOffline = false,
}) async {
  if (metername.isEmpty || metername == '--Select--') {
    return Message(
      token: null,
      success: null,
      error: "Select a master meter",
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

  if (remarks.isEmpty) {
    return Message(
      token: null,
      success: null,
      error: "Select remarks after taking the photo.",
    );
  }

  final db = DatabaseHelper();
  final isOnline =
      !forceOffline && await ConnectivityHelper().checkConnectivity();

  Future<Message> queueOffline(String reason) async {
    final payload = <String, dynamic>{
      'meterName': metername,
      'reading': meterreading,
      if (myimage.isNotEmpty) 'image': myimage,
      if (remarks.isNotEmpty) 'remarks': remarks,
    };

    await db.saveSubmission(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      formId: 'master_meter_reading',
      formName: 'Master Meter Reading',
      responses: {
        '_type': 'master_meter_reading',
        '_endpoint': 'master-meter-reading/create',
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

  if (!isOnline || forceOffline) {
    return queueOffline(forceOffline ? 'Draft saved' : 'Offline');
  }

  try {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'mwstaffjwt');
    final response = await http.post(
      Uri.parse("${getUrl()}master-meter-reading/create"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{
        'meterName': metername,
        'reading': meterreading,
        'image': myimage,
        'remarks': remarks,
      }),
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 203) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        if (decoded['error'] != null) {
          return Message(
            token: null,
            success: null,
            error: decoded['error'].toString(),
          );
        }
        if (decoded['success'] != null) {
          return Message(
            token: decoded['data'] is Map ? (decoded['data'] as Map)['id'] : null,
            success: decoded['success']?.toString(),
            error: null,
          );
        }
      }
      return Message.fromJson(decoded as Map<String, dynamic>);
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['error'] != null) {
        return Message(
          token: null,
          success: null,
          error: decoded['error'].toString(),
        );
      }
    } catch (_) {}

    return Message(
      token: null,
      success: null,
      error:
          "Server error (${response.statusCode}). Try again or contact support.",
    );
  } catch (_) {
    return queueOffline('Network error');
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
