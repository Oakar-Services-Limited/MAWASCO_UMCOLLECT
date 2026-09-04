import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:um_collect/components/Utils.dart';
import 'package:um_collect/models/customer.dart';
import 'package:um_collect/services/rationing_schedule_service.dart';

enum CustomerEntryMode { fromList, manual }

class FeedbackController extends ChangeNotifier {
  final _schedule = RationingScheduleService.instance;
  final _storage = const FlutterSecureStorage();
  final _imagePicker = ImagePicker();

  String selectedDay = '';
  String selectedZone = '';
  String selectedArea = '';
  String selectedRoute = '';
  String collectionMode = ''; // Customer Care | Field
  CustomerEntryMode customerEntryMode = CustomerEntryMode.fromList;
  Customer? selectedCustomer;
  String manualAccountNo = '';
  String manualCustomerName = '';
  bool? waterAvailable; // true = Yes, false = No
  String? satisfaction; // 'Sufficient' | 'Low Pressure' when water available
  String remarks = '';

  /// Staff / enumerator name stored on the feedback row as reporterName.
  String reporterName = '';
  /// True when name came from JWT / secure storage (show read-only).
  bool reporterNameFromLogin = false;
  bool reporterIdentityLoaded = false;

  // Photo/proof evidence (required on submit)
  XFile? photo;
  double? latitude;
  double? longitude;
  double? locationAccuracy;

  List<Customer> customers = [];

  /// Routes for the route dropdown (set on first zone-only fetch, kept when refetching by route).
  List<String> availableRoutes = [];
  bool isLoadingCustomers = false;
  String? customersError;

  FeedbackController() {
    loadReporterIdentity();
  }

  /// Prefer JWT `name`, then stored staffName. If neither exists, UI shows a text field.
  Future<void> loadReporterIdentity() async {
    try {
      final token = await _storage.read(key: 'mwstaffjwt');
      var name = '';
      if (token != null && token.isNotEmpty) {
        name = staffDisplayNameFromJwt(parseJwt(token));
      }
      if (name.isEmpty) {
        name = (await _storage.read(key: 'staffName'))?.trim() ?? '';
      }
      if (name.isNotEmpty) {
        reporterName = name;
        reporterNameFromLogin = true;
      } else {
        reporterName = '';
        reporterNameFromLogin = false;
      }
    } catch (_) {
      reporterName = '';
      reporterNameFromLogin = false;
    } finally {
      reporterIdentityLoaded = true;
      notifyListeners();
    }
  }

  void updateReporterName(String value) {
    if (reporterNameFromLogin) return;
    reporterName = value;
    notifyListeners();
  }

  /// Zones filtered by selected day (local).
  List<String> get filteredZones => _schedule.zonesForDay(selectedDay);

  /// Areas filtered by zone + day (local).
  List<String> get filteredAreas =>
      _schedule.areasForZoneAndDay(selectedZone, selectedDay);

  /// Route options for dropdown: full list from zone when available, else from current customers.
  List<String> get filteredRoutes => availableRoutes.isNotEmpty
      ? availableRoutes
      : _uniqueRoutesFrom(customers);

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

  String get selectedCustomerName => selectedCustomer?.name ?? '';

  List<Customer> searchCustomersByAccount(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return filteredCustomers.take(20).toList();
    return filteredCustomers
        .where((c) => c.accountNo.toLowerCase().contains(q))
        .take(20)
        .toList();
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
    if (value.isNotEmpty &&
        selectedZone.isNotEmpty &&
        selectedArea.isNotEmpty) {
      fetchCustomers();
    }
  }

  void updateCustomer(Customer? value) {
    selectedCustomer = value;
    notifyListeners();
  }

  void updateCustomerEntryMode(CustomerEntryMode mode) {
    if (customerEntryMode == mode) return;
    customerEntryMode = mode;
    selectedCustomer = null;
    manualAccountNo = '';
    manualCustomerName = '';
    notifyListeners();
  }

  void updateManualAccountNo(String value) {
    manualAccountNo = value;
    notifyListeners();
  }

  void updateManualCustomerName(String value) {
    manualCustomerName = value;
    notifyListeners();
  }

  void updateCollectionMode(String value) {
    collectionMode = value;
    notifyListeners();
  }

  void updateWaterAvailable(bool? value) {
    waterAvailable = value;
    if (value == false) {
      // No water: reset satisfaction.
      satisfaction = null;
    }
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

  Future<void> capturePhoto() async {
    // Mirror other pages: call ImagePicker directly and handle platform errors.
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      if (picked == null) return;
      photo = picked;
      notifyListeners();
    } on PlatformException catch (e) {
      // Common when camera is already open
      if (e.code == 'already_active') return;
      if (kDebugMode) {
        debugPrint('[capturePhoto] PlatformException: ${e.code} ${e.message}');
      }
      return;
    } catch (e) {
      if (kDebugMode) debugPrint('[capturePhoto] error: $e');
      return;
    }
  }

