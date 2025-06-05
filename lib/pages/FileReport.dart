import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:um_collect/components/MyDrawer.dart';
import 'package:um_collect/components/Utils.dart';
import 'package:um_collect/pages/TextOakar.dart';
import 'package:um_collect/pages/complete.dart';

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
    print("FileReport initState - widget.incidentid: ${widget.incidentid}");
    if (widget.incidentid.isEmpty) {
      print("WARNING: Empty incident ID received in widget");
    }
    loadFileReport(widget.incidentid);
  }

  Future<String> convertFileToBase64(XFile file) async {
    List<int> fileBytes = await file.readAsBytes();
    String base64String = base64Encode(fileBytes);
    return base64String;
  }

  Future<void> loadFileReport(String id) async {
    print("loadFileReport called with ID: $id");
    print("ID length: ${id.length}");
    print("ID is empty: ${id.isEmpty}");

    if (id.isEmpty) {
      print("ERROR: Empty ID passed to loadFileReport");
      setState(() {
        error = "Invalid Incident ID";
        isLoading = null;
      });
      return;
    }

    setState(() {
      isLoading = LoadingAnimationWidget.horizontalRotatingDots(
        color: const Color(0xff0288D1),
        size: 100,
      );
    });

    try {
      // Get the assigned report first
      final assignedUrl = "${getUrl()}om/assigned-reports/$id";
      print("Fetching assigned report from URL: $assignedUrl");

      final assignedResponse = await get(
        Uri.parse(assignedUrl),
      );

      print("Assigned report response status: ${assignedResponse.statusCode}");
      print("Assigned report response body: ${assignedResponse.body}");

      if (assignedResponse.statusCode != 200) {
        throw Exception('Failed to load assigned report: ${assignedResponse.statusCode}');
      }

      var assignedData = json.decode(assignedResponse.body);
      print("Decoded assigned data: $assignedData");

      if (assignedData == null || assignedData.isEmpty) {
        throw Exception('No assigned report data received');
      }

      // Get the main report details using the reportId from assigned report
      final reportId = assignedData['reportId'];
      if (reportId == null) {
        throw Exception('No reportId found in assigned report');
      }

      final reportUrl = "${getUrl()}om/reports/$reportId";
      print("Fetching main report from URL: $reportUrl");

      final reportResponse = await get(
        Uri.parse(reportUrl),
      );

      print("Main report response status: ${reportResponse.statusCode}");
      print("Main report response body: ${reportResponse.body}");

      if (reportResponse.statusCode != 200) {
        throw Exception('Failed to load main report: ${reportResponse.statusCode}');
      }

      var reportData = json.decode(reportResponse.body);
      print("Decoded report data: $reportData");

      if (reportData == null || reportData.isEmpty) {
        throw Exception('No report data received');
      }

      setState(() {
        userData = reportData;
        type = reportData["Type"] ?? 'Unknown Type';
        description = reportData["Description"] ?? 'No description available';
        serial = reportData["SerialNo"]?.toString() ?? 'No serial number';
        latitude = reportData["Latitude"] ?? '0';
        longitude = reportData["Longitude"] ?? '0';
        status = reportData["Status"] ?? '';
        imageUrl = reportData["Image"] ?? '';
        incidentId = id;
        staffid = reportData["NRWUserID"] ?? '';
        isLoading = null;
      });

      print("State updated with incidentId: $incidentId");
      print("Type: $type");
      print("Serial: $serial");
    } catch (e) {
      print("Error in loadFileReport: $e");
      setState(() {
        error = "Failed to load report: $e";
        isLoading = null;
      });
    }
  }

  Future<void> takePhoto() async {
    try {
      final XFile? pickedFile = await imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        String base64Image = await convertFileToBase64(pickedFile);
        setState(() {
          _image = File(pickedFile.path);
          repairedImage = base64Image;
        });
      }
    } catch (e) {
      print("Error taking photo: $e");
      setState(() {
        error = "Failed to take photo: $e";
      });
    }
  }

  Future<void> getImage() async {
    try {
      final pickedFile = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        String base64Image = await convertFileToBase64(pickedFile);
        setState(() {
          _image = File(pickedFile.path);
          repairedImage = base64Image;
        });
      }
    } catch (e) {
      print("Error getting image: $e");
      setState(() {
        error = "Failed to get image: $e";
      });
    }
  }

  DateTime parsePostgresTimestamp(String timestamp) {
    try {
      return DateTime.parse(timestamp).toLocal();
    } catch (e) {
      print("Error parsing timestamp: $e");
      return DateTime.now();
    }
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
        color: Colors.grey[50],
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xff0288D1),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                        child: _buildHeaderCard(),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (imageUrl.isNotEmpty) ...[
                      _buildSectionTitle('Captured Photo'),
                      const SizedBox(height: 15),
                      _buildImageSection(fullImageUrl),
                      const SizedBox(height: 25),
                    ],
                    _buildSectionTitle('Incident Details'),
                    const SizedBox(height: 15),
                    if (userData.isNotEmpty)
                      _buildIncidentDetails()
                    else if (isLoading != null)
                      Center(child: isLoading)
                    else
                      const SizedBox(),
                    const SizedBox(height: 25),
                    _buildSectionTitle('Take a Photo'),
                    const SizedBox(height: 15),
                    _buildPhotoSection(),
                    const SizedBox(height: 25),
                    _buildSectionTitle('Select Action Taken'),
                    const SizedBox(height: 15),
                    _buildActionDropdown(),
                    if (error.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 15),
                        child:
                            TextOakar(label: error, issuccessful: successful),
                      ),
                    const SizedBox(height: 25),
                    _buildSubmitButton(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 0,
      color: Colors.white.withOpacity(0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "File Report",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    type,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Serial No: $serial",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_outlined,
                color: Colors.white,
                size: 40,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(String imageUrl) {
    return Container(
      width: double.infinity,
      height: 250,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xff0288D1).withOpacity(0.1),
        ),
      ),
      child: GestureDetector(
        onTap: () => _showFullImage(context, imageUrl),
        child: Image.network(
          imageUrl,
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
    );
  }

  Widget _buildIncidentDetails() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xff0288D1).withOpacity(0.1),
        ),
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
            _buildDetailRow(Icons.comment, 'Description', description),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            _buildDetailRow(
              Icons.calendar_month,
              'Date Reported',
              userData.isNotEmpty && userData["createdAt"] != null
                  ? "${DateFormat('EEEE, MMMM d, y').format(parsePostgresTimestamp(userData["createdAt"]))} ${DateFormat('HH:mm').format(parsePostgresTimestamp(userData["createdAt"]))}"
                  : 'Date not available',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Container(
      width: double.infinity,
      height: 250,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xff0288D1).withOpacity(0.1),
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
    );
  }

  Widget _buildActionDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xff0288D1).withOpacity(0.1),
        ),
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
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
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
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xff0288D1),
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
  print("submitData called with incidentId: $incidentId");
  print("incidentId length: ${incidentId.length}");
  print("incidentId is empty: ${incidentId.isEmpty}");

  if (repairedImage.isEmpty || taskremark.isEmpty) {
    return Message(
      token: null,
      success: null,
      error: "All Fields Must Be Filled!",
    );
  }

  if (incidentId.isEmpty) {
    return Message(
      token: null,
      success: null,
      error: "Invalid Incident ID",
    );
  }

  DateTime now = DateTime.now();
  String resolvedDate = DateFormat('yyyy-MM-dd').format(now);
  String resolvedTime = DateFormat('hh:mm a').format(now);

  try {
    // First, update the assigned report
    final assignedUrl = "${getUrl()}om-assigned-reports/update/$incidentId";
    print("Updating assigned report at URL: $assignedUrl");
    print("Incident ID being used: $incidentId");

    final assignedData = {
      'taskDescription': taskremark,
      'image': repairedImage,
      'resolvedDate': resolvedDate,
      'resolvedTime': resolvedTime,
    };
    print("Assigned report data: $assignedData");

    var assignedResponse = await put(
      Uri.parse(assignedUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(assignedData),
    );

    print("Assigned report response status: ${assignedResponse.statusCode}");
    print("Assigned report response body: ${assignedResponse.body}");

    if (assignedResponse.statusCode != 200 && assignedResponse.statusCode != 203) {
      return Message(
        token: null,
        success: null,
        error: "Failed to update assigned report: ${assignedResponse.body}",
      );
    }

    // Then, update the main report status
    final reportUrl = "${getUrl()}om-reports/update/$incidentId";
    print("Updating main report at URL: $reportUrl");

    final reportData = {
      'TaskImage': repairedImage,
      'TaskRemark': taskremark,
      'ResolvedDate': resolvedDate,
      'ResolvedTime': resolvedTime,
      'Status': 'Resolved',
    };
    print("Main report data: $reportData");

    var reportResponse = await put(
      Uri.parse(reportUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(reportData),
    );

    print("Main report response status: ${reportResponse.statusCode}");
    print("Main report response body: ${reportResponse.body}");

    if (reportResponse.statusCode == 200 || reportResponse.statusCode == 203) {
      return Message.fromJson(jsonDecode(reportResponse.body));
    } else {
      return Message(
        token: null,
        success: null,
        error: "Server error: ${reportResponse.body}",
      );
    }
  } catch (e) {
    print("Error submitting report: $e");
    return Message(
      token: null,
      success: null,
      error: "Connection failed! Check your internet connection.",
    );
  }
}

class Message {
  final dynamic token;
  final dynamic success;
  final dynamic error;

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
