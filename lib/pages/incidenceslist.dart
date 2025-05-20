import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:um_collect/components/MyDrawer.dart';
import 'package:um_collect/components/MyReportedItem.dart';
import 'package:um_collect/components/Utils.dart';
import 'package:um_collect/pages/incidences.dart';
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

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  void initState() {
    fetchReportedIncidences();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> fetchReportedIncidences() async {
    var token = await storage.read(key: "mwjwt");
    var decoded = parseJwt(token.toString());
    var userid = decoded["id"];

    setState(() {
      isLoading = LoadingAnimationWidget.staggeredDotsWave(
        color: const Color(0xff0288D1),
        size: 100,
      );
    });

    try {
      final response = await get(
        Uri.parse("${getUrl()}reports/reported/$userid/0"),
      );

      List responseList = json.decode(response.body);
      setState(() {
        incidentLst = responseList;
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
              Icons.arrow_back,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const Incidences()));
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
      drawer: const MyDrawer(),
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
    if (incidentLst.isEmpty && isLoading == null) {
      return const Center(
        child: Text('No client calls.'),
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
