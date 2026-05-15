import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:um_collect/components/Utils.dart';
import 'package:um_collect/models/meter_replacement_entry.dart';
import 'package:um_collect/services/meter_replacement_list_service.dart';

enum MeterReplacementSource {
  scheduledExercise,
  normalOperations,
}

class MeterReplacementController extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  final _list = MeterReplacementListService.instance;
  final _imagePicker = ImagePicker();

  bool isLoadingList = true;
  String? loadError;

  String technicianName = '';

  /// Scheduled exercise list vs ad-hoc normal operations.
  MeterReplacementSource? replacementSource;

  // Exercise list lookup
  String accountSearchQuery = '';
  MeterReplacementEntry? selectedExerciseEntry;
  bool accountNotFound = false;

  // Normal operations — manual meter number only
  String manualMeterNumber = '';

  String zone = '';

  // Replaceability
  bool? canBeReplaced;

  static const String notReplaceableOtherLabel = 'Other (Please Specify)';

  static const List<String> notReplaceableReasons = [
    'Cemented - In a Chamber',
    'Cemented - Requires Meter Raising',
    'Limited Space',
    'Access Denied by Owner',
    'Gate Locked',
    'Locked Chamber - Needs Owner Access',
    'Locked Chamber - Limited Space',
    'Meter Buried - Requires Raising',
    notReplaceableOtherLabel,
  ];

  String notReplaceableReason = '';
  String notReplaceableOtherReason = '';
  XFile? photoIssue;

  // Meter being removed
  XFile? photoMeterRemoved;
  String readingMeterRemoved = '';
  String confirmRemovedSerial = '';

  // New meter
  String newMeterSerial = '';
  XFile? photoNewMeter;
  String initialNewMeterReading = '';

  // Location
  double? latitude;
  double? longitude;
  double? altitude;
  double? locationAccuracy;

  // Route verification
  bool? routeIsCorrect;
  String correctedRoute = '';

  String additionalNotes = '';

  bool isSubmitting = false;

  Future<void> init() async {
    try {
      isLoadingList = true;
      loadError = null;
      notifyListeners();
      await _list.ensureLoaded();
      await _loadTechnicianName();
    } catch (e) {
      loadError = 'Failed to load replacement exercise list';
      if (kDebugMode) debugPrint('[MeterReplacement.init] $e');
    } finally {
      isLoadingList = false;
      notifyListeners();
    }
  }

  Future<void> _loadTechnicianName() async {
    final token = await _storage.read(key: 'mwstaffjwt');
    if (token == null || token.isEmpty) return;
    final decoded = parseJwt(token);
    technicianName = (decoded['name'] ??
            decoded['Name'] ??
            decoded['fullName'] ??
            decoded['FullName'] ??
            '')
        .toString()
        .trim();
  }

  List<String> get zoneOptions {
    return getZones().where((z) => z != '--Select--').toList();
  }

  List<String> get routeOptions => _list.routes;

  String? get displayCustomerName {
    if (replacementSource == MeterReplacementSource.scheduledExercise) {
      return selectedExerciseEntry?.customerName;
    }
    return null;
  }

  String? get displayMeterNumber {
    if (replacementSource == MeterReplacementSource.scheduledExercise) {
      return selectedExerciseEntry?.meterNumber;
    }
    if (replacementSource == MeterReplacementSource.normalOperations) {
      return manualMeterNumber.trim().isEmpty ? null : manualMeterNumber.trim();
    }
    return null;
  }

  String? get displayCurrentRoute {
    if (replacementSource == MeterReplacementSource.scheduledExercise) {
      return selectedExerciseEntry?.route;
    }
    return null;
  }

  String? get displayLastReading {
    if (replacementSource == MeterReplacementSource.scheduledExercise) {
      return selectedExerciseEntry?.currentMeterReading;
    }
    return null;
  }

  void setReplacementSource(MeterReplacementSource? value) {
    if (replacementSource == value) return;
    replacementSource = value;
    accountSearchQuery = '';
    selectedExerciseEntry = null;
    accountNotFound = false;
    manualMeterNumber = '';
    canBeReplaced = null;
    _clearReplaceabilityDetails();
    _clearReplacementWork();
    notifyListeners();
  }

  void setAccountSearchQuery(String v) {
    accountSearchQuery = v;
    accountNotFound = false;
    notifyListeners();
  }

  void lookupAccountByNumber() {
    if (replacementSource != MeterReplacementSource.scheduledExercise) return;
    final entry = _list.findByAccountNumber(accountSearchQuery);
    selectedExerciseEntry = entry;
    accountNotFound = entry == null && accountSearchQuery.trim().isNotEmpty;
    notifyListeners();
  }

  void selectExerciseEntry(MeterReplacementEntry? entry) {
    selectedExerciseEntry = entry;
    accountNotFound = false;
    if (entry != null) {
      accountSearchQuery = entry.accountNumber;
    }
    notifyListeners();
  }

  List<MeterReplacementEntry> exerciseSearchResults() {
    if (replacementSource != MeterReplacementSource.scheduledExercise) {
      return const [];
    }
    return _list.searchAccounts(accountSearchQuery);
  }

  void setManualMeterNumber(String v) {
    manualMeterNumber = v;
    notifyListeners();
  }

  void setZone(String v) {
    if (zone == v) return;
    zone = v;
    notifyListeners();
  }

  void setCanBeReplaced(bool? v) {
    if (canBeReplaced == v) return;
    canBeReplaced = v;
    _clearReplaceabilityDetails();
    if (v == true) _clearNotReplaceableOnly();
    if (v == false) _clearReplacementWork();
    notifyListeners();
  }

  void setNotReplaceableReason(String v) {
    notReplaceableReason = v;
    if (v != notReplaceableOtherLabel) {
      notReplaceableOtherReason = '';
    }
    notifyListeners();
  }

  void setNotReplaceableOtherReason(String v) {
    notReplaceableOtherReason = v;
    notifyListeners();
  }

  void setReadingMeterRemoved(String v) {
    readingMeterRemoved = v;
    notifyListeners();
  }

  void setConfirmRemovedSerial(String v) {
    confirmRemovedSerial = v;
    notifyListeners();
  }

  void setNewMeterSerial(String v) {
    newMeterSerial = v;
    notifyListeners();
  }

  void setInitialNewMeterReading(String v) {
    initialNewMeterReading = v;
    notifyListeners();
  }

  void setRouteIsCorrect(bool? v) {
    routeIsCorrect = v;
    if (v == true) correctedRoute = '';
    notifyListeners();
  }

  void setCorrectedRoute(String v) {
    correctedRoute = v;
    notifyListeners();
  }

  void setAdditionalNotes(String v) {
    additionalNotes = v;
    notifyListeners();
  }

  Future<void> _pickImage({
    required ImageSource source,
    required void Function(XFile?) assign,
  }) async {
    try {
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (!status.isGranted) return;
      }
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );
      assign(file);
      notifyListeners();
    } on Exception catch (e) {
      if (kDebugMode) debugPrint('[MeterReplacement._pickImage] $e');
    }
  }

  Future<void> capturePhotoIssue() =>
      _pickImage(source: ImageSource.camera, assign: (f) => photoIssue = f);

  Future<void> pickPhotoIssueFromGallery() =>
      _pickImage(source: ImageSource.gallery, assign: (f) => photoIssue = f);

  void clearPhotoIssue() {
    photoIssue = null;
    notifyListeners();
  }

  Future<void> capturePhotoMeterRemoved() => _pickImage(
        source: ImageSource.camera,
        assign: (f) => photoMeterRemoved = f,
      );

  Future<void> pickPhotoMeterRemovedFromGallery() => _pickImage(
        source: ImageSource.gallery,
        assign: (f) => photoMeterRemoved = f,
      );

  void clearPhotoMeterRemoved() {
    photoMeterRemoved = null;
    notifyListeners();
  }

  Future<void> capturePhotoNewMeter() =>
      _pickImage(source: ImageSource.camera, assign: (f) => photoNewMeter = f);

  Future<void> pickPhotoNewMeterFromGallery() =>
      _pickImage(source: ImageSource.gallery, assign: (f) => photoNewMeter = f);

  void clearPhotoNewMeter() {
    photoNewMeter = null;
    notifyListeners();
  }

  void setCapturedLocation({
    required double lat,
    required double lng,
    required double accuracy,
    double? alt,
  }) {
    latitude = lat;
    longitude = lng;
    locationAccuracy = accuracy;
    altitude = alt;
    notifyListeners();
  }

  void clearLocation() {
    latitude = null;
    longitude = null;
    altitude = null;
    locationAccuracy = null;
    notifyListeners();
  }

  void _clearNotReplaceableOnly() {
    notReplaceableReason = '';
    notReplaceableOtherReason = '';
    photoIssue = null;
  }

  void _clearReplacementWork() {
    photoMeterRemoved = null;
    readingMeterRemoved = '';
    confirmRemovedSerial = '';
    newMeterSerial = '';
    photoNewMeter = null;
    initialNewMeterReading = '';
    routeIsCorrect = null;
    correctedRoute = '';
  }

  void _clearReplaceabilityDetails() {
    _clearNotReplaceableOnly();
    _clearReplacementWork();
  }

  String? validate() {
    if (replacementSource == null) {
      return 'Indicate whether this is a scheduled exercise or normal operations replacement';
    }

    if (replacementSource == MeterReplacementSource.scheduledExercise) {
      if (selectedExerciseEntry == null) {
        return accountNotFound
            ? 'Account number not found in the replacement list'
            : 'Search and select an account from the replacement list';
      }
    } else {
      if (manualMeterNumber.trim().isEmpty) {
        return 'Enter the meter number';
      }
    }

    if (zone.isEmpty || zone == '--Select--') {
      return 'Select zone';
    }

    if (technicianName.trim().isEmpty) {
      return 'Technician name could not be loaded — sign in again';
    }

    if (canBeReplaced == null) {
      return 'Indicate whether the meter can be replaced';
    }

    if (canBeReplaced == false) {
      if (notReplaceableReason.isEmpty) {
        return 'Select the reason the meter cannot be replaced';
      }
      if (notReplaceableReason == notReplaceableOtherLabel &&
          notReplaceableOtherReason.trim().isEmpty) {
        return 'Specify the other reason';
      }
      if (photoIssue == null) {
        return 'Take a photo showing why replacement is not possible';
      }
    } else {
      if (photoMeterRemoved == null) {
        return 'Take a photo of the meter being removed';
      }
      if (readingMeterRemoved.trim().isEmpty) {
        return 'Enter the reading of the meter being removed';
      }
      if (confirmRemovedSerial.trim().isEmpty) {
        return 'Confirm the meter serial number being removed';
      }
      if (newMeterSerial.trim().isEmpty) {
        return 'Enter the new meter serial number';
      }
      if (photoNewMeter == null) {
        return 'Take a photo of the new meter installed';
      }
      if (initialNewMeterReading.trim().isEmpty) {
        return 'Enter the initial reading of the new meter';
      }

      if (replacementSource == MeterReplacementSource.scheduledExercise) {
        if (routeIsCorrect == null) {
          return 'Indicate whether the current route is correct';
        }
        if (routeIsCorrect == false &&
            (correctedRoute.isEmpty || correctedRoute == '--Select--')) {
          return 'Select the correct route';
        }
      }
    }

    if (latitude == null || longitude == null) {
      return 'Capture GPS location';
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

      final uri = Uri.parse('${getUrl()}meter-replacement/with-media');
      final req = http.MultipartRequest('POST', uri);
      req.headers['Authorization'] = 'Bearer $token';

      req.fields['replacementSource'] =
          replacementSource == MeterReplacementSource.scheduledExercise
              ? 'scheduled_exercise'
              : 'normal_operations';
      req.fields['zone'] = zone;
      req.fields['technicianName'] = technicianName;

      if (replacementSource == MeterReplacementSource.scheduledExercise) {
        final e = selectedExerciseEntry!;
        req.fields['accountNumber'] = e.accountNumber;
        req.fields['customerName'] = e.customerName;
        req.fields['meterNumber'] = e.meterNumber;
        req.fields['currentRoute'] = e.route;
        req.fields['lastRecordedReading'] = e.currentMeterReading;
        req.fields['category'] = e.category;
        req.fields['accountStatus'] = e.accountStatus;
      } else {
        req.fields['meterNumber'] = manualMeterNumber.trim();
      }

      req.fields['canBeReplaced'] = canBeReplaced == true ? 'true' : 'false';

      if (canBeReplaced == false) {
        req.fields['notReplaceableReason'] = notReplaceableReason;
        if (notReplaceableReason == notReplaceableOtherLabel) {
          req.fields['notReplaceableOtherReason'] =
              notReplaceableOtherReason.trim();
        }
        req.files.add(await http.MultipartFile.fromPath(
          'photoIssue',
          File(photoIssue!.path).path,
        ));
      } else {
        req.fields['readingMeterRemoved'] = readingMeterRemoved.trim();
        req.fields['confirmRemovedSerial'] = confirmRemovedSerial.trim();
        req.fields['newMeterSerial'] = newMeterSerial.trim();
        req.fields['initialNewMeterReading'] = initialNewMeterReading.trim();

        if (replacementSource == MeterReplacementSource.scheduledExercise) {
          req.fields['routeIsCorrect'] = routeIsCorrect == true ? 'true' : 'false';
          if (routeIsCorrect == false) {
            req.fields['correctedRoute'] = correctedRoute;
          }
        }

        req.files.add(await http.MultipartFile.fromPath(
          'photoMeterRemoved',
          File(photoMeterRemoved!.path).path,
        ));
        req.files.add(await http.MultipartFile.fromPath(
          'photoNewMeter',
          File(photoNewMeter!.path).path,
        ));
      }

      req.fields['latitude'] = latitude.toString();
      req.fields['longitude'] = longitude.toString();
      if (altitude != null) req.fields['altitude'] = altitude.toString();
      if (locationAccuracy != null) {
        req.fields['locationAccuracy'] = locationAccuracy.toString();
      }
      if (additionalNotes.trim().isNotEmpty) {
        req.fields['additionalNotes'] = additionalNotes.trim();
      }

      final streamed = await req.send();
      final resp = await http.Response.fromStream(streamed);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        reset();
        return null;
      }
      if (kDebugMode) debugPrint('[MeterReplacement.submit] ${resp.statusCode} ${resp.body}');
      return 'Failed to submit meter replacement (${resp.statusCode})';
    } catch (e) {
      if (kDebugMode) debugPrint('[MeterReplacement.submit] $e');
      return 'Failed to submit meter replacement';
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  void reset() {
    replacementSource = null;
    accountSearchQuery = '';
    selectedExerciseEntry = null;
    accountNotFound = false;
    manualMeterNumber = '';
    zone = '';
    canBeReplaced = null;
    _clearReplaceabilityDetails();
    additionalNotes = '';
    latitude = null;
    longitude = null;
    altitude = null;
    locationAccuracy = null;
  }
}
