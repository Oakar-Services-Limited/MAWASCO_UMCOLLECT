import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:um_collect/components/Utils.dart';
import 'package:um_collect/models/meter_replacement_entry.dart';
import 'package:um_collect/services/connectivity_helper.dart';
import 'package:um_collect/services/database_helper.dart';
import 'package:um_collect/services/meter_replacement_list_service.dart';
import 'package:um_collect/services/offline_image_store.dart';

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

  // Normal operations — same dimensions as exercise list, entered manually
  String manualAccountNumber = '';
  String manualCustomerName = '';
  String manualMeterNumber = '';
  String manualCurrentRoute = '';
  String manualLastRecordedReading = '';
  String manualCategory = '';
  String manualAccountStatus = '';

  /// Mirrors common CSV values; technician can pick closest type.
  static const List<String> manualCategoryOptions = [
    'Domestic/Residential',
    'Commercial',
    'Institutions',
    'Industrial',
    'Other',
  ];

  static const List<String> manualAccountStatusOptions = [
    'Active',
    'Sealed',
    'Inactive',
    'Other',
  ];

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
  String? lastSubmitNotice;

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
    if (replacementSource == MeterReplacementSource.normalOperations) {
      final v = manualCustomerName.trim();
      return v.isEmpty ? null : v;
    }
    return null;
  }

  String? get displayMeterNumber {
    if (replacementSource == MeterReplacementSource.scheduledExercise) {
      final v = selectedExerciseEntry?.meterNumber.trim() ?? '';
      return v.isEmpty ? null : v;
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
    if (replacementSource == MeterReplacementSource.normalOperations) {
      final v = manualCurrentRoute.trim();
      return v.isEmpty ? null : v;
    }
    return null;
  }

  String? get displayLastReading {
    if (replacementSource == MeterReplacementSource.scheduledExercise) {
      return selectedExerciseEntry?.currentMeterReading;
    }
    if (replacementSource == MeterReplacementSource.normalOperations) {
      final v = manualLastRecordedReading.trim();
      return v.isEmpty ? null : v;
    }
    return null;
  }

  void setReplacementSource(MeterReplacementSource? value) {
    if (replacementSource == value) return;
    replacementSource = value;
    accountSearchQuery = '';
    selectedExerciseEntry = null;
    accountNotFound = false;
    manualAccountNumber = '';
    manualCustomerName = '';
    manualMeterNumber = '';
    manualCurrentRoute = '';
    manualLastRecordedReading = '';
    manualCategory = '';
    manualAccountStatus = '';
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

  void setManualAccountNumber(String v) {
    manualAccountNumber = v;
    notifyListeners();
  }

  void setManualCustomerName(String v) {
    manualCustomerName = v;
    notifyListeners();
  }

  void setManualCurrentRoute(String v) {
    manualCurrentRoute = v;
    notifyListeners();
  }

  void setManualLastRecordedReading(String v) {
    manualLastRecordedReading = v;
    notifyListeners();
  }

  void setManualCategory(String v) {
    manualCategory = v;
    notifyListeners();
  }

  void setManualAccountStatus(String v) {
    manualAccountStatus = v;
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
    required String persistLabel,
  }) async {
    try {
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (!status.isGranted) return;
      }
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      if (picked == null) return;
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final saved = await OfflineImageStore.persistFromFile(
        sourcePath: picked.path,
        submissionId: 'meter_rep_${persistLabel}_$id',
      );
      assign(XFile(saved ?? picked.path));
      notifyListeners();
    } on Exception catch (e) {
      if (kDebugMode) debugPrint('[MeterReplacement._pickImage] $e');
    }
  }

  Future<void> capturePhotoIssue() => _pickImage(
        source: ImageSource.camera,
        assign: (f) => photoIssue = f,
        persistLabel: 'issue',
      );

  Future<void> pickPhotoIssueFromGallery() => _pickImage(
        source: ImageSource.gallery,
        assign: (f) => photoIssue = f,
        persistLabel: 'issue',
      );

  void clearPhotoIssue() {
    photoIssue = null;
    notifyListeners();
  }

  Future<void> capturePhotoMeterRemoved() => _pickImage(
        source: ImageSource.camera,
        assign: (f) => photoMeterRemoved = f,
        persistLabel: 'removed',
      );

  Future<void> pickPhotoMeterRemovedFromGallery() => _pickImage(
        source: ImageSource.gallery,
        assign: (f) => photoMeterRemoved = f,
        persistLabel: 'removed',
      );

  void clearPhotoMeterRemoved() {
    photoMeterRemoved = null;
    notifyListeners();
  }

  Future<void> capturePhotoNewMeter() => _pickImage(
        source: ImageSource.camera,
        assign: (f) => photoNewMeter = f,
        persistLabel: 'new',
      );

  Future<void> pickPhotoNewMeterFromGallery() => _pickImage(
        source: ImageSource.gallery,
        assign: (f) => photoNewMeter = f,
        persistLabel: 'new',
      );

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
      if (manualAccountNumber.trim().isEmpty) {
        return 'Enter the account number';
      }
      if (manualCustomerName.trim().isEmpty) {
        return 'Enter the customer name';
      }
      // meter number optional — submit null/omit when not available
      if (manualCurrentRoute.trim().isEmpty) {
        return 'Enter the current route';
      }
      if (manualLastRecordedReading.trim().isEmpty) {
        return 'Enter the last recorded reading';
      }
      if (manualCategory.isEmpty || manualCategory == '--Select--') {
        return 'Select customer category';
      }
      if (manualAccountStatus.isEmpty || manualAccountStatus == '--Select--') {
        return 'Select account status';
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

      if (replacementSource == MeterReplacementSource.scheduledExercise ||
          replacementSource == MeterReplacementSource.normalOperations) {
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

  Map<String, String> _buildSubmitFields() {
    final fields = <String, String>{
      'replacementSource':
          replacementSource == MeterReplacementSource.scheduledExercise
              ? 'scheduled_exercise'
              : 'normal_operations',
      'zone': zone,
      'technicianName': technicianName,
      'canBeReplaced': canBeReplaced == true ? 'true' : 'false',
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
    };

    if (replacementSource == MeterReplacementSource.scheduledExercise) {
      final e = selectedExerciseEntry!;
      fields['accountNumber'] = e.accountNumber;
      fields['customerName'] = e.customerName;
      final meter = e.meterNumber.trim();
      if (meter.isNotEmpty) fields['meterNumber'] = meter;
      fields['currentRoute'] = e.route;
      fields['lastRecordedReading'] = e.currentMeterReading;
      fields['category'] = e.category;
      fields['accountStatus'] = e.accountStatus;
    } else {
      fields['accountNumber'] = manualAccountNumber.trim();
      fields['customerName'] = manualCustomerName.trim();
      final meter = manualMeterNumber.trim();
      if (meter.isNotEmpty) fields['meterNumber'] = meter;
      fields['currentRoute'] = manualCurrentRoute.trim();
      fields['lastRecordedReading'] = manualLastRecordedReading.trim();
      fields['category'] = manualCategory.trim();
      fields['accountStatus'] = manualAccountStatus.trim();
    }

    if (canBeReplaced == false) {
      fields['notReplaceableReason'] = notReplaceableReason;
      if (notReplaceableReason == notReplaceableOtherLabel) {
        fields['notReplaceableOtherReason'] = notReplaceableOtherReason.trim();
      }
    } else {
      fields['readingMeterRemoved'] = readingMeterRemoved.trim();
      fields['confirmRemovedSerial'] = confirmRemovedSerial.trim();
      fields['newMeterSerial'] = newMeterSerial.trim();
      fields['initialNewMeterReading'] = initialNewMeterReading.trim();
      fields['routeIsCorrect'] = routeIsCorrect == true ? 'true' : 'false';
      if (routeIsCorrect == false) {
        fields['correctedRoute'] = correctedRoute;
      }
    }

    if (altitude != null) fields['altitude'] = altitude.toString();
    if (locationAccuracy != null) {
      fields['locationAccuracy'] = locationAccuracy.toString();
    }
    if (additionalNotes.trim().isNotEmpty) {
      fields['additionalNotes'] = additionalNotes.trim();
    }
    return fields;
  }

  Future<void> _addPhotoPath({
    required Map<String, dynamic> body,
    required String bodyKey,
    required XFile? photo,
    required String submissionId,
    required String suffix,
  }) async {
    if (photo == null) return;
    final saved = await OfflineImageStore.persistFromFile(
      sourcePath: photo.path,
      submissionId: '${submissionId}_$suffix',
    );
    if (saved != null) {
      body[bodyKey] = saved;
    }
  }

  Future<String?> _ensureDurablePhotoPath({
    required XFile? photo,
    required String persistLabel,
  }) async {
    if (photo == null) return null;
    final existing = File(photo.path);
    if (await existing.exists()) return photo.path;

    final saved = await OfflineImageStore.persistFromFile(
      sourcePath: photo.path,
      submissionId: 'meter_rep_${persistLabel}_${DateTime.now().millisecondsSinceEpoch}',
    );
    return saved;
  }

  String _formatSubmitError(http.Response resp) {
    try {
      final data = json.decode(resp.body);
      if (data is Map) {
        final err = data['error'] ?? data['message'];
        if (err != null && err.toString().trim().isNotEmpty) {
          return err.toString();
        }
      }
    } catch (_) {}
    final body = resp.body.trim();
    if (body.isNotEmpty && body.length <= 240) return body;
    return 'Failed to submit meter replacement (${resp.statusCode})';
  }

  Future<void> _attachPhotosToRequest(http.MultipartRequest req) async {
    Future<void> attach(
      String fieldName,
      XFile? photo,
      String persistLabel,
    ) async {
      if (photo == null) {
        throw StateError('$fieldName is missing');
      }
      final path = await _ensureDurablePhotoPath(
        photo: photo,
        persistLabel: persistLabel,
      );
      if (path == null) {
        throw StateError(
          '$fieldName file is missing. Please capture the photo again.',
        );
      }
      if (kDebugMode) {
        debugPrint(
          '[MeterReplacement.submit] attach $fieldName path=$path exists=${await File(path).exists()}',
        );
      }
      req.files.add(await http.MultipartFile.fromPath(fieldName, path));
    }

    if (canBeReplaced == false) {
      await attach('photoIssue', photoIssue, 'issue');
      return;
    }

    await attach('photoMeterRemoved', photoMeterRemoved, 'removed');
    await attach('photoNewMeter', photoNewMeter, 'new');
  }

  Future<String?> _queueOffline() async {
    final submissionId = DateTime.now().millisecondsSinceEpoch.toString();
    final body = Map<String, dynamic>.from(_buildSubmitFields());

    if (canBeReplaced == false) {
      await _addPhotoPath(
        body: body,
        bodyKey: 'photoIssuePath',
        photo: photoIssue,
        submissionId: submissionId,
        suffix: 'issue',
      );
    } else {
      await _addPhotoPath(
        body: body,
        bodyKey: 'photoMeterRemovedPath',
        photo: photoMeterRemoved,
        submissionId: submissionId,
        suffix: 'removed',
      );
      await _addPhotoPath(
        body: body,
        bodyKey: 'photoNewMeterPath',
        photo: photoNewMeter,
        submissionId: submissionId,
        suffix: 'new',
      );
    }

    await DatabaseHelper().saveSubmission(
      id: submissionId,
      formId: 'meter_replacement',
      formName: 'Meter Replacement',
      responses: {
        '_type': 'meter_replacement',
        '_endpoint': 'meter-replacement/with-media',
        '_method': 'POST',
        '_multipart': true,
        '_body': body,
      },
    );

    final expectedPhotos = canBeReplaced == false ? 1 : 2;
    final savedPhotos = body.keys
        .where((k) => k.endsWith('Path') && body[k] != null)
        .length;
    lastSubmitNotice = savedPhotos >= expectedPhotos
        ? 'Saved offline with photos. Will sync when you have internet.'
        : savedPhotos > 0
            ? 'Saved offline with some photos. Will sync when you have internet.'
            : 'Saved offline but photos could not be stored. Will sync without photos.';
    reset();
    return null;
  }

  Future<String?> _submitOnline(String token) async {
    final uri = Uri.parse('${getUrl()}meter-replacement/with-media');
    final req = http.MultipartRequest('POST', uri);
    req.headers['Authorization'] = 'Bearer $token';
    req.fields.addAll(_buildSubmitFields());
    await _attachPhotosToRequest(req);

    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      lastSubmitNotice = null;
      reset();
      return null;
    }
    if (kDebugMode) {
      debugPrint('[MeterReplacement.submit] ${resp.statusCode} ${resp.body}');
    }
    return _formatSubmitError(resp);
  }

  bool _isNetworkError(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('socketexception') ||
        msg.contains('network is unreachable') ||
        msg.contains('connection failed') ||
        msg.contains('failed host lookup') ||
        msg.contains('connection refused') ||
        msg.contains('timed out');
  }

  Future<String?> submit() async {
    final err = validate();
    if (err != null) return err;

    isSubmitting = true;
    lastSubmitNotice = null;
    notifyListeners();
    try {
      final token = await _storage.read(key: 'mwstaffjwt');
      if (token == null || token.isEmpty) return 'Not authenticated';

      final isOnline = await ConnectivityHelper().checkConnectivity();
      if (!isOnline) {
        return await _queueOffline();
      }

      try {
        return await _submitOnline(token);
      } catch (e) {
        if (_isNetworkError(e)) {
          return await _queueOffline();
        }
        if (e is StateError) return e.message;
        rethrow;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[MeterReplacement.submit] $e');
      if (_isNetworkError(e)) {
        return await _queueOffline();
      }
      if (e is StateError) return e.message;
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
    manualAccountNumber = '';
    manualCustomerName = '';
    manualMeterNumber = '';
    manualCurrentRoute = '';
    manualLastRecordedReading = '';
    manualCategory = '';
    manualAccountStatus = '';
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
