// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names, unused_import

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:um_collect/components/MyRowAligned.dart';
import 'package:um_collect/components/MyRowII.dart';
import 'package:um_collect/pages/Forms/MasterMeters.dart';
import 'package:um_collect/pages/Forms/Interventions.dart';
import 'package:um_collect/pages/Forms/Washouts.dart';
import 'package:um_collect/pages/MasterMeterReadings.dart';
import 'package:um_collect/pages/NRW.dart';
import 'package:um_collect/pages/navigatetoasset.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:um_collect/components/MyDrawer.dart';
import 'package:um_collect/components/MyRow.dart';
import 'package:um_collect/components/MyRowIII.dart';
import 'package:um_collect/components/StaffDrawer.dart';
import 'package:um_collect/components/Utils.dart';
import 'package:um_collect/pages/Assets.dart';
import 'package:um_collect/pages/Routing.dart';
import 'package:um_collect/pages/complete.dart';
import 'package:um_collect/pages/incidences.dart';
import 'package:um_collect/pages/incidences_home.dart';
import 'package:um_collect/pages/assetnavigation.dart';
import 'package:um_collect/pages/pending.dart';
import 'package:um_collect/pages/login.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:um_collect/pages/stafflogin.dart';
import 'package:um_collect/pages/customer_supply_feedback.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final storage = const FlutterSecureStorage();
  String name = '';
  String staffid = '';
  String position = '';
  String pending = '';
  String complete = '';
  String formattedDate = '';
  String offset = '0';
  bool isnew = false;
  var isLoading;
  Timer? _timer;

  List stats = [];

  @override
  void initState() {
    getDefaultValues();
    super.initState();
  }

  Future<void> getDefaultValues() async {
    try {
      var token = await storage.read(key: "mwstaffjwt");

      // Check if token is null or empty
      if (token == null || token.isEmpty) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const Login()));
        return;
      }

      var decoded = parseJwt(token);
      formattedDate = DateFormat('MMMM dd, yyyy').format(DateTime.now());
      if (decoded["error"] == "Invalid token") {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const Login()));
      } else {
        setState(() {
          name = decoded["name"];
          staffid = decoded["id"];
          position = decoded["position"];
          isnew = true;
        });
        await storage.write(key: 'staffid', value: staffid);

        fetchStats(staffid, isnew);
        preloadMasterMeterNames(); // Warm cache so Master Meter Readings opens with list ready
      }
    } catch (e) {
      // Error handling: silently ignore errors during data fetching
    }
  }

  Future<void> fetchStats(String id, bool isnew) async {
    try {
      if (!mounted) return;

      setState(() {
        isnew
            ? isLoading = LoadingAnimationWidget.horizontalRotatingDots(
                color: const Color(0xff0288D1),
                size: 100,
              )
            : null;
      });

      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: "mwstaffjwt");

      if (token == null) {
        if (!mounted) return;
        setState(() {
          pending = '0';
          complete = '0';
          isLoading = null;
        });
        return;
      }

      // Fetch pending count
      final pendingResponse = await get(
        Uri.parse(
            "${getUrl()}om/assigned-reports?userId=$id&status=Inprogress"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      // Fetch resolved count
      final resolvedResponse = await get(
        Uri.parse("${getUrl()}om/assigned-reports?userId=$id&status=Resolved"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (pendingResponse.statusCode == 200 &&
          resolvedResponse.statusCode == 200) {
        var pendingData = json.decode(pendingResponse.body);
        var resolvedData = json.decode(resolvedResponse.body);
        if (!mounted) return;
        setState(() {
          pending = (pendingData['data']?.length ?? 0).toString();
          complete = (resolvedData['data']?.length ?? 0).toString();
          isLoading = null;
        });
      } else {
        if (!mounted) return;
        setState(() {
          pending = '0';
          complete = '0';
          isLoading = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        pending = '0';
        complete = '0';
        isLoading = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UM Collect',
      theme: ThemeData(
        primaryColor: const Color(0xff0288D1),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff0288D1)),
        useMaterial3: true,
      ),
      home: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            "Home",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: const Color(0xff0288D1),
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        drawer: Drawer(
          child: StaffDrawer(staffid: staffid),
        ),
        body: RefreshIndicator(
          onRefresh: () => fetchStats(staffid, false),
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
                        child: _buildWelcomeCard(),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSectionTitle("Core Services"),
                    const SizedBox(height: 15),
                    _buildCoreServicesGrid(),
                    const SizedBox(height: 25),
                    _buildSectionTitle("Meter Reading"),
                    const SizedBox(height: 15),
                    _buildMeterManagementGrid(),
                    const SizedBox(height: 25),
                    _buildSectionTitle("Incidence Tracking"),
                    const SizedBox(height: 15),
                    _buildIncidenceCards(),
                    const SizedBox(height: 25),
                    _buildSectionTitle("Customer Feedback"),
                    const SizedBox(height: 15),
                    _buildCustomerFeedbackCard(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
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
                    "Welcome back,",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha:0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha:0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Role: $position',
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
                Icons.person,
                color: Colors.white,
                size: 40,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildStatCard("Pending", pending, Icons.pending_actions),
          const SizedBox(width: 15),
          _buildStatCard("Completed", complete, Icons.task_alt),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xff0288D1).withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xff0288D1)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff0288D1),
                    ),
                  ),
                ],
              ),
            ],
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

  Widget _buildCoreServicesGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 15,
      crossAxisSpacing: 8,
      childAspectRatio: 0.8,
      children: [
        _buildServiceCard(
          'Mapping',
          Icons.map_outlined,
          () => Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => Assets(staffid: staffid),
          )),
        ),
        _buildServiceCard(
          'Navigation',
          Icons.navigation_outlined,
          () => Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => AssetNavigation(staffid: staffid),
          )),
        ),
        _buildServiceCard(
          'NRW',
          Icons.water_drop_outlined,
          () => Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const NRW(),
          )),
        ),
      ],
    );
  }

  Widget _buildMeterManagementGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 15,
      crossAxisSpacing: 8,
      childAspectRatio: 1.2,
      children: [
        _buildServiceCard(
          'Customer Meters',
          Icons.person_outline,
          () => Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => NavigateToAsset(
              label: 'Customer Meters',
              staffid: staffid,
            ),
          )),
        ),
        _buildServiceCard(
          'Master Meters',
          Icons.dashboard_outlined,
          () => Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const MasterMeterReadings(),
          )),
        ),
      ],
    );
  }

  Widget _buildIncidenceCards() {
    return Row(
      children: [
        Expanded(
          child: _buildServiceCard(
            'Pending',
            Icons.pending_actions_outlined,
            () => Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => IncidencesHome(
                staffid: staffid,
                selectedItem: 0,
              ),
            )),
            count: pending,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildServiceCard(
            'Completed',
            Icons.task_alt_outlined,
            () => Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => IncidencesHome(
                staffid: staffid,
                selectedItem: 1,
              ),
            )),
            count: complete,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerFeedbackCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const CustomerSupplyFeedback(),
        )),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: const Color(0xff0288D1).withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xff0288D1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.feedback_outlined,
                  color: Color(0xff0288D1),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Share customer feedback',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff0288D1),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Help us improve our service',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(String title, IconData icon, VoidCallback onTap,
      {String? count}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: const Color(0xff0288D1).withValues(alpha:0.1),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (count != null) ...[
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff0288D1),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xff0288D1).withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xff0288D1),
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff0288D1),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
