// ignore_for_file: file_names, non_constant_identifier_names

class SearchAsset {
  final String Name;
  const SearchAsset({
    required this.Name,
  });
}

class SearchOfftakes {
  final String AccountName;
  const SearchOfftakes({
    required this.AccountName,
  });
}

class SearchCustomerMeter {
  final String AccountNo;
  final String Name;
  final String MeterNo;
  final String Location;

  SearchCustomerMeter({
    required this.AccountNo,
    required this.Name,
    required this.MeterNo,
    required this.Location,
  });

  @override
  String toString() {
    return 'SearchCustomerMeter(AccountNo: $AccountNo, Name: $Name, MeterNo: $MeterNo, Location: $Location)';
  }
}

class SearchCustomerChambers {
  final int AccountNo;
  const SearchCustomerChambers({
    required this.AccountNo,
  });
}

class SearchProductionMeter {
  final String AccountNumber;
  const SearchProductionMeter({
    required this.AccountNumber,
  });
}

class SearchDMAMeter {
  final String DMAName;
  const SearchDMAMeter({
    required this.DMAName,
  });
}