  Future<void> pickPhotoFromGallery() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      if (picked == null) return;
      photo = picked;
      notifyListeners();
    } on PlatformException catch (e) {
      if (e.code == 'already_active') return;
      if (kDebugMode) {
        debugPrint(
            '[pickPhotoFromGallery] PlatformException: ${e.code} ${e.message}');
      }
      return;
    } catch (e) {
      if (kDebugMode) debugPrint('[pickPhotoFromGallery] error: $e');
      return;
    }
  }

  void clearPhoto() {
    photo = null;
    notifyListeners();
  }

  Future<void> captureCurrentLocation() async {
    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted) return;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    final locPerm = await Geolocator.checkPermission();
    LocationPermission effective = locPerm;
    if (locPerm == LocationPermission.denied) {
      effective = await Geolocator.requestPermission();
    }
    if (effective == LocationPermission.denied ||
        effective == LocationPermission.deniedForever) {
      return;
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    latitude = pos.latitude;
    longitude = pos.longitude;
    locationAccuracy = pos.accuracy;
    notifyListeners();
  }

  void clearLocation() {
    latitude = null;
    longitude = null;
    locationAccuracy = null;
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
          '${getUrl()}wt/customer-meters?zone=${Uri.encodeComponent(zoneForApi)}&accountStatus=${Uri.encodeComponent("Active")}&limit=3000&offset=0';
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

  /// Validation: day, zone, area, route, customer (list or manual), reporter,
  /// and photo required; if waterAvailable == false, remarks required.
  String? validate() {
    if (selectedDay.isEmpty) return 'Please select a day';
    if (selectedZone.isEmpty) return 'Please select a zone';
    if (selectedArea.isEmpty) return 'Please select an area';
    if (selectedRoute.isEmpty) return 'Please select a route';
    if (customerEntryMode == CustomerEntryMode.fromList) {
      if (selectedCustomer == null) {
        return 'Please select a customer from the list';
      }
    } else {
      if (manualAccountNo.trim().isEmpty) {
        return 'Please enter the account number';
      }
      if (manualCustomerName.trim().isEmpty) {
        return 'Please enter the customer name';
      }
    }
    if (reporterName.trim().isEmpty) {
      return reporterNameFromLogin
          ? 'Could not resolve your name from login. Please re-login or enter your name.'
          : 'Please enter your name (reporter)';
    }
    if (collectionMode.isEmpty) return 'Please select data collection mode';
    if (waterAvailable == null) return 'Please indicate if water was available';
    if (waterAvailable == false && remarks.trim().isEmpty) {
      return 'Remarks are required when water was not available';
    }
    if (photo == null) return 'Please capture a photo as proof';
    return null;
  }

  /// Submit feedback to POST /customer-feedback. Returns null on success, error message otherwise.
  Future<String?> submitFeedback() async {
    final err = validate();
    if (err != null) return err;

    try {
      final token = await _storage.read(key: 'mwstaffjwt');
      if (token == null || token.isEmpty) return 'Not authenticated';

      final resolvedReporter = reporterName.trim();

      // Always use multipart endpoint so we can include required photo + optional GPS.
      final uri = Uri.parse('${getUrl()}customer-feedback/with-media');
      final req = http.MultipartRequest('POST', uri);
      req.headers['Authorization'] = 'Bearer $token';

      final customerId = customerEntryMode == CustomerEntryMode.fromList
          ? selectedCustomer!.id
          : manualAccountNo.trim();
      final accountNo = customerEntryMode == CustomerEntryMode.fromList
          ? selectedCustomer!.accountNo
          : manualAccountNo.trim();
      final customerName = customerEntryMode == CustomerEntryMode.fromList
          ? selectedCustomer!.name
          : manualCustomerName.trim();

      req.fields['day'] = selectedDay;
      req.fields['zone'] = selectedZone;
      req.fields['area'] = selectedArea;
      req.fields['customerId'] = customerId;
      req.fields['collectionMode'] = collectionMode;
      // Route is required in the form but was previously omitted from the payload.
      final routeValue = selectedRoute.isNotEmpty
          ? selectedRoute
          : (customerEntryMode == CustomerEntryMode.fromList
              ? (selectedCustomer?.route ?? '')
              : '');
      if (routeValue.isNotEmpty) {
        req.fields['route'] = routeValue;
      }
      if (accountNo.isNotEmpty) {
        req.fields['accountNo'] = accountNo;
      }
      if (customerName.isNotEmpty) {
        req.fields['customerName'] = customerName;
      }
      req.fields['waterAvailable'] = waterAvailable! ? 'true' : 'false';
      if (waterAvailable! && satisfaction != null) {
        req.fields['satisfaction'] = satisfaction!;
      }
      if (remarks.trim().isNotEmpty) {
        req.fields['remarks'] = remarks.trim();
      }
      req.fields['timestamp'] = DateTime.now().toIso8601String();
      // Always persist who submitted (from login name or manual text field).
      req.fields['reporterName'] = resolvedReporter;

      if (latitude != null && longitude != null) {
        req.fields['latitude'] = latitude.toString();
        req.fields['longitude'] = longitude.toString();
      }
      if (locationAccuracy != null) {
        req.fields['locationAccuracy'] = locationAccuracy.toString();
      }

      if (photo != null) {
        final file = File(photo!.path);
        req.files.add(await http.MultipartFile.fromPath('photo', file.path));
      }

      final streamed = await req.send();
      final response = await http.Response.fromStream(streamed);

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
    collectionMode = '';
    customerEntryMode = CustomerEntryMode.fromList;
    selectedCustomer = null;
    manualAccountNo = '';
    manualCustomerName = '';
    waterAvailable = null;
    satisfaction = null;
    remarks = '';
    photo = null;
    latitude = null;
    longitude = null;
    locationAccuracy = null;
    customers = [];
    availableRoutes = [];
    customersError = null;
    // Keep login name; clear only manually typed reporter name.
    if (!reporterNameFromLogin) {
      reporterName = '';
    }
    notifyListeners();
  }

  /// Normalize zone string to match DB format: add spaces around hyphen (e.g. "018 Tumutumu-87" -> "018 Tumutumu - 87").
  static String _normalizeZoneForApi(String zone) {
    if (zone.isEmpty) return zone;
    return zone.replaceAll(RegExp(r'\s*-\s*'), ' - ');
  }
}
