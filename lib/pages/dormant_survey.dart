import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:um_collect/controllers/dormant_survey_controller.dart';
import 'package:um_collect/models/Map.dart';
import 'package:um_collect/services/customer_db_service.dart';
import 'package:um_collect/theme/app_theme.dart';

class DormantSurveyPage extends StatelessWidget {
  const DormantSurveyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DormantSurveyController()..init(),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'Dormant Survey',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: AppTheme.primaryMain,
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        body: const SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: _DormantSurveyForm(),
        ),
      ),
    );
  }
}

class _DormantSurveyForm extends StatelessWidget {
  const _DormantSurveyForm();

  static const double _requiredAccuracyMeters = 5.0;

  @override
  Widget build(BuildContext context) {
    return Consumer<DormantSurveyController>(
      builder: (context, ctrl, _) {
        if (ctrl.isLoadingDb) {
          return const Center(child: CircularProgressIndicator());
        }
        if (ctrl.dbError != null) {
          return Text(ctrl.dbError!, style: TextStyle(color: Colors.red[700]));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionTitle('A. Account search'),
            const SizedBox(height: 8),
            _schemeDropdown(ctrl),
            const SizedBox(height: 12),
            _zoneDropdown(ctrl),
            const SizedBox(height: 12),
            _routeDropdown(ctrl),
            const SizedBox(height: 12),
            _accountSearch(context, ctrl),
            const SizedBox(height: 24),
            _sectionTitle('B. Ground verification'),
            const SizedBox(height: 8),
            _dropdown(
              label: 'Source of Water *',
              hint: 'If not using MAWASCO, where do they get it?',
              value: ctrl.sourceOfWater.isEmpty ? null : ctrl.sourceOfWater,
              items: DormantSurveyController.sourceOfWaterOptions,
              onChanged: (v) => ctrl.setSourceOfWater(v ?? ''),
            ),
            const SizedBox(height: 12),
            _boolChoice(
              title: 'Do system details and ground details match? *',
              subtitle: 'Yes = dormant/vacant',
              value: ctrl.detailsMatch,
              onChanged: ctrl.setDetailsMatch,
            ),
            if (ctrl.detailsMatch == true) ...[
              const SizedBox(height: 12),
              _dropdown(
                label: 'Is the customer willing to regularize? *',
                hint: 'Only ask if details match (dormant)',
                value: ctrl.willingToRegularize,
                items: DormantSurveyController.regularizeOptions,
                onChanged: ctrl.setWillingToRegularize,
              ),
              const SizedBox(height: 12),
              _boolChoice(
                title: 'Is the current user the registered customer? *',
                value: ctrl.currentUserIsRegisteredCustomer,
                onChanged: ctrl.setCurrentUserIsRegisteredCustomer,
              ),
              if (ctrl.currentUserIsRegisteredCustomer == false) ...[
                const SizedBox(height: 24),
                _sectionTitle('C. Occupants and usage'),
                const SizedBox(height: 8),
                _dropdown(
                  label: 'Relationship to Account Holder *',
                  hint: 'Select relationship',
                  value: ctrl.relationshipToAccountHolder.isEmpty
                      ? null
                      : ctrl.relationshipToAccountHolder,
                  items: DormantSurveyController.relationshipOptions,
                  onChanged: (v) =>
                      ctrl.setRelationshipToAccountHolder(v ?? ''),
                ),
                const SizedBox(height: 12),
                _textInput(
                  label: 'Current occupant name *',
                  value: ctrl.currentOccupantName,
                  onChanged: ctrl.setCurrentOccupantName,
                ),
                const SizedBox(height: 12),
                _textInput(
                  label: 'Current occupant phone *',
                  hint: '07**',
                  value: ctrl.currentOccupantPhone,
                  onChanged: ctrl.setCurrentOccupantPhone,
                  keyboardType: TextInputType.phone,
                ),
              ],
              if (ctrl.currentUserIsRegisteredCustomer != null) ...[
                const SizedBox(height: 12),
                _boolChoice(
                  title: 'Does this require investigation? *',
                  subtitle: 'Suspected bypass / spaghetti line?',
                  value: ctrl.requiresInvestigation,
                  onChanged: ctrl.setRequiresInvestigation,
                ),
                if (ctrl.requiresInvestigation == true) ...[
                  const SizedBox(height: 12),
                  _textInput(
                    label: 'Reason for investigation *',
                    hint: 'Explain specifically',
                    value: ctrl.investigationReason,
                    onChanged: ctrl.setInvestigationReason,
                    maxLines: 2,
                  ),
                ],
              ],
            ],
            if (ctrl.detailsMatch == false) ...[
              const SizedBox(height: 12),
              _textInput(
                label: 'Current account number *',
                hint: 'The account actually serving the house.',
                value: ctrl.currentAccountNumber,
                onChanged: ctrl.setCurrentAccountNumber,
              ),
              const SizedBox(height: 12),
              _textInput(
                label: 'Current meter number *',
                value: ctrl.currentMeterNumber,
                onChanged: ctrl.setCurrentMeterNumber,
              ),
              const SizedBox(height: 12),
              _boolChoice(
                title: 'Is the current user the registered customer? *',
                value: ctrl.currentUserIsRegisteredCustomer,
                onChanged: ctrl.setCurrentUserIsRegisteredCustomer,
              ),
              if (ctrl.currentUserIsRegisteredCustomer == false) ...[
                const SizedBox(height: 24),
                _sectionTitle('C. Occupants and usage'),
                const SizedBox(height: 8),
                _dropdown(
                  label: 'Relationship to Account Holder *',
                  hint: 'Select relationship',
                  value: ctrl.relationshipToAccountHolder.isEmpty
                      ? null
                      : ctrl.relationshipToAccountHolder,
                  items: DormantSurveyController.relationshipOptions,
                  onChanged: (v) =>
                      ctrl.setRelationshipToAccountHolder(v ?? ''),
                ),
                const SizedBox(height: 12),
                _textInput(
                  label: 'Current occupant name *',
                  value: ctrl.currentOccupantName,
                  onChanged: ctrl.setCurrentOccupantName,
                ),
                const SizedBox(height: 12),
                _textInput(
                  label: 'Current occupant phone *',
                  hint: '07**',
                  value: ctrl.currentOccupantPhone,
                  onChanged: ctrl.setCurrentOccupantPhone,
                  keyboardType: TextInputType.phone,
                ),
              ],
              if (ctrl.currentUserIsRegisteredCustomer != null) ...[
                const SizedBox(height: 12),
                _boolChoice(
                  title: 'Does this require investigation? *',
                  subtitle: 'Suspected bypass / spaghetti line?',
                  value: ctrl.requiresInvestigation,
                  onChanged: ctrl.setRequiresInvestigation,
                ),
                if (ctrl.requiresInvestigation == true) ...[
                  const SizedBox(height: 12),
                  _textInput(
                    label: 'Reason for investigation *',
                    hint: 'Explain specifically',
                    value: ctrl.investigationReason,
                    onChanged: ctrl.setInvestigationReason,
                    maxLines: 2,
                  ),
                ],
              ],
            ],
            const SizedBox(height: 24),
            _sectionTitle('D. Meter condition'),
            const SizedBox(height: 8),
            _dropdown(
              label: 'Meter condition *',
              hint: 'Select “No Meter” if direct connection.',
              value: ctrl.meterCondition.isEmpty ? null : ctrl.meterCondition,
              items: DormantSurveyController.meterConditions,
              onChanged: (v) => ctrl.setMeterCondition(v ?? ''),
            ),
            const SizedBox(height: 12),
            if (ctrl.meterCondition.isNotEmpty &&
                ctrl.meterCondition != 'No Meter (Direct)' &&
                ctrl.meterCondition != 'Disconnected (Meter Removed)' &&
                ctrl.meterCondition != 'Buried / Covered(inaccessible)')
              _textInput(
                label: 'Enter meter reading *',
                hint: 'Enter reading even if illegible (estimate/0)',
                value: ctrl.meterReading,
                onChanged: ctrl.setMeterReading,
                keyboardType: TextInputType.number,
              ),
            const SizedBox(height: 12),
            _locationSection(context, ctrl),
            const SizedBox(height: 12),
            _photoSection(ctrl),
            const SizedBox(height: 12),
            _sectionTitle('E. General comments'),
            const SizedBox(height: 8),
            _dropdown(
              label: 'General comments *',
              hint: 'Select one option',
              value: ctrl.generalCommentChoice.isEmpty
                  ? null
                  : ctrl.generalCommentChoice,
              items: DormantSurveyController.generalCommentOptions,
              onChanged: (v) => ctrl.setGeneralCommentChoice(v ?? ''),
            ),
            if (ctrl.generalCommentChoice ==
                DormantSurveyController.generalCommentOtherLabel) ...[
              const SizedBox(height: 12),
              _textInput(
                label: 'Other (specify) *',
                hint: 'Type your comment',
                value: ctrl.generalCommentOther,
                onChanged: ctrl.setGeneralCommentOther,
                maxLines: 2,
              ),
            ],
            const SizedBox(height: 24),
            _submitButton(context, ctrl),
          ],
        );
      },
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xff0288D1),
      ),
    );
  }

  Widget _cardWrap(Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xff0288D1).withValues(alpha: 0.1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: child,
    );
  }

  Widget _schemeDropdown(DormantSurveyController ctrl) {
    return _dropdown(
      label: 'Scheme *',
      hint: 'Select scheme',
      value: ctrl.scheme.isEmpty ? null : ctrl.scheme,
      items: DormantSurveyController.schemes,
      onChanged: (v) => ctrl.setScheme(v ?? ''),
    );
  }

  Widget _zoneDropdown(DormantSurveyController ctrl) {
    final zones = ctrl.zonesForSelectedScheme();
    return _dropdown(
      label: 'Zone *',
      hint: ctrl.scheme.isEmpty ? 'Select scheme first' : 'Select zone',
      value: ctrl.zone.isEmpty ? null : ctrl.zone,
      items: zones,
      onChanged: ctrl.scheme.isEmpty ? null : (v) => ctrl.setZone(v ?? ''),
    );
  }

  Widget _routeDropdown(DormantSurveyController ctrl) {
    final routes = ctrl.routesForSelectedZone();
    return _dropdown(
      label: 'Route *',
      hint: ctrl.zone.isEmpty ? 'Select zone first' : 'Select route',
      value: ctrl.route.isEmpty ? null : ctrl.route,
      items: routes,
      onChanged: ctrl.zone.isEmpty ? null : (v) => ctrl.setRoute(v ?? ''),
    );
  }

  Widget _accountSearch(BuildContext context, DormantSurveyController ctrl) {
    final enabled =
        ctrl.scheme.isNotEmpty && ctrl.zone.isNotEmpty && ctrl.route.isNotEmpty;
    final options = enabled ? ctrl.accountOptions() : const <CustomerDbEntry>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _textInput(
          label: 'Search account (name/account no)',
          hint: 'Type to filter',
          value: ctrl.accountSearchQuery,
          onChanged: ctrl.setAccountSearchQuery,
          enabled: enabled,
        ),
        const SizedBox(height: 12),
        _cardWrap(
          DropdownButtonHideUnderline(
            child: DropdownButton<CustomerDbEntry>(
              isExpanded: true,
              value: ctrl.selectedAccount,
              hint: Text(enabled
                  ? 'Select account'
                  : 'Select scheme, zone and route first'),
              items: options
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.label.isNotEmpty
                            ? e.label
                            : '${e.connectionNumber} - ${e.customerName}'),
                      ))
                  .toList(),
              onChanged: !enabled
                  ? null
                  : (v) async {
                      if (v == null) {
                        ctrl.setAccount(null);
                        return;
                      }
                      final exists =
                          await ctrl.isDormantNameAlreadySubmitted(v.customerName);
                      if (!context.mounted) return;
                      if (exists) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Dormant Account already submitted'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 3),
                          ),
                        );
                        // Do not set this account.
                        return;
                      }
                      ctrl.setAccount(v);
                    },
            ),
          ),
        ),
        if (ctrl.selectedAccount != null) ...[
          const SizedBox(height: 10),
          _cardWrap(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System info',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 6),
                Text('Name: ${ctrl.selectedAccount!.customerName}'),
                Text('Account: ${ctrl.selectedAccount!.connectionNumber}'),
                Text('Meter (system): ${ctrl.selectedAccount!.meterNo}'),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _dropdown({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return _cardWrap(
      DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(hint),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _textInput({
    required String label,
    String? hint,
    required String value,
    required ValueChanged<String> onChanged,
    bool enabled = true,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final controller = TextEditingController(text: value);
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );
    return TextField(
      enabled: enabled,
      controller: controller,
      onChanged: onChanged,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xff0288D1)),
        ),
      ),
    );
  }

  Widget _boolChoice({
    required String title,
    String? subtitle,
    required bool? value,
    required ValueChanged<bool?> onChanged,
  }) {
    return _cardWrap(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: RadioListTile<bool>(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Yes'),
                  value: true,
                  groupValue: value,
                  onChanged: onChanged,
                  activeColor: AppTheme.primaryMain,
                ),
              ),
              Expanded(
                child: RadioListTile<bool>(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('No'),
                  value: false,
                  groupValue: value,
                  onChanged: onChanged,
                  activeColor: AppTheme.primaryMain,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _locationSection(BuildContext context, DormantSurveyController ctrl) {
    final hasLocation = ctrl.latitude != null && ctrl.longitude != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xff0288D1).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Capture GPS location *',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _LiveLocationMapPreview(
            savedLat: ctrl.latitude,
            savedLng: ctrl.longitude,
            savedAcc: ctrl.locationAccuracy,
          ),
          const SizedBox(height: 10),
          if (hasLocation)
            Text(
              'Lat: ${ctrl.latitude!.toStringAsFixed(6)}, Lng: ${ctrl.longitude!.toStringAsFixed(6)}'
              '${ctrl.locationAccuracy != null ? ' (±${ctrl.locationAccuracy!.toStringAsFixed(0)}m)' : ''}',
              style: TextStyle(color: Colors.grey[800]),
            )
          else
            Text('No location captured',
                style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openGpsCaptureDialog(context, ctrl),
                  icon: const Icon(Icons.my_location, size: 18),
                  label: const Text('Capture GPS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0288D1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: hasLocation ? ctrl.clearLocation : null,
                icon: const Icon(Icons.delete_outline),
                color: Colors.red[700],
                tooltip: 'Clear location',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openGpsCaptureDialog(
    BuildContext context,
    DormantSurveyController ctrl,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _GpsCaptureDialog(
          requiredAccuracyMeters: _requiredAccuracyMeters,
          initialLat: ctrl.latitude,
          initialLng: ctrl.longitude,
          onSave: (p) {
            ctrl.setCapturedLocation(
              lat: p.latitude,
              lng: p.longitude,
              accuracy: p.accuracy,
            );
            Navigator.of(dialogContext).pop();
          },
          onCancel: () => Navigator.of(dialogContext).pop(),
        );
      },
    );
  }

  Widget _photoSection(DormantSurveyController ctrl) {
    final hasPhoto = ctrl.photo != null;
    final needsPhoto = ctrl.meterCondition == 'Disconnected';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xff0288D1).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Capture photo${needsPhoto ? ' *' : ' (optional)'}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (hasPhoto)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(ctrl.photo!.path),
                height: 180,
                fit: BoxFit.cover,
              ),
            )
          else
            Text('No photo captured',
                style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => ctrl.capturePhoto(),
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: Text(hasPhoto ? 'Retake photo' : 'Capture photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0288D1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ctrl.pickPhotoFromGallery(),
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Choose file'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xff0288D1),
                    side: const BorderSide(color: Color(0xff0288D1)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          if (hasPhoto)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: ctrl.clearPhoto,
                icon: Icon(Icons.delete_outline, color: Colors.red[700]),
                label: Text('Remove', style: TextStyle(color: Colors.red[700])),
              ),
            ),
          if (needsPhoto && !hasPhoto)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Required when meter is disconnected',
                style: TextStyle(color: Colors.orange[800], fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _submitButton(BuildContext context, DormantSurveyController ctrl) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: ctrl.isSubmitting
            ? null
            : () async {
                final err = await ctrl.submit();
                if (!context.mounted) return;
                if (err != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(err), backgroundColor: Colors.red),
                  );
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dormant survey submitted successfully.'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff0288D1),
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: Text(
          ctrl.isSubmitting ? 'Submitting…' : 'Submit Dormant Survey',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

class _LiveLocationMapPreview extends StatefulWidget {
  final double? savedLat;
  final double? savedLng;
  final double? savedAcc;

  const _LiveLocationMapPreview({
    required this.savedLat,
    required this.savedLng,
    required this.savedAcc,
  });

  @override
  State<_LiveLocationMapPreview> createState() => _LiveLocationMapPreviewState();
}

class _LiveLocationMapPreviewState extends State<_LiveLocationMapPreview> {
  StreamSubscription<Position>? _sub;
  Position? _latest;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final hasSaved = widget.savedLat != null && widget.savedLng != null;
    if (!hasSaved) {
      _start();
    }
  }

  @override
  void didUpdateWidget(covariant _LiveLocationMapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If a saved point exists, we can stop streaming to reduce battery.
    final hadSaved = oldWidget.savedLat != null && oldWidget.savedLng != null;
    final hasSaved = widget.savedLat != null && widget.savedLng != null;
    if (!hadSaved && hasSaved) {
      _sub?.cancel();
      _sub = null;
    }
  }

  Future<void> _start() async {
    if (_started) return;
    _started = true;

    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final effective = await Geolocator.checkPermission();
      if (effective == LocationPermission.denied ||
          effective == LocationPermission.deniedForever) {
        if (mounted) setState(() {});
        return;
      }
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (mounted) setState(() {});
        return;
      }

      const settings = LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      );

      _sub = Geolocator.getPositionStream(locationSettings: settings).listen(
        (p) {
          if (!mounted) return;
          setState(() {
            _latest = p;
          });
        },
      );
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasSaved = widget.savedLat != null && widget.savedLng != null;
    final lat = hasSaved ? widget.savedLat : _latest?.latitude;
    final lng = hasSaved ? widget.savedLng : _latest?.longitude;
    final acc = hasSaved ? widget.savedAcc : _latest?.accuracy;

    if (lat == null || lng == null) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Text(
          'Waiting for current location…',
          style: TextStyle(color: Colors.grey[700]),
        ),
      );
    }

    return SizedBox(
      height: 180,
      width: double.infinity,
      child: MyMap(
        lat: lat,
        lon: lng,
        acc: (acc ?? 999).toDouble(),
      ),
    );
  }
}

