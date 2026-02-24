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

  @override
  void dispose() {
    _remarksController.dispose();
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
            _sectionTitle('4. Select Customer'),
            const SizedBox(height: 8),
            _customerSection(context, ctrl),
            const SizedBox(height: 24),
            _sectionTitle('5. Water Available?'),
            const SizedBox(height: 8),
            _waterAvailableRadio(ctrl),
            if (ctrl.waterAvailable == true) ...[
              const SizedBox(height: 16),
              _sectionTitle('6. Satisfaction'),
              const SizedBox(height: 8),
              _satisfactionRadio(ctrl),
            ],
            const SizedBox(height: 24),
            _sectionTitle(
                ctrl.waterAvailable == true ? '7. Remarks' : '6. Remarks'),
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
            const SizedBox(height: 32),
            _submitButton(context, ctrl),
            const SizedBox(height: 24),
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

  Widget _customerSection(BuildContext context, FeedbackController ctrl) {
    if (ctrl.selectedArea.isEmpty) {
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
          'Select zone and area first to load customers',
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
    if (ctrl.customers.isEmpty) {
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
          'No customers found for this zone and area',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      );
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
        child: DropdownButton<Customer>(
          value: ctrl.selectedCustomer,
          isExpanded: true,
          hint: const Text('Select customer'),
          items: ctrl.customers
              .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c.displayName),
                  ))
              .toList(),
          onChanged: (v) => ctrl.updateCustomer(v),
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
}
