/// Customer model for dropdown/selection from GET /customers API.
class Customer {
  final String id;
  final String displayName;
  final String accountNo;
  final String name;
  /// Route from wt_customer_meters (used to filter customers by zone + route).
  final String route;

  const Customer({
    required this.id,
    required this.displayName,
    this.accountNo = '',
    this.name = '',
    this.route = '',
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? json['customerId']?.toString() ?? '';
    final accountNo =
        json['accountNo']?.toString() ?? json['account_no']?.toString() ?? '';
    final name = json['name']?.toString() ?? '';
    final displayName = accountNo.isNotEmpty
        ? accountNo
        : (name.isNotEmpty ? name : id);
    final route = json['route']?.toString().trim() ?? '';
    return Customer(
      id: id,
      displayName: displayName,
      accountNo: accountNo,
      name: name,
      route: route,
    );
  }
}
