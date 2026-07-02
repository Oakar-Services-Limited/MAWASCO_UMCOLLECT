// ignore_for_file: prefer_typing_uninitialized_variables

import 'package:flutter/material.dart';
import 'package:um_collect/components/NewCallItem.dart';
import 'package:um_collect/components/StaffDrawer.dart';
import 'package:um_collect/components/incidence_list_pagination.dart';
import 'package:um_collect/services/assigned_reports_service.dart';
import 'package:um_collect/pages/home.dart';
import 'package:um_collect/pages/login.dart';
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

      final reports = await AssignedReportsService.fetchAll(
        userId: widget.staffid,
        status: 'Inprogress',
        token: token,
      );
      setState(() {
        incireported = reports;
        currentPage = 1;
        isLoading = null;
      });
    } catch (e) {
      if (e is AssignedReportsAuthException) {
        final storage = const FlutterSecureStorage();
        await storage.delete(key: 'mwstaffjwt');
        await storage.delete(key: 'isstaff');
        setState(() {
          incireported = [];
          isLoading = null;
        });
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Login()),
          );
        }
        return;
      }
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
    return IncidenceListPagination(
      currentPage: currentPage,
      itemsPerPage: itemsPerPage,
      totalItems: incireported.length,
      onPrevious: _previousPage,
      onNext: _nextPage,
    );
  }
}
