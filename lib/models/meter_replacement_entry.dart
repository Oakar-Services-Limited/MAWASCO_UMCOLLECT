class MeterReplacementEntry {
  final String accountNumber;
  final String customerName;
  final String meterNumber;
  final String currentMeterReading;
  final String route;
  final String category;
  final String accountStatus;

  const MeterReplacementEntry({
    required this.accountNumber,
    required this.customerName,
    required this.meterNumber,
    required this.currentMeterReading,
    required this.route,
    required this.category,
    required this.accountStatus,
  });

  static MeterReplacementEntry fromCsvRow(Map<String, String> row) {
    return MeterReplacementEntry(
      accountNumber: (row['account_number'] ?? '').trim(),
      customerName: (row['customer_name'] ?? '').trim(),
      meterNumber: (row['meter_number'] ?? '').trim(),
      currentMeterReading: (row['cur_mtr_rd'] ?? '').trim(),
      route: (row['route'] ?? '').trim(),
      category: (row['category'] ?? '').trim(),
      accountStatus: (row['account_status'] ?? '').trim(),
    );
  }
}
