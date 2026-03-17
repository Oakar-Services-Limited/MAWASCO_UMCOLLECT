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
  final double? latitude;
  final double? longitude;
  final double? locationAccuracy;
  final String? photoUrl;

  const CustomerFeedback({
    required this.day,
    required this.zone,
    required this.area,
    required this.customerId,
    required this.waterAvailable,
    this.satisfaction,
    required this.remarks,
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.locationAccuracy,
    this.photoUrl,
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
      latitude: (json['latitude'] is num) ? (json['latitude'] as num).toDouble() : double.tryParse('${json['latitude'] ?? ''}'),
      longitude: (json['longitude'] is num) ? (json['longitude'] as num).toDouble() : double.tryParse('${json['longitude'] ?? ''}'),
      locationAccuracy: (json['locationAccuracy'] is num) ? (json['locationAccuracy'] as num).toDouble() : double.tryParse('${json['locationAccuracy'] ?? ''}'),
      photoUrl: json['photoUrl'] as String?,
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
      'latitude': latitude,
      'longitude': longitude,
      'locationAccuracy': locationAccuracy,
      'photoUrl': photoUrl,
    };
  }
}
