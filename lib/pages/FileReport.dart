import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:kiambu_umcollect/components/MyDrawer.dart';
import 'package:kiambu_umcollect/components/SubmitButton.dart';
import 'package:kiambu_umcollect/components/Utils.dart';
import 'package:kiambu_umcollect/pages/TextOakar.dart';
import 'package:kiambu_umcollect/pages/complete.dart';

class FileReport extends StatefulWidget {
  final String incidentid;
  const FileReport({super.key, required this.incidentid});

  @override
  State<FileReport> createState() => _FileReportState();
}

class _FileReportState extends State<FileReport> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  var isLoading;
  String userid = '';
  String staffid = '';
  String incidentId = '';
  String incident = '';
  String error = '';
  String serial = '';
  String type = '';
  String description = '';
  String latitude = '0';
  String longitude = '0';
  String taskremark = '';
  String status = '';
  String imageUrl = '';
  String repairedImage = '';
  bool successful = false;

  String capturedImageUrl = '';
  dynamic userData = [];
  late File? _image;
  final imagePicker = ImagePicker();

  final storage = const FlutterSecureStorage();

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  void initState() {
    super.initState();
    _image = null;
    loadFileReport(widget.incidentid);
  }

  Future<String> convertFileToBase64(XFile file) async {
    List<int> fileBytes = await file.readAsBytes();
    String base64String = base64Encode(fileBytes);
    return base64String;
  }

  Future<void> loadFileReport(String id) async {
    print("file report id: $id");

    setState(() {
      isLoading = LoadingAnimationWidget.horizontalRotatingDots(
        color: const Color(0xff0288D1),
        size: 100,
      );
    });

    try {
      final response = await get(
        Uri.parse("${getUrl()}reports/$id"),
      );

      var data = json.decode(response.body);
      print("file report data: $data");

      setState(() {
        userData = data;
        type = data["Type"];
        description = data["Description"];
        serial = data["SerialNo"].toString();
        latitude = data["Latitude"];
        longitude = data["Longitude"];
        status = data["Status"];
        imageUrl = data["Image"];
        incidentId = id;
        staffid = data["NRWUserID"];
        isLoading = null;
      });
    } catch (e) {
      print("Error loading file report: $e");

      setState(() {
        isLoading = null;
      });
    }
  }

  Future<void> takePhoto() async {
    final XFile? pickedFile = await imagePicker.pickImage(
      source: ImageSource.camera, // Open the camera to take a photo
    );

    if (pickedFile != null) {
      String base64Image = await convertFileToBase64(pickedFile);
      // Here you can save `base64Image` to your database

      setState(() {
        _image = File(pickedFile.path);
        repairedImage = base64Image;
      });
    } else {}
  }

  Future getImage() async {
    final pickedFile = await imagePicker.pickImage(
        source: ImageSource
            .gallery); // This will open the image picker for selecting from the gallery

    if (pickedFile != null) {
      String base64Image = await convertFileToBase64(pickedFile);
      setState(() {
        _image = File(pickedFile.path);
        repairedImage = base64Image;
      });
    } else {}
  }

  DateTime parsePostgresTimestamp(String timestamp) {
    return DateTime.parse(timestamp)
        .toLocal(); // Parse timestamp and convert to local time
  }

  @override
  Widget build(BuildContext context) {
    final String fullImageUrl = imageUrl.isNotEmpty
        ? "${getUrl()}uploads/${imageUrl.replaceAll("uploads/", "")}"
        : '';
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xff0288D1).withOpacity(0.95),
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          userData.isNotEmpty ? userData["Type"] : "Reported Incident",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      drawer: const MyDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xff0288D1).withOpacity(0.92),
              const Color(0xFFE3F2FD),
            ],
            stops: const [0.2, 0.9],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl.isNotEmpty) ...[
                  _buildSectionTitle('Captured Photo', topPadding: 16),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Container(
                      width: double.infinity,
                      height: 250,
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: GestureDetector(
                        onTap: () => _showFullImage(context, fullImageUrl),
                        child: Image.network(
                          fullImageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xff0288D1),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Text(
                                'Image not available',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
                _buildSectionTitle('Incident Details'),
                if (userData.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildDetailRow(Icons.category, 'Category', type),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1),
                            ),
                            _buildDetailRow(Icons.pin, 'Serial', serial),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1),
                            ),
                            _buildDetailRow(
                                Icons.comment, 'Description', description),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1),
                            ),
                            _buildDetailRow(
                              Icons.calendar_month,
                              'Date Reported',
                              "${DateFormat('EEEE, MMMM d, y').format(parsePostgresTimestamp(userData["createdAt"]))} ${DateFormat('HH:mm').format(parsePostgresTimestamp(userData["createdAt"]))}",
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (isLoading != null)
                  Center(child: isLoading)
                else
                  const SizedBox(),
                _buildSectionTitle('Take a Photo'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Container(
                    width: double.infinity,
                    height: 250,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
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
                                  color: Colors.black.withOpacity(0.2),
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
                ),
                _buildSectionTitle('Select Action Taken'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xff0288D1).withOpacity(0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: taskremark.isEmpty ? null : taskremark,
                        hint: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Select action...',
                            style: TextStyle(
                              color: Color(0xff0288D1),
                              fontSize: 16,
                            ),
                          ),
                        ),
                        isExpanded: true,
                        icon: const Padding(
                          padding: EdgeInsets.only(right: 16),
                          child: Icon(
                            Icons.arrow_drop_down_rounded,
                            color: Color(0xff0288D1),
                            size: 30,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Illegal connection disconnected',
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('Illegal connection disconnected'),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Leakage repaired',
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('Leakage repaired'),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Vandalised cover/line repaired',
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('Vandalised cover/line repaired'),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Flashing Unit',
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('Flashing Unit'),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Rodding',
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('Rodding'),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Other',
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('Other'),
                            ),
                          ),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            taskremark = newValue ?? '';
                          });
                        },
                      ),
                    ),
                  ),
                ),
                if (error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextOakar(label: error, issuccessful: successful),
                  ),
                if (isLoading != null)
                  Center(child: isLoading)
                else
                  const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          error = "";
                          isLoading = LoadingAnimationWidget.staggeredDotsWave(
                            color: const Color(0xff0288D1),
                            size: 100,
                          );
                        });

                        var res = await submitData(
                          incidentId,
                          repairedImage,
                          taskremark,
                        );

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
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CompleteIncidences(
                                staffid: staffid,
                              ),
                            ),
                          );
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {double topPadding = 0}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: const Color(0xff0288D1),
          size: 22,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xff0288D1),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.white,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xff0288D1),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.white,
                    child: const Center(
                      child: Text(
                        'Failed to load image',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<Message> submitData(
  String incidentId,
  String repairedImage,
  String taskremark,
) async {
  if (repairedImage.isEmpty || taskremark.isEmpty) {
    return Message(
        token: null, success: null, error: "All Fields Must Be Filled!");
  }

  DateTime now = DateTime.now();
  String resolvedDate = DateFormat('YYYY-MM-DD').format(now);
  String resolvedTime = DateFormat('hh:mm a').format(now);

  try {
    var response = await put(
      Uri.parse("${getUrl()}reports/update/$incidentId"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'TaskImage': repairedImage,
        'TaskRemark': taskremark,
        'ResolvedDate': resolvedDate,
        'ResolvedTime': resolvedTime,
        'Status': 'Resolved',
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
