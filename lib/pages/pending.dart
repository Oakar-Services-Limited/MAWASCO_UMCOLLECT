import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:um_collect/components/NewCallItem.dart';
import 'package:um_collect/components/StaffDrawer.dart';
import 'package:um_collect/components/Utils.dart';
import 'package:um_collect/pages/home.dart';
import 'package:um_collect/pages/login.dart';
import 'package:http/http.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PendingIncidences extends StatefulWidget {
  final String staffid;
  const PendingIncidences({super.key, required this.staffid});

  @override
  State<PendingIncidences> createState() => _PendingIncidencesState();
}

class _PendingIncidencesState extends State<PendingIncidences> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<dynamic> incireported = [];
  var isLoading;
  int currentPage = 1;
  final int itemsPerPage = 5;

  @override
  void initState() {
    fetchAssignedIncidences();
    super.initState();
  }

  Future<void> fetchAssignedIncidences() async {
    setState(() {
      isLoading = LoadingAnimationWidget.staggeredDotsWave(
        color: const Color(0xff0288D1),
        size: 50,
      );
    });

    try {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: "mwstaffjwt");

      if (token == null) {
        throw Exception("No authentication token found");
      }

      final url =
          "${getUrl()}om/assigned-reports?userId=${widget.staffid}&status=Inprogress";
      print("Fetching assigned incidents from URL: $url");

      final response = await get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print("Response status code: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        print("Decoded data: $data");
        setState(() {
          incireported = data["data"] ?? [];
          isLoading = null;
        });
      } else if (response.statusCode == 400 || response.statusCode == 401) {
        // Handle authentication errors
        var errorData = json.decode(response.body);
        print("Error response: ${response.body}");

        if (errorData['error'] == 'Invalid token' ||
            response.statusCode == 401) {
          // Clear invalid token
          await storage.delete(key: 'mwstaffjwt');
          await storage.delete(key: 'isstaff');

          setState(() {
            incireported = [];
            isLoading = null;
          });

          // Redirect to login
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const Login()),
            );
          }
        } else {
          setState(() {
            incireported = [];
            isLoading = null;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Failed to fetch assigned incidents. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        print("Error response: ${response.body}");
        setState(() {
          incireported = [];
          isLoading = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Failed to fetch assigned incidents. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print("Exception occurred: $e");
      setState(() {
        incireported = [];
        isLoading = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'An error occurred while fetching incidents. Please check your connection.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<dynamic> get paginatedIncidents {
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage;
    return incireported.sublist(
      startIndex,
      endIndex > incireported.length ? incireported.length : endIndex,
    );
  }

  void _nextPage() {
    if ((currentPage * itemsPerPage) < incireported.length) {
      setState(() {
        currentPage++;
      });
    }
  }

  void _previousPage() {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
      });
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
              Icons.refresh,
              color: Colors.white,
            ),
            onPressed: () {
              fetchAssignedIncidences();
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => const Home()));
            },
          ),
        ],
        title: const Text(
          'Pending Incidences',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xff0288D1),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: StaffDrawer(
        staffid: widget.staffid,
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: SafeArea(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(
                height: 16,
              ),
              Align(alignment: Alignment.center, child: isLoading),
              Expanded(child: _buildBody()),
              if (incireported.isNotEmpty) _buildPaginationControls(),
            ],
          )),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (incireported.isEmpty && isLoading == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_empty,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No pending incidents',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else {
      return ListView.builder(
          itemCount: paginatedIncidents.length,
          itemBuilder: (context, index) {
            return NewCallItem(
              item: paginatedIncidents[index],
              index: index,
            );
          });
    }
  }

  Widget _buildPaginationControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          onPressed: _previousPage,
          child: const Text('Previous'),
        ),
        Text('Page $currentPage'),
        ElevatedButton(
          onPressed: _nextPage,
          child: const Text('Next'),
        ),
      ],
    );
  }
}
