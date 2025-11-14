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
import 'package:um_collect/components/MyTextInput.dart';

class FileReport extends StatefulWidget {
  final dynamic item;
  const FileReport({super.key, required this.item});

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

  @override
  void initState() {
    super.initState();
    _image = null;
    if (widget.item == null) {
    }
    loadFileReport();
  }

  Future<String> convertFileToBase64(XFile file) async {
    List<int> fileBytes = await file.readAsBytes();
    String base64String = base64Encode(fileBytes);
    return base64String;
  }

  Future<void> loadFileReport() async {
    if (widget.item == null) {
      setState(() {
        error = "Invalid Report Data";
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
      setState(() {
        userData = widget.item;
        type = widget.item["report"]["incidentType"] ?? 'Unknown Type';
        description =
            widget.item["report"]["description"] ?? 'No description available';
        serial =
            widget.item["report"]["serialNo"]?.toString() ?? 'No serial number';
        latitude = widget.item["report"]["latitude"]?.toString() ?? '0';
        longitude = widget.item["report"]["longitude"]?.toString() ?? '0';
        status = widget.item["status"] ?? '';
        imageUrl = widget.item["image"] ?? '';
        incidentId = widget.item["id"] ?? '';
        staffid = widget.item["admin"]?["id"] ?? '';
        isLoading = null;
      });
    } catch (e) {
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
        setState(() {
          _image = File(pickedFile.path);
          repairedImage = pickedFile.path;
        });
      }
    } catch (e) {
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
        setState(() {
          _image = File(pickedFile.path);
          repairedImage = pickedFile.path;
        });
      }
    } catch (e) {
      setState(() {
        error = "Failed to get image: $e";
      });
    }
  }

  DateTime parsePostgresTimestamp(String timestamp) {
    try {
      return DateTime.parse(timestamp).toLocal();
    } catch (e) {
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
        backgroundColor: const Color(0xff0288D1),
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "File Report",
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
                    MyTextInput(
                      lines: 3,
                      value: taskremark,
                      type: TextInputType.text,
                      onSubmit: (value) {
                        setState(() {
                          taskremark = value;
                        });
                      },
                      title: 'Describe the action taken',
                    ),
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
      color: Colors.white.withValues(alpha:0),
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
                      color: Colors.white.withValues(alpha:0.9),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.2),
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
          color: const Color(0xff0288D1).withValues(alpha:0.1),
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
          color: const Color(0xff0288D1).withValues(alpha:0.1),
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
          color: const Color(0xff0288D1).withValues(alpha:0.1),
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
                    color: Colors.black.withValues(alpha:0.2),
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
          });

          if (res.error == null) {
            _showMessage(res.success ?? "Report submitted successfully", false);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => CompleteIncidences(
                  staffid: staffid,
                ),
              ),
            );
          } else {
            _showMessage(res.error ?? "Failed to submit report", true);
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
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: "mwstaffjwt");

    // Create multipart request
    var request = MultipartRequest(
      'PUT',
      Uri.parse("${getUrl()}om/assigned-reports/$incidentId"),
    );

    // Add headers
    request.headers.addAll({
      'Authorization': 'Bearer $token',
    });

    // Add text fields
    request.fields['taskRemark'] = taskremark;
    request.fields['resolvedDate'] = resolvedDate;
    request.fields['resolvedTime'] = resolvedTime;

    // Add image file if it exists
    if (repairedImage.isNotEmpty) {
      var file = File(repairedImage);
      if (await file.exists()) {
        request.files.add(
          await MultipartFile.fromPath(
            'image',
            file.path,
          ),
        );
      }
    }

    // Send the request
    var streamedResponse = await request.send();
    var response = await Response.fromStream(streamedResponse);
    if (response.statusCode == 200 || response.statusCode == 203) {
      return Message(
        token: null,
        success: "Report updated successfully",
        error: null,
      );
    } else {
      // Try to parse the error message from the response
      String errorMessage = "Server error (${response.statusCode})!";
      try {
        final errorData = jsonDecode(response.body);
        if (errorData['error'] != null) {
          errorMessage += " ${errorData['error']}";
        } else if (errorData['message'] != null) {
          errorMessage += " ${errorData['message']}";
        } else {
          errorMessage += " ${response.body}";
        }
      } catch (e) {
        errorMessage += " ${response.body}";
      }

      return Message(
        token: null,
        success: null,
        error: errorMessage,
      );
    }
  } catch (e) {
    return Message(
      token: null,
      success: null,
      error: "Connection failed! Check your internet connection. Error: $e",
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
