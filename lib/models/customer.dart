/// Customer model for dropdown/selection from GET /customers API.
class Customer {
  final String id;
  final String displayName;

  const Customer({
    required this.id,
    required this.displayName,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? json['customerId']?.toString() ?? '';
    final name = json['name']?.toString() ??
        json['accountNo']?.toString() ??
        json['account_no']?.toString() ??
        id;
    return Customer(id: id, displayName: name);
  }
}
