import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:um_collect/controllers/meter_replacement_controller.dart';
import 'package:um_collect/components/offline_pending_card.dart';
import 'package:um_collect/models/Map.dart';
import 'package:um_collect/models/meter_replacement_entry.dart';
import 'package:um_collect/theme/app_theme.dart';

class MeterReplacementPage extends StatelessWidget {
  const MeterReplacementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MeterReplacementController()..init(),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'Meter Replacement Form',
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
          child: _MeterReplacementForm(),
        ),
      ),
    );
  }
}

class _MeterReplacementForm extends StatelessWidget {
  const _MeterReplacementForm();

  static const double _requiredAccuracyMeters = 5.0;

  @override
  Widget build(BuildContext context) {
    return Consumer<MeterReplacementController>(
      builder: (context, ctrl, _) {
        if (ctrl.isLoadingList) {
          return const Center(child: CircularProgressIndicator());
        }
        if (ctrl.loadError != null) {
          return Text(ctrl.loadError!, style: TextStyle(color: Colors.red[700]));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const OfflinePendingCard(
              types: ['meter_replacement'],
              label: 'Meter Replacement',
            ),
            const SizedBox(height: 12),
            _sectionTitle('Replacement context'),
            const SizedBox(height: 8),
            _replacementSourceChoice(ctrl),
            const SizedBox(height: 24),
            _sectionTitle('Assignment details'),
            const SizedBox(height: 8),
            _zoneDropdown(ctrl),
            const SizedBox(height: 12),
            _readOnlyField(
              label: 'Meter Service Technician',
              hint: 'Logged-in field technician',
              value: ctrl.technicianName.isEmpty
                  ? 'Loading…'
                  : ctrl.technicianName,
            ),
            if (ctrl.replacementSource != null) ...[
              const SizedBox(height: 24),
              _sectionTitle('Meter identification'),
              const SizedBox(height: 8),
              if (ctrl.replacementSource ==
                  MeterReplacementSource.scheduledExercise)
                _exerciseAccountSearch(context, ctrl)
              else
                _normalOperationsCustomerFields(ctrl),
              const SizedBox(height: 24),
              _sectionTitle('Meter replaceability check'),
              const SizedBox(height: 8),
              _replaceabilityChoice(ctrl),
              if (ctrl.canBeReplaced == false) ...[
                const SizedBox(height: 12),
                _notReplaceableSection(context, ctrl),
              ],
              if (ctrl.canBeReplaced != null) ...[
                if (ctrl.canBeReplaced == true) ...[
                const SizedBox(height: 24),
                _sectionTitle('Meter being removed'),
                const SizedBox(height: 8),
                _photoBlock(
                  ctrl: ctrl,
                  title: 'Photo of meter being removed *',
                  subtitle:
                      'Take a clear photo showing the meter reading and serial number',
                  photo: ctrl.photoMeterRemoved,
                  onCapture: ctrl.capturePhotoMeterRemoved,
                  onGallery: ctrl.pickPhotoMeterRemovedFromGallery,
                  onClear: ctrl.clearPhotoMeterRemoved,
                ),
                const SizedBox(height: 12),
                _textInput(
                  label: 'Reading of meter being removed *',
                  hint: 'Type the current reading shown on the meter',
                  value: ctrl.readingMeterRemoved,
                  onChanged: ctrl.setReadingMeterRemoved,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _textInput(
                  label: 'Confirm meter serial number *',
                  hint: 'Type the serial number visible on the meter',
                  value: ctrl.confirmRemovedSerial,
                  onChanged: ctrl.setConfirmRemovedSerial,
                ),
                const SizedBox(height: 24),
                _sectionTitle('New meter installation'),
                const SizedBox(height: 8),
                _textInput(
                  label: 'New meter serial number *',
                  hint: 'Enter the serial number of the new meter',
                  value: ctrl.newMeterSerial,
                  onChanged: ctrl.setNewMeterSerial,
                ),
                const SizedBox(height: 12),
                _photoBlock(
                  ctrl: ctrl,
                  title: 'Photo of new meter installed *',
                  subtitle: 'Take a clear photo of the newly installed meter',
                  photo: ctrl.photoNewMeter,
                  onCapture: ctrl.capturePhotoNewMeter,
                  onGallery: ctrl.pickPhotoNewMeterFromGallery,
                  onClear: ctrl.clearPhotoNewMeter,
                ),
                const SizedBox(height: 12),
                _textInput(
                  label: 'Initial reading of new meter *',
                  hint: 'Type the initial reading of the new meter',
                  value: ctrl.initialNewMeterReading,
                  onChanged: ctrl.setInitialNewMeterReading,
                  keyboardType: TextInputType.number,
                ),
              ],
              const SizedBox(height: 24),
              _sectionTitle('Location information'),
              const SizedBox(height: 8),
              _locationSection(context, ctrl),
              if (ctrl.canBeReplaced == true &&
                  ctrl.replacementSource != null) ...[
                const SizedBox(height: 24),
                _sectionTitle('Route verification'),
                const SizedBox(height: 8),
                _routeVerification(ctrl),
              ],
              const SizedBox(height: 24),
              _sectionTitle('Additional notes (optional)'),
              const SizedBox(height: 8),
              _textInput(
                label: 'Additional notes',
                hint: 'Any other relevant information',
                value: ctrl.additionalNotes,
                onChanged: ctrl.setAdditionalNotes,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              _submitButton(context, ctrl),
              ],
            ],
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

  Widget _replacementSourceChoice(MeterReplacementController ctrl) {
    return _cardWrap(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Is this meter on the scheduled replacement list? *',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose how you are identifying the meter before proceeding.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          RadioListTile<MeterReplacementSource>(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Yes — scheduled exercise (pick from list)'),
            subtitle: const Text(
              'Account is on the Meter Replacement Exercise list',
              style: TextStyle(fontSize: 12),
            ),
            value: MeterReplacementSource.scheduledExercise,
            groupValue: ctrl.replacementSource,
            onChanged: ctrl.setReplacementSource,
            activeColor: AppTheme.primaryMain,
          ),
          RadioListTile<MeterReplacementSource>(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('No — other / normal operations'),
            subtitle: const Text(
              'Enter account, customer, meter, route, and other details manually',
              style: TextStyle(fontSize: 12),
            ),
            value: MeterReplacementSource.normalOperations,
            groupValue: ctrl.replacementSource,
            onChanged: ctrl.setReplacementSource,
            activeColor: AppTheme.primaryMain,
          ),
        ],
      ),
    );
  }

  Widget _zoneDropdown(MeterReplacementController ctrl) {
    return _dropdown(
      label: 'Zone *',
      hint: 'Select the operational zone',
      value: ctrl.zone.isEmpty ? null : ctrl.zone,
      items: ctrl.zoneOptions,
      onChanged: (v) => ctrl.setZone(v ?? ''),
    );
  }

  Widget _readOnlyField({
    required String label,
    required String hint,
    required String value,
  }) {
    return TextField(
      readOnly: true,
      controller: TextEditingController(text: value),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  Widget _exerciseAccountSearch(
    BuildContext context,
    MeterReplacementController ctrl,
  ) {
    final results = ctrl.exerciseSearchResults();
    final selected = ctrl.selectedExerciseEntry;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _textInput(
          label: 'Enter account number *',
          hint: 'Type the account number to search',
          value: ctrl.accountSearchQuery,
          onChanged: ctrl.setAccountSearchQuery,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: ctrl.accountSearchQuery.trim().isEmpty
                ? null
                : ctrl.lookupAccountByNumber,
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Search account'),
          ),
        ),
        if (ctrl.accountNotFound)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Account number not found in database. Please verify.',
              style: TextStyle(color: Colors.orange[800], fontSize: 13),
            ),
          ),
        if (results.isNotEmpty && selected == null) ...[
          _cardWrap(
            DropdownButtonHideUnderline(
              child: DropdownButton<MeterReplacementEntry>(
                isExpanded: true,
                hint: const Text('Select matching account'),
                items: results
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(
                          '${e.accountNumber} — ${e.customerName}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: ctrl.selectExerciseEntry,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (selected != null) _exerciseDetailsCard(selected),
      ],
    );
  }

  Widget _exerciseDetailsCard(MeterReplacementEntry entry) {
    return _cardWrap(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer details',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          _detailRow('Customer name', entry.customerName),
          _detailRow(
            'Meter number',
            entry.meterNumber.trim().isEmpty ? '—' : entry.meterNumber,
          ),
          _detailRow('Current route', entry.route),
          _detailRow('Last recorded reading', entry.currentMeterReading),
          _detailRow('Category', entry.category),
          _detailRow('Account status', entry.accountStatus),
        ],
      ),
    );
  }

  /// Same fields as the exercise list, for normal operations (manual entry).
  Widget _normalOperationsCustomerFields(MeterReplacementController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cardWrap(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer details',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Fill in all items that would appear after selecting from the '
                'replacement list.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _textInput(
          label: 'Account number *',
          hint: 'Customer account number',
          value: ctrl.manualAccountNumber,
          onChanged: ctrl.setManualAccountNumber,
        ),
        const SizedBox(height: 12),
        _textInput(
          label: 'Customer name *',
          hint: 'Full name as on account',
          value: ctrl.manualCustomerName,
          onChanged: ctrl.setManualCustomerName,
        ),
        const SizedBox(height: 12),
        _textInput(
          label: 'Meter number (optional)',
          hint: 'Meter number on site / billing — leave blank if unknown',
          value: ctrl.manualMeterNumber,
          onChanged: ctrl.setManualMeterNumber,
        ),
        const SizedBox(height: 12),
        _textInput(
          label: 'Current route *',
          hint: 'e.g. 005 Karindundu 01',
          value: ctrl.manualCurrentRoute,
          onChanged: ctrl.setManualCurrentRoute,
        ),
        const SizedBox(height: 12),
        _textInput(
          label: 'Last recorded reading *',
          hint: 'Last billing / system reading (m³)',
          value: ctrl.manualLastRecordedReading,
          onChanged: ctrl.setManualLastRecordedReading,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 12),
        _dropdown(
          label: 'Category *',
          hint: 'Select category',
          value: ctrl.manualCategory.isEmpty ? null : ctrl.manualCategory,
          items: MeterReplacementController.manualCategoryOptions,
          onChanged: (v) => ctrl.setManualCategory(v ?? ''),
        ),
        const SizedBox(height: 12),
        _dropdown(
          label: 'Account status *',
          hint: 'Select status',
          value:
              ctrl.manualAccountStatus.isEmpty ? null : ctrl.manualAccountStatus,
          items: MeterReplacementController.manualAccountStatusOptions,
          onChanged: (v) => ctrl.setManualAccountStatus(v ?? ''),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: Colors.grey[800], fontSize: 14),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value.isEmpty ? '—' : value),
          ],
        ),
      ),
    );
  }

  Widget _replaceabilityChoice(MeterReplacementController ctrl) {
    return _cardWrap(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Can this meter be replaced? *',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Check if there are any issues preventing replacement',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          RadioListTile<bool>(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Yes — meter can be replaced'),
            value: true,
            groupValue: ctrl.canBeReplaced,
            onChanged: ctrl.setCanBeReplaced,
            activeColor: AppTheme.primaryMain,
          ),
          RadioListTile<bool>(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('No — there is an issue preventing replacement'),
            value: false,
            groupValue: ctrl.canBeReplaced,
            onChanged: ctrl.setCanBeReplaced,
            activeColor: AppTheme.primaryMain,
          ),
        ],
      ),
    );
  }

  Widget _notReplaceableSection(
    BuildContext context,
    MeterReplacementController ctrl,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _dropdown(
          label: 'Reason meter cannot be replaced *',
          hint: 'Select the main reason',
          value: ctrl.notReplaceableReason.isEmpty
              ? null
              : ctrl.notReplaceableReason,
          items: MeterReplacementController.notReplaceableReasons,
          onChanged: (v) => ctrl.setNotReplaceableReason(v ?? ''),
        ),
        if (ctrl.notReplaceableReason ==
            MeterReplacementController.notReplaceableOtherLabel) ...[
          const SizedBox(height: 12),
          _textInput(
            label: 'Specify other reason *',
            hint: 'Describe why the meter cannot be replaced',
            value: ctrl.notReplaceableOtherReason,
            onChanged: ctrl.setNotReplaceableOtherReason,
            maxLines: 2,
          ),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blueGrey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blueGrey.shade100),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Colors.blueGrey[700], size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'This meter has been flagged as NOT replaceable. The customer '
                  'will be contacted to resolve the issue. Please submit the form '
                  'to record the issue.',
                  style: TextStyle(color: Colors.blueGrey[800], fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _photoBlock(
          ctrl: ctrl,
          title: 'Photo of issue *',
          subtitle:
              'Take a photo showing why replacement is not possible (required)',
          photo: ctrl.photoIssue,
          onCapture: ctrl.capturePhotoIssue,
          onGallery: ctrl.pickPhotoIssueFromGallery,
          onClear: ctrl.clearPhotoIssue,
        ),
      ],
    );
  }

  Widget _routeVerification(MeterReplacementController ctrl) {
    final currentRoute = ctrl.displayCurrentRoute ?? '—';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _cardWrap(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Is the current route correct? *',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Current route: $currentRoute',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              RadioListTile<bool>(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('Yes — route is correct'),
                value: true,
                groupValue: ctrl.routeIsCorrect,
                onChanged: ctrl.setRouteIsCorrect,
                activeColor: AppTheme.primaryMain,
              ),
              RadioListTile<bool>(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('No — route is incorrect'),
                value: false,
                groupValue: ctrl.routeIsCorrect,
                onChanged: ctrl.setRouteIsCorrect,
                activeColor: AppTheme.primaryMain,
              ),
            ],
          ),
        ),
        if (ctrl.routeIsCorrect == false) ...[
          const SizedBox(height: 12),
          _dropdown(
            label: 'Select the correct route *',
            hint: 'Choose the actual route where the meter is located',
            value: ctrl.correctedRoute.isEmpty ? null : ctrl.correctedRoute,
            items: ctrl.routeOptions,
            onChanged: (v) => ctrl.setCorrectedRoute(v ?? ''),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        _cardWrap(
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
        ),
      ],
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

  Widget _photoBlock({
    required MeterReplacementController ctrl,
    required String title,
    required String subtitle,
    required dynamic photo,
    required VoidCallback onCapture,
    required VoidCallback onGallery,
    required VoidCallback onClear,
  }) {
    final hasPhoto = photo != null;
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 8),
          if (hasPhoto)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(photo.path),
                height: 180,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 100,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                'Click here to upload file (< 10MB)',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onCapture,
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: Text(hasPhoto ? 'Retake photo' : 'Take photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff0288D1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onGallery,
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Choose file'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xff0288D1),
                    side: const BorderSide(color: Color(0xff0288D1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (hasPhoto)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onClear,
                icon: Icon(Icons.delete_outline, color: Colors.red[700]),
                label: Text('Remove', style: TextStyle(color: Colors.red[700])),
              ),
            ),
        ],
      ),
    );
  }

  Widget _locationSection(BuildContext context, MeterReplacementController ctrl) {
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
          const Text(
            'Capture GPS location *',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Accuracy should be less than ${_requiredAccuracyMeters.toStringAsFixed(0)} meters',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          _LiveLocationMapPreview(
            savedLat: ctrl.latitude,
            savedLng: ctrl.longitude,
            savedAcc: ctrl.locationAccuracy,
          ),
          const SizedBox(height: 10),
          if (hasLocation) ...[
            _textInput(
              label: 'Latitude (°)',
              value: ctrl.latitude!.toStringAsFixed(6),
              onChanged: (_) {},
              enabled: false,
            ),
            const SizedBox(height: 8),
            _textInput(
              label: 'Longitude (°)',
              value: ctrl.longitude!.toStringAsFixed(6),
              onChanged: (_) {},
              enabled: false,
            ),
            if (ctrl.altitude != null) ...[
              const SizedBox(height: 8),
              _textInput(
                label: 'Altitude (m)',
                value: ctrl.altitude!.toStringAsFixed(1),
                onChanged: (_) {},
                enabled: false,
              ),
            ],
            if (ctrl.locationAccuracy != null) ...[
              const SizedBox(height: 8),
              _textInput(
                label: 'Accuracy (m)',
                value: ctrl.locationAccuracy!.toStringAsFixed(1),
                onChanged: (_) {},
                enabled: false,
              ),
            ],
          ] else
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
                      borderRadius: BorderRadius.circular(12),
                    ),
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
    MeterReplacementController ctrl,
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
              alt: p.altitude,
            );
            Navigator.of(dialogContext).pop();
          },
          onCancel: () => Navigator.of(dialogContext).pop(),
        );
      },
    );
  }

  Widget _submitButton(BuildContext context, MeterReplacementController ctrl) {
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
                  SnackBar(
                    content: Text(
                      ctrl.lastSubmitNotice ??
                          'Meter replacement submitted successfully.',
                    ),
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
          ctrl.isSubmitting ? 'Submitting…' : 'Submit Meter Replacement',
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
    if (!hasSaved) _start();
  }

  @override
  void didUpdateWidget(covariant _LiveLocationMapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
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
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) setState(() {});
        return;
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) setState(() {});
        return;
      }
      _sub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 0,
        ),
      ).listen((p) {
        if (mounted) setState(() => _latest = p);
      });
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
      child: MyMap(lat: lat, lon: lng, acc: (acc ?? 999).toDouble()),
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
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) widget.onCancel();
        return;
      }
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _elapsedSeconds += 1);
      });
      _subscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 0,
        ),
      ).listen((pos) {
        if (mounted) setState(() => _latestPosition = pos);
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
    final dialogWidth =
        screenWidth * 0.92 > 360 ? 360.0 : screenWidth * 0.92;
    final compact = screenWidth < 360;

    return AlertDialog(
      backgroundColor: const Color(0xff263238),
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
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
                  children: [
                    Text(
                      accuracy == null ? '-- m' : '${accuracy.toStringAsFixed(0)} m',
                      style: TextStyle(
                        color: const Color(0xff0D2F45),
                        fontSize: compact ? 34 : 40,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      !hasFix
                          ? 'Waiting for GPS fix...'
                          : (isRecommendedAccuracy
                              ? 'Good accuracy. Ready to save.'
                              : 'Accuracy still high. You can save or wait.'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xff0D2F45),
                        fontSize: compact ? 14 : 16,
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
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  height: compact ? 200 : 220,
                  width: double.infinity,
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Time elapsed: $mm:$ss',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(compact ? 10 : 12),
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
