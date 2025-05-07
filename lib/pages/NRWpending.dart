import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kiambu_umcollect/components/NewNRWItem.dart';
import 'package:kiambu_umcollect/components/StaffDrawer.dart';
import 'package:kiambu_umcollect/components/Utils.dart';
import 'package:kiambu_umcollect/pages/NRW.dart';
import 'package:http/http.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class NRWPending extends StatefulWidget {
  final String staffid;
  const NRWPending({super.key, required this.staffid});

  @override
  State<NRWPending> createState() => _NRWPendingState();
}

class _NRWPendingState extends State<NRWPending> {
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
        size: 100,
      );
    });

    try {
      final response = await get(
        Uri.parse("${getUrl()}nrw_leakages/assigned/${widget.staffid}/0"),
      );

      var data = json.decode(response.body);

      print("submitted data: $data");

      setState(() {
        incireported = data["pending"];
        isLoading = null;
      });
    } catch (e) {
      setState(() {
        isLoading = null;
      });
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
        elevation: 0,
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
          'Pending Incidences',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xff0288D1),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: StaffDrawer(
        staffid: widget.staffid,
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xff0288D1).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Align(alignment: Alignment.center, child: isLoading),
                Expanded(child: _buildBody()),
                if (incireported.isNotEmpty) _buildPaginationControls(),
              ],
            ),
          ),
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
              'No pending incidences',
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
          padding: const EdgeInsets.only(top: 8),
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: NewNRWItem(
                item: paginatedIncidents[index],
                index: index,
              ),
            );
          });
    }
  }

  Widget _buildPaginationControls() {
    int totalPages = (incireported.length / itemsPerPage).ceil();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalPages, (index) {
          bool isCurrentPage = index + 1 == currentPage;
          return GestureDetector(
            onTap: () {
              setState(() {
                currentPage = index + 1;
              });
            },
            child: Container(
              width: isCurrentPage ? 12 : 8,
              height: isCurrentPage ? 12 : 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCurrentPage
                    ? const Color(0xff0288D1)
                    : const Color(0xff0288D1).withOpacity(0.2),
              ),
            ),
          );
        }),
      ),
    );
  }
}