class _GpsCaptureDialog extends StatefulWidget {
  final double requiredAccuracyMeters;
  final double? initialLat;
  final double? initialLng;
  final void Function(Position position) onSave;
  final VoidCallback onCancel;

  const _GpsCaptureDialog({
    required this.requiredAccuracyMeters,
    required this.initialLat,
    required this.initialLng,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<_GpsCaptureDialog> createState() => _GpsCaptureDialogState();
}

class _GpsCaptureDialogState extends State<_GpsCaptureDialog> {
  StreamSubscription<Position>? _subscription;
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _saving = false;
  bool _starting = false;

  Position? _latestPosition;

  @override
  void initState() {
    super.initState();
    _startCaptureOnce();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startCaptureOnce() async {
    if (_starting) return;
    _starting = true;

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) widget.onCancel();
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) widget.onCancel();
        return;
      }

      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _elapsedSeconds += 1);
      });

      const settings = LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      );

      _subscription = Geolocator.getPositionStream(locationSettings: settings)
          .listen((pos) {
        if (!mounted) return;
        setState(() {
          _latestPosition = pos;
        });
      });
    } catch (_) {
      if (mounted) widget.onCancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = _latestPosition?.accuracy;
    final hasFix = _latestPosition != null && accuracy != null;
    final isRecommendedAccuracy =
        hasFix && accuracy <= widget.requiredAccuracyMeters;
    final canSave = !_saving && hasFix;

    final mm = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final ss = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    final progress = accuracy == null
        ? 0.0
        : (1 - (accuracy / 30)).clamp(0.0, 1.0).toDouble();

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogWidth =
        screenWidth * 0.92 > 360 ? 360.0 : screenWidth * 0.92;
    final maxDialogHeight = screenHeight * 0.8;
    final compact = screenWidth < 360;
    final accuracyFontSize = compact ? 34.0 : 40.0;
    final statusFontSize = compact ? 14.0 : 16.0;

    return AlertDialog(
      backgroundColor: const Color(0xff263238),
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: maxDialogHeight,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 14 : 18,
                  vertical: compact ? 12 : 16,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xff4AA6D6),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GETTING LOCATION',
                      style: TextStyle(
                        color: Color(0xff0E3A56),
                        fontSize: 10,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: compact ? 8 : 10),
                    Center(
                      child: Text(
                        accuracy == null ? '-- m' : '${accuracy.toStringAsFixed(0)} m',
                        style: TextStyle(
                          color: const Color(0xff0D2F45),
                          fontSize: accuracyFontSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        !hasFix
                            ? 'Waiting for GPS fix...'
                            : (isRecommendedAccuracy
                                ? 'Good accuracy. Ready to save.'
                                : 'Accuracy still high. You can save or wait.'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xff0D2F45),
                          fontSize: statusFontSize,
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 8 : 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: compact ? 10 : 12,
                        backgroundColor: const Color(0xff146189),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xff0D2F45),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 10 : 12,
                  compact ? 10 : 12,
                  compact ? 10 : 12,
                  0,
                ),
                child: SizedBox(
                  height: compact ? 200 : 220,
                  width: double.infinity,
                  child: RepaintBoundary(
                    child: MyMap(
                      lat: _latestPosition?.latitude ??
                          widget.initialLat ??
                          -2.0,
                      lon: _latestPosition?.longitude ??
                          widget.initialLng ??
                          36.0,
                      acc: accuracy ?? 999,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 12 : 16,
                  compact ? 8 : 10,
                  compact ? 12 : 16,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Point will be saved at ${widget.requiredAccuracyMeters.toStringAsFixed(0)} m',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Time elapsed: $mm:$ss',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Satellites: 0',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              SizedBox(height: compact ? 6 : 8),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 10 : 12,
                  0,
                  compact ? 10 : 12,
                  compact ? 10 : 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : widget.onCancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xff51B5E8),
                          side: const BorderSide(color: Color(0xff51B5E8)),
                          minimumSize: const Size.fromHeight(44),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: canSave
                            ? () {
                                setState(() => _saving = true);
                                widget.onSave(_latestPosition!);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isRecommendedAccuracy
                              ? const Color(0xff51B5E8)
                              : const Color(0xff1D8BC2),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(44),
                        ),
                        child: Text(
                          isRecommendedAccuracy ? 'Save' : 'Save Anyway',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
