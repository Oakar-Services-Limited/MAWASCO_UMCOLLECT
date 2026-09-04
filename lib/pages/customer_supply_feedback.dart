import 'dart:io';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:um_collect/controllers/feedback_controller.dart';
import 'package:um_collect/models/customer.dart';

class CustomerSupplyFeedback extends StatelessWidget {
  const CustomerSupplyFeedback({super.key});

  static const List<String> days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> satisfactionOptions = [
    'Sufficient',
    'Low Pressure',
  ];

  static const List<String> collectionModes = [
    'Customer Care',
    'Field',
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FeedbackController(),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'Customer Supply Feedback',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: const Color(0xff0288D1),
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        body: const SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: _FeedbackForm(),
        ),
      ),
    );
  }
}

class _FeedbackForm extends StatefulWidget {
  const _FeedbackForm();

  @override
  State<_FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<_FeedbackForm> {
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _manualAccountController = TextEditingController();
  final TextEditingController _manualNameController = TextEditingController();
  final TextEditingController _reporterNameController = TextEditingController();

  @override
  void dispose() {
    _remarksController.dispose();
    _manualAccountController.dispose();
    _manualNameController.dispose();
    _reporterNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FeedbackController>(
      builder: (context, ctrl, _) {
        if (ctrl.remarks.isEmpty && _remarksController.text.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _remarksController.clear();
          });
        }
        if (ctrl.manualAccountNo.isEmpty &&
            _manualAccountController.text.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _manualAccountController.clear();
          });
        }
        if (ctrl.manualCustomerName.isEmpty &&
            _manualNameController.text.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _manualNameController.clear();
          });
        }
        if (_reporterNameController.text != ctrl.reporterName) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _reporterNameController.text = ctrl.reporterName;
          });
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionTitle('1. Select Day'),
            const SizedBox(height: 8),
            _dayDropdown(ctrl),
            const SizedBox(height: 24),
            _sectionTitle('2. Select Zone'),
            const SizedBox(height: 8),
            _zoneDropdown(ctrl),
            const SizedBox(height: 24),
            _sectionTitle('3. Select Area'),
            const SizedBox(height: 8),
            _areaDropdown(ctrl),
            const SizedBox(height: 24),
            _sectionTitle('4. Select Route'),
            const SizedBox(height: 8),
            _routeDropdown(ctrl),
            const SizedBox(height: 24),
            _sectionTitle('5. Customer'),
            const SizedBox(height: 8),
            _customerEntryModeChoice(ctrl),
            const SizedBox(height: 12),
            if (ctrl.customerEntryMode == CustomerEntryMode.fromList) ...[
              _sectionSubtitle('Account Number'),
              const SizedBox(height: 8),
              _customerListSection(context, ctrl),
              const SizedBox(height: 16),
              _sectionSubtitle('Customer Name'),
              const SizedBox(height: 8),
              _customerNameField(ctrl),
            ] else ...[
              _sectionSubtitle('Account Number'),
              const SizedBox(height: 8),
              _manualAccountField(ctrl),
              const SizedBox(height: 16),
              _sectionSubtitle('Customer Name'),
              const SizedBox(height: 8),
              _manualCustomerNameField(ctrl),
            ],
            const SizedBox(height: 24),
            _sectionTitle('6. Data Collection Mode'),
            const SizedBox(height: 8),
            _collectionModeDropdown(ctrl),
            const SizedBox(height: 24),
            _sectionTitle('7. Water Available?'),
            const SizedBox(height: 8),
            _waterAvailableRadio(ctrl),
            if (ctrl.waterAvailable == true) ...[
              const SizedBox(height: 16),
              _sectionTitle('8. Satisfaction'),
              const SizedBox(height: 8),
              _satisfactionRadio(ctrl),
            ],
            const SizedBox(height: 24),
            _sectionTitle(
                ctrl.waterAvailable == true ? '9. Remarks' : '8. Remarks'),
            const SizedBox(height: 8),
            _remarksField(ctrl),
            if (ctrl.waterAvailable == false)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Required when water was not available',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[800],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            _sectionTitle(
                ctrl.waterAvailable == true
                    ? '10. Current Location (optional)'
                    : '9. Current Location (optional)'),
            const SizedBox(height: 8),
            _locationSection(ctrl),
            const SizedBox(height: 24),
            _sectionTitle(
                ctrl.waterAvailable == true
                    ? '11. Photo / Proof'
                    : '10. Photo / Proof'),
            const SizedBox(height: 8),
            _photoSection(ctrl),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Required — capture or choose a photo as proof',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange[800],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle(
                ctrl.waterAvailable == true
                    ? '12. Reporter Name'
                    : '11. Reporter Name'),
            const SizedBox(height: 8),
            _reporterNameField(ctrl),
            const SizedBox(height: 32),
            _submitButton(context, ctrl),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _sectionSubtitle(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.grey[700],
      ),
    );
  }

  Widget _customerEntryModeChoice(FeedbackController ctrl) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xff0288D1).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          RadioListTile<CustomerEntryMode>(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Choose from customer list'),
            subtitle: const Text(
              'Search and pick an account loaded from the database',
              style: TextStyle(fontSize: 12),
            ),
            value: CustomerEntryMode.fromList,
            groupValue: ctrl.customerEntryMode,
            onChanged: (v) {
              if (v != null) ctrl.updateCustomerEntryMode(v);
            },
            activeColor: const Color(0xff0288D1),
          ),
          RadioListTile<CustomerEntryMode>(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Enter account details manually'),
            subtitle: const Text(
              'Type the account number and customer name',
              style: TextStyle(fontSize: 12),
            ),
            value: CustomerEntryMode.manual,
            groupValue: ctrl.customerEntryMode,
            onChanged: (v) {
              if (v != null) ctrl.updateCustomerEntryMode(v);
            },
            activeColor: const Color(0xff0288D1),
          ),
        ],
      ),
    );
  }

  Widget _manualAccountField(FeedbackController ctrl) {
    return TextField(
      controller: _manualAccountController,
      onChanged: ctrl.updateManualAccountNo,
      decoration: InputDecoration(
        hintText: 'Enter account number',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xff0288D1)),
        ),
      ),
    );
  }

  Widget _manualCustomerNameField(FeedbackController ctrl) {
    return TextField(
      controller: _manualNameController,
      onChanged: ctrl.updateManualCustomerName,
      decoration: InputDecoration(
        hintText: 'Enter customer name',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xff0288D1)),
        ),
      ),
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

  Widget _reporterNameField(FeedbackController ctrl) {
    final fromLogin = ctrl.reporterNameFromLogin;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _reporterNameController,
          readOnly: fromLogin,
          onChanged: fromLogin ? null : ctrl.updateReporterName,
          decoration: InputDecoration(
            hintText: fromLogin
                ? 'Logged-in staff name'
                : 'Enter your full name',
            helperText: fromLogin
                ? 'Taken from your login account'
                : 'Required — your login token has no name',
            filled: true,
            fillColor: fromLogin ? Colors.grey[100] : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xff0288D1)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dayDropdown(FeedbackController ctrl) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xff0288D1).withValues(alpha: 0.1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: ctrl.selectedDay.isEmpty ? null : ctrl.selectedDay,
          isExpanded: true,
          hint: const Text('Select day'),
          items: CustomerSupplyFeedback.days
              .map((d) => DropdownMenuItem(value: d, child: Text(d)))
              .toList(),
          onChanged: (v) => ctrl.updateDay(v ?? ''),
        ),
      ),
    );
  }

  Widget _zoneDropdown(FeedbackController ctrl) {
    final zones = ctrl.filteredZones;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xff0288D1).withValues(alpha: 0.1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: ctrl.selectedZone.isEmpty ? null : ctrl.selectedZone,
          isExpanded: true,
          hint: Text(
            ctrl.selectedDay.isEmpty
                ? 'Select day first'
                : (zones.isEmpty ? 'No zones for this day' : 'Select zone'),
          ),
          items: zones
              .map((z) => DropdownMenuItem(value: z, child: Text(z)))
              .toList(),
          onChanged: ctrl.selectedDay.isEmpty || zones.isEmpty
              ? null
              : (v) => ctrl.updateZone(v ?? ''),
        ),
      ),
    );
  }

  Widget _areaDropdown(FeedbackController ctrl) {
    final areas = ctrl.filteredAreas;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xff0288D1).withValues(alpha: 0.1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: ctrl.selectedArea.isEmpty ? null : ctrl.selectedArea,
          isExpanded: true,
          hint: Text(
            ctrl.selectedZone.isEmpty
                ? 'Select zone first'
                : (areas.isEmpty ? 'No areas for this zone' : 'Select area'),
          ),
          items: areas
              .map((a) => DropdownMenuItem(value: a, child: Text(a)))
              .toList(),
          onChanged: ctrl.selectedZone.isEmpty || areas.isEmpty
              ? null
              : (v) => ctrl.updateArea(v ?? ''),
        ),
      ),
    );
  }

  Widget _routeDropdown(FeedbackController ctrl) {
    final routes = ctrl.filteredRoutes;
    final zoneAndAreaSelected =
        ctrl.selectedZone.isNotEmpty && ctrl.selectedArea.isNotEmpty;
    String hintText;
    if (ctrl.isLoadingCustomers && zoneAndAreaSelected) {
      hintText = 'Loading routes...';
    } else if (!zoneAndAreaSelected || ctrl.customers.isEmpty) {
      hintText = 'Select zone and area first to load routes';
    } else if (routes.isEmpty) {
      hintText = 'No routes for this zone';
    } else {
      hintText = 'Select route';
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xff0288D1).withValues(alpha: 0.1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: ctrl.selectedRoute.isEmpty ? null : ctrl.selectedRoute,
          isExpanded: true,
          hint: Text(hintText),
          items: routes
              .map((r) => DropdownMenuItem(value: r, child: Text(r)))
              .toList(),
          onChanged: ctrl.isLoadingCustomers || routes.isEmpty
              ? null
              : (v) => ctrl.updateRoute(v ?? ''),
        ),
      ),
    );
  }

  Widget _customerListSection(BuildContext context, FeedbackController ctrl) {
    if (ctrl.selectedRoute.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xff0288D1).withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          'Select zone, area and route first to load customers',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      );
    }
    if (ctrl.isLoadingCustomers) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xff0288D1).withValues(alpha: 0.1),
          ),
        ),
        child: Center(
          child: LoadingAnimationWidget.horizontalRotatingDots(
            color: const Color(0xff0288D1),
            size: 36,
          ),
        ),
      );
    }
    if (ctrl.customersError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700], size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                ctrl.customersError!,
                style: TextStyle(color: Colors.red[700], fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }
    if (ctrl.filteredCustomers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xff0288D1).withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          'No customers found for this zone and route',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Autocomplete<Customer>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            return ctrl.searchCustomersByAccount(textEditingValue.text);
          },
          displayStringForOption: (Customer c) => c.accountNo,
          onSelected: (Customer c) => ctrl.updateCustomer(c),
          fieldViewBuilder:
              (context, textEditingController, focusNode, onFieldSubmitted) {
            final selectedAccountNo = ctrl.selectedCustomer?.accountNo ?? '';
            if (textEditingController.text != selectedAccountNo) {
              textEditingController.text = selectedAccountNo;
            }
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: 'Type or select account number',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Color(0xff0288D1)),
                ),
              ),
              onChanged: (_) {
                if (ctrl.selectedCustomer != null) {
                  ctrl.updateCustomer(null);
                }
              },
              onSubmitted: (_) => onFieldSubmitted(),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            final items = options.toList();
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 40,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return ListTile(
                          dense: true,
                          title: Text(item.accountNo),
                          subtitle: Text(
                            item.name.isNotEmpty ? item.name : 'No name',
                          ),
                          onTap: () => onSelected(item),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (ctrl.selectedCustomer == null &&
            ctrl.selectedRoute.isNotEmpty &&
            !ctrl.isLoadingCustomers &&
            ctrl.customersError == null &&
            ctrl.filteredCustomers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'Type to search, then choose an account from the suggestions',
              style: TextStyle(fontSize: 12, color: Colors.orange[800]),
            ),
          ),
      ],
    );
  }

  Widget _customerNameField(FeedbackController ctrl) {
    return TextField(
      readOnly: true,
      controller: TextEditingController(text: ctrl.selectedCustomerName),
      decoration: InputDecoration(
        hintText: 'Customer name auto-populates after account selection',
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xff0288D1)),
        ),
      ),
    );
  }

  Widget _waterAvailableRadio(FeedbackController ctrl) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xff0288D1).withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: RadioListTile<bool>(
              title: const Text('Yes'),
              value: true,
              groupValue: ctrl.waterAvailable,
              onChanged: (v) => ctrl.updateWaterAvailable(v),
              activeColor: const Color(0xff0288D1),
            ),
          ),
          Expanded(
            child: RadioListTile<bool>(
              title: const Text('No'),
              value: false,
              groupValue: ctrl.waterAvailable,
              onChanged: (v) => ctrl.updateWaterAvailable(v),
              activeColor: const Color(0xff0288D1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _collectionModeDropdown(FeedbackController ctrl) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xff0288D1).withValues(alpha: 0.1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: ctrl.collectionMode.isEmpty ? null : ctrl.collectionMode,
          isExpanded: true,
          hint: const Text('Select mode'),
          items: CustomerSupplyFeedback.collectionModes
              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
              .toList(),
          onChanged: (v) => ctrl.updateCollectionMode(v ?? ''),
        ),
      ),
    );
  }

  Widget _satisfactionRadio(FeedbackController ctrl) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xff0288D1).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: CustomerSupplyFeedback.satisfactionOptions
            .map(
              (s) => RadioListTile<String>(
                title: Text(s),
                value: s,
                groupValue: ctrl.satisfaction,
                onChanged: (v) => ctrl.updateSatisfaction(v),
                activeColor: const Color(0xff0288D1),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _remarksField(FeedbackController ctrl) {
    return TextField(
      controller: _remarksController,
      onChanged: ctrl.updateRemarks,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Enter remarks',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xff0288D1)),
        ),
      ),
    );
  }

  Widget _submitButton(BuildContext context, FeedbackController ctrl) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: () => _submit(context, ctrl),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff0288D1),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: const Text('Submit Feedback', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  Future<void> _submit(BuildContext context, FeedbackController ctrl) async {
    final err = ctrl.validate();
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Submitting...'),
        duration: Duration(seconds: 2),
      ),
    );

    final error = await ctrl.submitFeedback();

    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Feedback submitted successfully. Thank you!'),
        backgroundColor: Colors.green,
      ),
    );
    // Don't pop; user taps Back to return so success snackbar stays visible.
  }

  Widget _locationSection(FeedbackController ctrl) {
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
          if (hasLocation)
            Text(
              'Lat: ${ctrl.latitude!.toStringAsFixed(6)}, Lng: ${ctrl.longitude!.toStringAsFixed(6)}'
              '${ctrl.locationAccuracy != null ? ' (±${ctrl.locationAccuracy!.toStringAsFixed(0)}m)' : ''}',
              style: TextStyle(color: Colors.grey[800]),
            )
          else
            Text(
              'No location captured',
              style: TextStyle(color: Colors.grey[600]),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => ctrl.captureCurrentLocation(),
                  icon: const Icon(Icons.my_location, size: 18),
                  label: const Text('Use current location'),
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

  Widget _photoSection(FeedbackController ctrl) {
    final hasPhoto = ctrl.photo != null;
    final allowGallery = ctrl.collectionMode == 'Customer Care';
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
            Text(
              'Photo required — capture or choose a file',
              style: TextStyle(color: Colors.orange[800]),
            ),
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (allowGallery) ...[
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (!allowGallery)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Field mode allows camera capture only',
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
              ),
            ),
          if (hasPhoto)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: ctrl.clearPhoto,
                icon: Icon(Icons.delete_outline, color: Colors.red[700]),
                label: Text(
                  'Remove',
                  style: TextStyle(color: Colors.red[700]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
