import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:um_collect/components/MyReportedItem.dart';
import 'package:um_collect/components/StaffDrawer.dart';
import 'package:um_collect/components/Utils.dart';
import 'package:http/http.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class IncidencesList extends StatefulWidget {
  final String? staffid;
  const IncidencesList({
    super.key,
    this.staffid,
  });

  @override
  State<IncidencesList> createState() => _IncidencesListState();
}

class _IncidencesListState extends State<IncidencesList> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final storage = const FlutterSecureStorage();

  List<dynamic> incidentLst = [];
  var isLoading;
  int currentPage = 1;
  final int itemsPerPage = 5;
  String user = '';
  String id = '';
  String userId = '';

  Future<void> getUserDetails() async {
    try {
      // First check for staff token
      var staffToken = await storage.read(key: "mwstaffjwt");
      if (staffToken != null) {
        var decoded = parseJwt(staffToken.toString());
        if (!mounted) return;
        setState(() {
          userId = decoded["id"]?.toString() ?? '';
          user = decoded["name"] ?? '';
          id = decoded["id"]?.toString() ?? '';
        });
        return;
      }

      // If no staff token, check for public user token
      var publicToken = await storage.read(key: "mwjwt");
      if (publicToken != null) {
        var decoded = parseJwt(publicToken.toString());
        if (!mounted) return;
        setState(() {
          userId = decoded["id"]?.toString() ?? '';
          id = decoded["id"]?.toString() ?? '';
        });
      }
    } catch (e) {
      print("Error getting user ID: $e");
    }
  }

  @override
  void initState() {
    getUserDetails().then((_) {
      fetchReportedIncidences();
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> fetchReportedIncidences() async {
    // Use staffid if provided, otherwise use userId from token
    String userIdentifier = widget.staffid ?? userId;

    if (userIdentifier.isEmpty) {
      print("No user ID available to fetch incidents");
      if (!mounted) return;
      setState(() {
        isLoading = null;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      isLoading = LoadingAnimationWidget.staggeredDotsWave(
        color: const Color(0xff0288D1),
        size: 100,
      );
    });

    try {
      // Get auth token for authenticated requests
      var staffToken = await storage.read(key: "mwstaffjwt");
      var publicToken = await storage.read(key: "mwjwt");
      var authToken = staffToken ?? publicToken;

      // Use the correct endpoint: /om/reports with userId query parameter
      String url = "${getUrl()}om/reports?userId=$userIdentifier";
      print("Fetching reported incidents from: $url");
      print("User ID being used: $userIdentifier");

      Map<String, String> headers = {
        'Content-Type': 'application/json',
      };

      // Add auth header if token exists
      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await get(Uri.parse(url), headers: headers);

      print("Response status: ${response.statusCode}");
      print("Response body length: ${response.body.length}");
      if (response.body.length < 500) {
        print("Response body: ${response.body}");
      }

      if (response.statusCode == 200) {
        var decoded = json.decode(response.body);

        // Handle different response formats
        List responseList;
        if (decoded is List) {
          responseList = decoded;
        } else if (decoded is Map) {
          if (decoded.containsKey('data') && decoded['data'] is List) {
            responseList = decoded['data'];
          } else if (decoded.containsKey('reports') &&
              decoded['reports'] is List) {
            responseList = decoded['reports'];
          } else if (decoded.containsKey('results') &&
              decoded['results'] is List) {
            responseList = decoded['results'];
          } else {
            responseList = [];
          }
        } else {
          responseList = [];
        }

        if (!mounted) return;
        setState(() {
          incidentLst = responseList;
          isLoading = null;
        });
        print(
            "Loaded ${responseList.length} incidents for user: $userIdentifier");
      } else {
        print("Failed to fetch incidents. Status: ${response.statusCode}");
        print("Response: ${response.body}");
        if (!mounted) return;
        setState(() {
          incidentLst = [];
          isLoading = null;
        });
      }
    } catch (e, stackTrace) {
      print("Error fetching reported incidents: $e");
      print("Stack trace: $stackTrace");
      if (!mounted) return;
      setState(() {
        incidentLst = [];
        isLoading = null;
      });
    }
  }

  List<dynamic> get paginatedIncidents {
    if (incidentLst.isEmpty) return [];
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage;
    return incidentLst.sublist(
      startIndex,
      endIndex > incidentLst.length ? incidentLst.length : endIndex,
    );
  }

  void _nextPage() {
    if ((currentPage * itemsPerPage) < incidentLst.length) {
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
              fetchReportedIncidences();
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
        title: const Text(
          'My Reported Incidences',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xff0288D1),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: widget.staffid != null
          ? StaffDrawer(staffid: widget.staffid!)
          : StaffDrawer(staffid: userId.isNotEmpty ? userId : ''),
      body: Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        decoration: const BoxDecoration(color: Colors.white),
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
              if (incidentLst.isNotEmpty) _buildPaginationControls(),
            ],
          )),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading != null) {
      return const SizedBox.shrink();
    }

    if (incidentLst.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No reported incidents found.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    } else {
      return ListView.builder(
          itemCount: paginatedIncidents.length,
          itemBuilder: (context, index) {
            return MyReportedItem(
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
