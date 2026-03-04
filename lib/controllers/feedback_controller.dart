import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:um_collect/components/Utils.dart';
import 'package:um_collect/models/customer.dart';
import 'package:um_collect/models/customer_feedback.dart';
import 'package:um_collect/services/rationing_schedule_service.dart';

class FeedbackController extends ChangeNotifier {
  final _schedule = RationingScheduleService.instance;
  final _storage = const FlutterSecureStorage();

  String selectedDay = '';
  String selectedZone = '';
  String selectedArea = '';
  String selectedRoute = '';
  Customer? selectedCustomer;
  bool? waterAvailable; // true = Yes, false = No
  String? satisfaction; // 'Sufficient' | 'Low Pressure' when water available
  String remarks = '';

  List<Customer> customers = [];
  /// Routes for the route dropdown (set on first zone-only fetch, kept when refetching by route).
  List<String> availableRoutes = [];
  bool isLoadingCustomers = false;
  String? customersError;

  /// Zones filtered by selected day (local).
  List<String> get filteredZones => _schedule.zonesForDay(selectedDay);

  /// Areas filtered by zone + day (local).
  List<String> get filteredAreas =>
      _schedule.areasForZoneAndDay(selectedZone, selectedDay);

  /// Route options for dropdown: full list from zone when available, else from current customers.
  List<String> get filteredRoutes =>
      availableRoutes.isNotEmpty ? availableRoutes : _uniqueRoutesFrom(customers);

  static List<String> _uniqueRoutesFrom(List<Customer> list) {
    final set = <String>{};
    for (final c in list) {
      if (c.route.isNotEmpty) set.add(c.route);
    }
    return set.toList()..sort();
  }

  /// Customers for selected zone (and route when refetched). API filters by zone and route.
  List<Customer> get filteredCustomers {
    if (selectedRoute.isEmpty) return [];
    return customers;
  }

  void updateDay(String value) {
    if (selectedDay == value) return;
    selectedDay = value;
    selectedZone = '';
    selectedArea = '';
    selectedRoute = '';
    selectedCustomer = null;
    customers = [];
    availableRoutes = [];
    customersError = null;
    notifyListeners();
  }

  void updateZone(String value) {
    if (selectedZone == value) return;
    selectedZone = value;
    selectedArea = '';
    selectedRoute = '';
    selectedCustomer = null;
    customers = [];
    availableRoutes = [];
    customersError = null;
    notifyListeners();
  }

  void updateArea(String value) {
    if (selectedArea == value) return;
    selectedArea = value;
    selectedRoute = '';
    selectedCustomer = null;
    customers = [];
    availableRoutes = [];
    customersError = null;
    notifyListeners();
    if (value.isNotEmpty && selectedZone.isNotEmpty) {
      fetchCustomers();
    }
  }

  void updateRoute(String value) {
    if (selectedRoute == value) return;
    selectedRoute = value;
    selectedCustomer = null;
    notifyListeners();
    if (value.isNotEmpty && selectedZone.isNotEmpty && selectedArea.isNotEmpty) {
      fetchCustomers();
    }
  }

  void updateCustomer(Customer? value) {
    selectedCustomer = value;
    notifyListeners();
  }

  void updateWaterAvailable(bool? value) {
    waterAvailable = value;
    if (value == false) satisfaction = null;
    notifyListeners();
  }

  void updateSatisfaction(String? value) {
    satisfaction = value;
    notifyListeners();
  }

  void updateRemarks(String value) {
    remarks = value;
    notifyListeners();
  }

