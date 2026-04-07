import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:um_collect/components/Utils.dart';
import 'package:um_collect/services/customer_db_service.dart';

class DormantSurveyController extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  final _db = CustomerDbService.instance;
  final _imagePicker = ImagePicker();

  bool duplicateCheckInProgress = false;

  bool isLoadingDb = true;
  String? dbError;

  // Step A: account search
  String scheme = '';
  String zone = '';
  String route = '';
  CustomerDbEntry? selectedAccount;
  String accountSearchQuery = '';

  // Step B: ground verification
  String sourceOfWater = ''; // choice
  bool? detailsMatch; // Yes=true dormant/vacant
  String? willingToRegularize; // Only if detailsMatch==true: "Yes - willing to pay" | "No - not interested"

  // If detailsMatch == false
  String currentAccountNumber = '';
  String currentMeterNumber = '';
  bool? currentUserIsRegisteredCustomer;
  bool? requiresInvestigation; // only if currentUserIsRegisteredCustomer == true
  String investigationReason = '';

  // Step C: occupants and usage (if currentUserIsRegisteredCustomer == false)
  String relationshipToAccountHolder = ''; // choice
  String currentOccupantName = '';
  String currentOccupantPhone = '';

  // Step D: meter condition + evidence
  String meterCondition = ''; // choice
  String meterReading = '';
  String generalCommentChoice = ''; // required choice
  String generalCommentOther = ''; // only if choice == Other

  // Evidence
  XFile? photo;
  double? latitude;
  double? longitude;
  double? locationAccuracy;

  bool isSubmitting = false;

  static const List<String> schemes = ['Rural', 'Urban'];

  static const List<String> regularizeOptions = [
    'Yes - willing to pay',
    'No - not interested',
  ];

  static const List<String> sourceOfWaterOptions = [
    'MAWASCO (Active)',
    'Neighbors',
    'Borehole / Well',
    'Rain Water',
    'Suspected Illegal / Unknown',
  ];

  static const List<String> relationshipOptions = [
    'New Tenant',
    'Caretaker / Agent',
    'New Property Owner',
    'Family member (Spouse, Son, Daughter)',
  ];

  static const List<String> meterConditions = [
    'Good / Functional',
    'Buried / Covered(inaccessible)',
    'Glass Broken / Foggy / Illegible',
    'Stuck / Stopped',
    'Disconnected (Meter On Ground)',
    'Disconnected (Meter Removed)',
    'No Meter (Direct)',
  ];

  static const String generalCommentOtherLabel = 'Other specify';

  static const List<String> generalCommentOptions = [
    'Active and consuming (wrongly categorized)',
    'True dormant (details match)',
    'False dormant (different account)',
    'Meter not found (exhausted all means)',
    generalCommentOtherLabel,
  ];

  Future<void> init() async {
    try {
      isLoadingDb = true;
      dbError = null;
      notifyListeners();
      await _db.ensureLoaded();
    } catch (e) {
      dbError = 'Failed to load customer DB';
    } finally {
      isLoadingDb = false;
      notifyListeners();
    }
  }

  List<String> zonesForSelectedScheme() {
    if (scheme.isEmpty) return const [];
    return _db.zonesForScheme(scheme);
  }

  List<String> routesForSelectedZone() {
    if (scheme.isEmpty || zone.isEmpty) return const [];
    return _db.routesForZone(scheme, zone);
  }

  List<CustomerDbEntry> accountOptions() {
    if (scheme.isEmpty || zone.isEmpty || route.isEmpty) return const [];
    return _db.accounts(
      scheme: scheme,
      zone: zone,
      route: route,
      query: accountSearchQuery,
      limit: 200,
    );
  }

  void setScheme(String v) {
    if (scheme == v) return;
    scheme = v;
    zone = '';
    route = '';
    selectedAccount = null;
    notifyListeners();
  }

  void setZone(String v) {
    if (zone == v) return;
    zone = v;
    route = '';
    selectedAccount = null;
    notifyListeners();
  }

  void setRoute(String v) {
    if (route == v) return;
    route = v;
    selectedAccount = null;
    notifyListeners();
  }

  void setAccount(CustomerDbEntry? v) {
    selectedAccount = v;
    notifyListeners();
  }

  String _normalizeName(String v) {
    return v.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  Future<bool> isDormantNameAlreadySubmitted(String customerName) async {
    try {
      final token = await _storage.read(key: 'mwstaffjwt');
      if (token == null || token.isEmpty) return false;

      final normalized = _normalizeName(customerName);
      if (normalized.isEmpty) return false;

      duplicateCheckInProgress = true;
      notifyListeners();

      final uri = Uri.parse('${getUrl()}dormant-survey/exists').replace(
        queryParameters: {'customerName': normalized},
      );
      final resp = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode < 200 || resp.statusCode >= 300) return false;

      final decoded = jsonDecode(resp.body);
      final exists = decoded is Map &&
          decoded['data'] is Map &&
          decoded['data']['exists'] == true;
      return exists;
    } catch (_) {
      return false;
    } finally {
      duplicateCheckInProgress = false;
      notifyListeners();
    }
  }

  void setAccountSearchQuery(String v) {
    accountSearchQuery = v;
    notifyListeners();
  }

  void setSourceOfWater(String v) {
    sourceOfWater = v;
    notifyListeners();
  }

  void setDetailsMatch(bool? v) {
    detailsMatch = v;
    // Clear dependent fields when switching paths
    willingToRegularize = null;
    currentAccountNumber = '';
    currentMeterNumber = '';
    currentUserIsRegisteredCustomer = null;
    requiresInvestigation = null;
    investigationReason = '';
    relationshipToAccountHolder = '';
    currentOccupantName = '';
    currentOccupantPhone = '';
    notifyListeners();
  }

  void setWillingToRegularize(String? v) {
    willingToRegularize = v;
    notifyListeners();
  }

  void setCurrentAccountNumber(String v) {
    currentAccountNumber = v;
    notifyListeners();
  }

  void setCurrentMeterNumber(String v) {
    currentMeterNumber = v;
    notifyListeners();
  }

  void setCurrentUserIsRegisteredCustomer(bool? v) {
    currentUserIsRegisteredCustomer = v;
    requiresInvestigation = null;
    investigationReason = '';
    relationshipToAccountHolder = '';
    currentOccupantName = '';
    currentOccupantPhone = '';
    notifyListeners();
  }

  void setRequiresInvestigation(bool? v) {
    requiresInvestigation = v;
    if (v != true) {
      investigationReason = '';
    }
    notifyListeners();
  }

  void setInvestigationReason(String v) {
    investigationReason = v;
    notifyListeners();
  }

  void setRelationshipToAccountHolder(String v) {
    relationshipToAccountHolder = v;
    notifyListeners();
  }

  void setCurrentOccupantName(String v) {
    currentOccupantName = v;
    notifyListeners();
  }

  void setCurrentOccupantPhone(String v) {
    currentOccupantPhone = v;
    notifyListeners();
  }

  void setMeterCondition(String v) {
    meterCondition = v;
    // If disconnected, we may want photo; if not, photo optional.
    notifyListeners();
  }

  void setMeterReading(String v) {
    meterReading = v;
    notifyListeners();
  }

  void setGeneralCommentChoice(String v) {
    if (generalCommentChoice == v) return;
    generalCommentChoice = v;
    if (generalCommentChoice != generalCommentOtherLabel) {
      generalCommentOther = '';
    }
    notifyListeners();
  }

  void setGeneralCommentOther(String v) {
    generalCommentOther = v;
    notifyListeners();
  }

  String? buildGeneralCommentsForSubmit() {
    if (generalCommentChoice.trim().isEmpty) return null;
    if (generalCommentChoice == generalCommentOtherLabel) {
      final other = generalCommentOther.trim();
      if (other.isEmpty) return null;
      return 'Other: $other';
    }
    return generalCommentChoice.trim();
  }

  Future<void> capturePhoto() async {
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
      if (e.code == 'already_active') return;
      if (kDebugMode) {
        debugPrint('[DormantSurvey.capturePhoto] ${e.code} ${e.message}');
      }
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
        debugPrint('[DormantSurvey.pickPhotoFromGallery] ${e.code} ${e.message}');
      }
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

  void setCapturedLocation({
    required double lat,
    required double lng,
    required double accuracy,
  }) {
    latitude = lat;
    longitude = lng;
    locationAccuracy = accuracy;
    notifyListeners();
  }

  String? validate() {
    // Step A
    if (scheme.isEmpty) return 'Select scheme (Rural/Urban)';
    if (zone.isEmpty) return 'Select zone';
    if (route.isEmpty) return 'Select route';
    if (selectedAccount == null) return 'Select an account';

    // Step B
    if (sourceOfWater.trim().isEmpty) return 'Source of water is required';
    if (detailsMatch == null) return 'Indicate if system details match ground';

    if (detailsMatch == true) {
      if (willingToRegularize == null || willingToRegularize!.isEmpty) {
        return 'Indicate if customer is willing to regularize';
      }
      if (currentUserIsRegisteredCustomer == null) {
        return 'Indicate if current user is the registered customer';
      }
      if (currentUserIsRegisteredCustomer == false) {
        if (relationshipToAccountHolder.trim().isEmpty) {
          return 'Relationship to account holder is required';
        }
        if (currentOccupantName.trim().isEmpty) {
          return 'Current occupant name is required';
        }
        if (currentOccupantPhone.trim().isEmpty) {
          return 'Current occupant phone is required';
        }
      }
      if (requiresInvestigation == null) {
        return 'Indicate if this requires investigation';
      }
      if (requiresInvestigation == true && investigationReason.trim().isEmpty) {
        return 'Provide reason for investigation';
      }
    } else {
      if (currentAccountNumber.trim().isEmpty) {
        return 'Enter current account number';
      }
      if (currentMeterNumber.trim().isEmpty) {
        return 'Enter current meter number';
      }
      if (currentUserIsRegisteredCustomer == null) {
        return 'Indicate if current user is the registered customer';
      }
      if (currentUserIsRegisteredCustomer == false) {
        if (relationshipToAccountHolder.trim().isEmpty) {
          return 'Relationship to account holder is required';
        }
        if (currentOccupantName.trim().isEmpty) {
          return 'Current occupant name is required';
        }
        if (currentOccupantPhone.trim().isEmpty) {
          return 'Current occupant phone is required';
        }
      }
      if (requiresInvestigation == null) {
        return 'Indicate if this requires investigation';
      }
      if (requiresInvestigation == true && investigationReason.trim().isEmpty) {
        return 'Provide reason for investigation';
      }
    }

    // Step D
    if (meterCondition.isEmpty) return 'Select meter condition';
    final noReadingConditions = <String>{
      'No Meter (Direct)',
      'Disconnected (Meter Removed)',
      'Buried / Covered(inaccessible)',
    };
    final needsReading = !noReadingConditions.contains(meterCondition);
    if (needsReading && meterReading.trim().isEmpty) {
      return 'Enter meter reading (use 0 / estimate if illegible)';
    }

    // General comments choice required
    if (generalCommentChoice.trim().isEmpty) {
      return 'Select general comments option';
    }
    if (generalCommentChoice == generalCommentOtherLabel &&
        generalCommentOther.trim().isEmpty) {
      return 'Specify other general comments';
    }

    // GPS required per doc
    if (latitude == null || longitude == null) {
      return 'Capture GPS location';
    }

    // Photo required when disconnected (per doc hint)
    if (meterCondition == 'Disconnected (Meter On Ground)' && photo == null) {
      return 'Capture a photo for disconnected meters';
    }

    return null;
  }

  Future<String?> submit() async {
    final err = validate();
    if (err != null) return err;

    isSubmitting = true;
    notifyListeners();
    try {
      final token = await _storage.read(key: 'mwstaffjwt');
      if (token == null || token.isEmpty) return 'Not authenticated';

      final acct = selectedAccount!;
      final already = await isDormantNameAlreadySubmitted(acct.customerName);
      if (already) return 'Dormant Account already submitted';

      final uri = Uri.parse('${getUrl()}dormant-survey/with-media');
      final req = http.MultipartRequest('POST', uri);
      req.headers['Authorization'] = 'Bearer $token';

      req.fields['scheme'] = scheme;
      req.fields['zone'] = zone;
      req.fields['route'] = route;
      req.fields['connectionNumber'] = acct.connectionNumber;
      req.fields['customerName'] = acct.customerName;
      req.fields['meterNoSystem'] = acct.meterNo;
      req.fields['sourceOfWater'] = sourceOfWater.trim();
      req.fields['detailsMatch'] = detailsMatch == true ? 'true' : 'false';
      if (willingToRegularize != null) {
        req.fields['willingToRegularize'] = willingToRegularize!;
      }
      if (currentAccountNumber.trim().isNotEmpty) {
        req.fields['currentAccountNumber'] = currentAccountNumber.trim();
      }
      if (currentMeterNumber.trim().isNotEmpty) {
        req.fields['currentMeterNumber'] = currentMeterNumber.trim();
      }
      if (currentUserIsRegisteredCustomer != null) {
        req.fields['currentUserIsRegisteredCustomer'] =
            currentUserIsRegisteredCustomer == true ? 'true' : 'false';
      }
      if (requiresInvestigation != null) {
        req.fields['requiresInvestigation'] =
            requiresInvestigation == true ? 'true' : 'false';
      }
      if (investigationReason.trim().isNotEmpty) {
        req.fields['investigationReason'] = investigationReason.trim();
      }
      if (relationshipToAccountHolder.trim().isNotEmpty) {
        req.fields['relationshipToAccountHolder'] = relationshipToAccountHolder.trim();
      }
      if (currentOccupantName.trim().isNotEmpty) {
        req.fields['currentOccupantName'] = currentOccupantName.trim();
      }
      if (currentOccupantPhone.trim().isNotEmpty) {
        req.fields['currentOccupantPhone'] = currentOccupantPhone.trim();
      }

      req.fields['meterCondition'] = meterCondition;
      if (meterReading.trim().isNotEmpty) {
        req.fields['meterReading'] = meterReading.trim();
      }
      final gen = buildGeneralCommentsForSubmit();
      if (gen != null && gen.trim().isNotEmpty) {
        req.fields['generalComments'] = gen.trim();
      }

      req.fields['latitude'] = latitude.toString();
      req.fields['longitude'] = longitude.toString();
      if (locationAccuracy != null) {
        req.fields['locationAccuracy'] = locationAccuracy.toString();
      }

      if (photo != null) {
        final file = File(photo!.path);
        req.files.add(await http.MultipartFile.fromPath('photo', file.path));
      }

      final streamed = await req.send();
      final resp = await http.Response.fromStream(streamed);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        reset();
        return null;
      }
      print(resp.body);
      return 'Failed to submit dormant survey';
      
      
    } catch (e) {
      print(e);
      return 'Failed to submit dormant survey';
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  void reset() {
    scheme = '';
    zone = '';
    route = '';
    selectedAccount = null;
    accountSearchQuery = '';
    sourceOfWater = '';
    detailsMatch = null;
    willingToRegularize = null;
    currentAccountNumber = '';
    currentMeterNumber = '';
    currentUserIsRegisteredCustomer = null;
    requiresInvestigation = null;
    investigationReason = '';
    relationshipToAccountHolder = '';
    currentOccupantName = '';
    currentOccupantPhone = '';
    meterCondition = '';
    meterReading = '';
    generalCommentChoice = '';
    generalCommentOther = '';
    photo = null;
    latitude = null;
    longitude = null;
    locationAccuracy = null;
  }
}

