import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:um_collect/components/MyReportedItem.dart';
import 'package:um_collect/components/StaffDrawer.dart';
import 'package:um_collect/components/Utils.dart';
import 'package:http/http.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class IncidencesList extends StatefulWidget {
  const IncidencesList({
    super.key,
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
  String staffid = '';

  @override
  void initState() {
    fetchReportedIncidences();
    super.initState();
  }

  Future<void> fetchReportedIncidences() async {
    setState(() {
      isLoading = LoadingAnimationWidget.staggeredDotsWave(
        color: const Color(0xff0288D1),
        size: 50,
      );
    });

    try {
      final token = await storage.read(key: "mwstaffjwt");

      if (token == null) {
        throw Exception("No authentication token found");
      }

      // Extract user ID from token
      var decoded = parseJwt(token);
      String userId = decoded["id"]?.toString() ?? '';

      if (userId.isEmpty) {
        throw Exception("No user ID found in token");
      }

      // Update staffid for drawer
      if (mounted) {
        setState(() {
          staffid = userId;
        });
      }

      print("Fetching reported incidents for userId: $userId");

      final response = await get(
        Uri.parse("${getUrl()}om/reports?userId=$userId"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("Response status code: ${response.statusCode}");
      if (response.body.length < 500) {
        print("Response body: ${response.body}");
      }

      if (response.statusCode == 200) {
        var decoded = json.decode(response.body);
        List responseList = decoded['data'] ?? [];

        setState(() {
          incidentLst = responseList;
          isLoading = null;
        });
      } else if (response.statusCode == 400 || response.statusCode == 401) {
        var errorData = json.decode(response.body);

        if (errorData['error'] == 'Invalid token' ||
            response.statusCode == 401) {
          await storage.delete(key: 'mwstaffjwt');
          await storage.delete(key: 'isstaff');

          setState(() {
            incidentLst = [];
            isLoading = null;
          });
        } else {
          setState(() {
            incidentLst = [];
            isLoading = null;
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to fetch incidents. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        setState(() {
          incidentLst = [];
          isLoading = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to fetch incidents. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print("Exception occurred: $e");
      setState(() {
        incidentLst = [];
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
      drawer: StaffDrawer(staffid: staffid.isNotEmpty ? staffid : ''),
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
