import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:um_collect/components/NewCallItem.dart';
import 'package:um_collect/components/StaffDrawer.dart';
import 'package:um_collect/components/Utils.dart';
import 'package:um_collect/pages/home.dart';
import 'package:http/http.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

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
        size: 100,
      );
    });

    try {
      final response = await get(
        Uri.parse("${getUrl()}reports/assigned/${widget.staffid}/0"),
      );

      var data = json.decode(response.body);

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
        actions: <Widget>[
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
      return const Center(
        child: Text('No client calls.'),
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
