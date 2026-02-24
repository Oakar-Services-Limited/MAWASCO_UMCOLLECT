/// Data model for customer supply feedback submission.
class CustomerFeedback {
  final String day;
  final String zone;
  final String area;
  final String customerId;
  final bool waterAvailable;
  final String? satisfaction;
  final String remarks;
  final DateTime timestamp;

  const CustomerFeedback({
    required this.day,
    required this.zone,
    required this.area,
    required this.customerId,
    required this.waterAvailable,
    this.satisfaction,
    required this.remarks,
    required this.timestamp,
  });

  factory CustomerFeedback.fromJson(Map<String, dynamic> json) {
    return CustomerFeedback(
      day: json['day'] as String,
      zone: json['zone'] as String,
      area: json['area'] as String,
      customerId: json['customerId'] as String,
      waterAvailable: json['waterAvailable'] as bool,
      satisfaction: json['satisfaction'] as String?,
      remarks: json['remarks'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'zone': zone,
      'area': area,
      'customerId': customerId,
      'waterAvailable': waterAvailable,
      'satisfaction': satisfaction,
      'remarks': remarks,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