  /// Fetch customers from API when zone and area are selected.
  /// When route is selected, API filters by zone and route; otherwise zone only (routes come from response).
  Future<void> fetchCustomers() async {
    if (selectedZone.isEmpty || selectedArea.isEmpty) return;
    isLoadingCustomers = true;
    customersError = null;
    customers = [];
    notifyListeners();

    try {
      final token = await _storage.read(key: 'mwstaffjwt');
      if (kDebugMode) {
        debugPrint(
            '[fetchCustomers] zone=$selectedZone area=$selectedArea route=$selectedRoute token=${token != null && token.isNotEmpty ? "present" : "null/empty"}');
      }
      if (token == null || token.isEmpty) {
        customersError = 'Not authenticated';
        if (kDebugMode) debugPrint('[fetchCustomers] Not authenticated');
        isLoadingCustomers = false;
        notifyListeners();
        return;
      }

      // Normalize zone to match DB format (e.g. "018 Tumutumu-87" -> "018 Tumutumu - 87")
      final zoneForApi = _normalizeZoneForApi(selectedZone);
      var path =
          '${getUrl()}wt/customer-meters?zone=${Uri.encodeComponent(zoneForApi)}&limit=3000&offset=0';
      if (selectedRoute.isNotEmpty) {
        path += '&route=${Uri.encodeComponent(selectedRoute)}';
      }
      final uri = Uri.parse(path);
      if (kDebugMode) debugPrint('[fetchCustomers] GET $uri');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (kDebugMode) {
        final bodyPreview = response.body.length > 500
            ? '${response.body.substring(0, 500)}...'
            : response.body;
        debugPrint(
            '[fetchCustomers] status=${response.statusCode} body=$bodyPreview');
      }

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        List<dynamic> list = [];
        if (body is Map && body['data'] is List) {
          list = body['data'] as List<dynamic>;
        } else if (body is List) {
          list = body;
        } else if (body is Map && body['customers'] is List) {
          list = body['customers'] as List<dynamic>;
        }

        if (kDebugMode) {
          debugPrint(
              '[fetchCustomers] raw list length=${list.length} body.success=${body is Map ? body['success'] : "n/a"}');
        }

        customers = list
            .map((e) => Customer.fromJson(e as Map<String, dynamic>))
            .toList();
        if (selectedRoute.isEmpty) {
          availableRoutes = _uniqueRoutesFrom(customers);
        }
        customersError = null;
      } else {
        if (kDebugMode)
          debugPrint('[fetchCustomers] non-200 status=${response.statusCode}');
        customersError = 'Failed to load customers';
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[fetchCustomers] catch: $e');
        debugPrint('[fetchCustomers] stack: $st');
      }
      customersError = 'Failed to load customers';
      customers = [];
    } finally {
      isLoadingCustomers = false;
      notifyListeners();
    }
  }

  /// Validation: day, zone, area, route, customer required; if waterAvailable == false, remarks required.
  String? validate() {
    if (selectedDay.isEmpty) return 'Please select a day';
    if (selectedZone.isEmpty) return 'Please select a zone';
    if (selectedArea.isEmpty) return 'Please select an area';
    if (selectedRoute.isEmpty) return 'Please select a route';
    if (selectedCustomer == null) return 'Please select a customer';
    if (waterAvailable == null) return 'Please indicate if water was available';
    if (waterAvailable == false && remarks.trim().isEmpty) {
      return 'Remarks are required when water was not available';
    }
    return null;
  }

  /// Submit feedback to POST /customer-feedback. Returns null on success, error message otherwise.
  Future<String?> submitFeedback() async {
    final err = validate();
    if (err != null) return err;

    try {
      final token = await _storage.read(key: 'mwstaffjwt');
      if (token == null || token.isEmpty) return 'Not authenticated';

      final feedback = CustomerFeedback(
        day: selectedDay,
        zone: selectedZone,
        area: selectedArea,
        customerId: selectedCustomer!.id,
        waterAvailable: waterAvailable!,
        satisfaction: waterAvailable! ? satisfaction : null,
        remarks: remarks.trim(),
        timestamp: DateTime.now(),
      );

      final response = await http.post(
        Uri.parse('${getUrl()}customer-feedback'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(feedback.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        resetForm();
        return null;
      }
      return 'Failed to submit feedback';
    } catch (e) {
      return 'Failed to submit feedback';
    }
  }

  void resetForm() {
    selectedDay = '';
    selectedZone = '';
    selectedArea = '';
    selectedRoute = '';
    selectedCustomer = null;
    waterAvailable = null;
    satisfaction = null;
    remarks = '';
    customers = [];
    availableRoutes = [];
    customersError = null;
    notifyListeners();
  }

  /// Normalize zone string to match DB format: add spaces around hyphen (e.g. "018 Tumutumu-87" -> "018 Tumutumu - 87").
  static String _normalizeZoneForApi(String zone) {
    if (zone.isEmpty) return zone;
    return zone.replaceAll(RegExp(r'\s*-\s*'), ' - ');
  }
}
