/// Customer model for dropdown/selection from GET /customers API.
class Customer {
  final String id;
  final String displayName;
  /// Route from wt_customer_meters (used to filter customers by zone + route).
  final String route;

  const Customer({
    required this.id,
    required this.displayName,
    this.route = '',
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? json['customerId']?.toString() ?? '';
    final name = json['name']?.toString() ??
        json['accountNo']?.toString() ??
        json['account_no']?.toString() ??
        id;
    final route = json['route']?.toString().trim() ?? '';
    return Customer(id: id, displayName: name, route: route);
  }
}
