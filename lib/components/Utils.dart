// ignore_for_file: file_names
import 'dart:convert';

import 'package:http/http.dart' as http;

String getUrl() {
  // return "http://192.168.1.136:3003/api/";
  return "http://192.168.1.121:3003/api/";

  // return "https://api-utilitymanager.mawasco.co.ke/api/";
//
}

Map<String, dynamic> parseJwt(String token) {
  final parts = token.split('.');
  if (parts.length != 3) {
    return <String, dynamic>{"error": "Invalid token"};
  }

  final payload = _decodeBase64(parts[1]);
  final payloadMap = json.decode(payload);
  if (payloadMap is! Map<String, dynamic>) {
    return <String, dynamic>{"error": "Invalid token"};
  }

  return payloadMap;
}

String _decodeBase64(String str) {
  String output = str.replaceAll('-', '+').replaceAll('_', '/');

  switch (output.length % 4) {
    case 0:
      break;
    case 2:
      output += '==';
      break;
    case 3:
      output += '=';
      break;
    default:
      throw Exception('Illegal base64url string!"');
  }

  return utf8.decode(base64Url.decode(output));
}

List<String> getDMAs() {
  return [
    "Blue Valley",
    "Cheru Rititi",
    "Factory Line",
    "Gathagana",
    "Gathehu",
    "Gathugu",
    "Gathumbi",
    "Gatina",
    "Gaturiri",
    "Giakairu",
    "Giakimuru",
    "Gichoru",
    "Gikore",
    "Gikumbo",
    "Githaiti",
    "Githambiro",
    "Gitugu",
    "Gitumbi",
    "Ihwagi",
    "Ikonju",
    "Indian",
    "Industry",
    "Itoga",
    "Jamaica",
    "Jambo",
    "Kahutini",
    "Kaiyaba",
    "Kangongoro",
    "Kanjuri",
    "Kanyama",
    "Karembu",
    "Karindundu",
    "Karogoto",
    "Karumaruma",
    "Kiaihuru",
    "Kiamabara",
    "Kiamariga Lower",
    "Kiamariaga Upper and lower",
    "Kiamucheru",
    "Kiamuthumbi",
    "Kiangai",
    "Kiangi",
    "Kihayu",
    "Kimathi",
    "Kindara A",
    "Kindara B",
    "King'ukiro",
    "Kiriko",
    "Kirima",
    "Kirimara Secondary",
    "Magutu",
    "Mathaithi A",
    "Mathaithi B",
    "Mbari Njora",
    "Mbari ya Kaigi",
    "Mbari ya Kanja",
    "Mbari ya Miiria",
    "Mbogoini B",
    "Migingo",
    "Muchoi",
    "Mugugutu",
    "Mukangu",
    "Muthua",
    "Mutiini",
    "N/A",
    "Ndiriti",
    "Ngurumo",
    "Ragati",
    "Rititi",
    "Rugoka",
    "Ruthagati",
    "Saigon",
    "Sofia",
    "Waweru",
  ];
}

List<String> getZones() {
  return [
    "--Select--",
    "Giakairu",
    "001 Gathugu",
    "002 Urban Institution",
    "003 Indian",
    "004 Industrial",
    "005 Karindundu",
    "006 Mathaithi",
    "007 Ragati",
    "008 Saigon 1",
    "009 Sofia",
    "010 Muthua",
    "011 Blue Valley",
    "012 83",
    "013 84",
    "014 85",
    "015 86",
    "016 87",
    "017 88",
    "018 Jambo-88",
    "019 Tumutumu-87",
    "019 89",
    "020 90",
    "021 91",
    "022 92",
    "023 82(Inst.Rural)",
    "024 93"
  ];
}

// --- Master meter names: central cache, fetched once and reused (search on frontend) ---

List<String> _masterMeterNamesCache = [];
DateTime? _masterMeterNamesCacheTime;
Future<List<String>>? _masterMeterNamesFetchFuture;
const int _masterMeterNamesCacheMaxAgeSeconds = 300;

/// If cache is valid, returns it; otherwise null. Use so the page can show list immediately with no loading.
List<String>? getMasterMeterNamesCached() {
  if (_masterMeterNamesCache.isEmpty || _masterMeterNamesCacheTime == null)
    return null;
  final now = DateTime.now();
  if (now.difference(_masterMeterNamesCacheTime!).inSeconds >=
      _masterMeterNamesCacheMaxAgeSeconds) {
    return null;
  }
  return List.from(_masterMeterNamesCache);
}

/// Returns master meter names (cached if valid, otherwise fetches and caches). Add "--Select--" in UI if needed.
Future<List<String>> getMasterMeterNames() async {
  final cached = getMasterMeterNamesCached();
  if (cached != null) return cached;

  if (_masterMeterNamesFetchFuture != null) {
    return _masterMeterNamesFetchFuture!;
  }

  _masterMeterNamesFetchFuture = _fetchMasterMeterNamesFromApi();
  try {
    final list = await _masterMeterNamesFetchFuture!;
    return list;
  } finally {
    _masterMeterNamesFetchFuture = null;
  }
}

Future<List<String>> _fetchMasterMeterNamesFromApi() async {
  final response = await http.get(
    Uri.parse("${getUrl()}wt/master-meters?limit=1000&namesOnly=1"),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8'
    },
  );

  if (response.statusCode != 200) {
    return List.from(_masterMeterNamesCache); // keep previous cache on error
  }

  final decoded = jsonDecode(response.body);
  final data = decoded['data'] as List? ?? [];
  final names = <String>[];
  for (var meter in data) {
    if (meter['name'] != null && meter['name'].toString().isNotEmpty) {
      final name = meter['name'].toString();
      if (!names.contains(name)) names.add(name);
    }
  }
  _masterMeterNamesCache = names;
  _masterMeterNamesCacheTime = DateTime.now();
  return List.from(names);
}

/// Call from Home (or after login) to warm the cache so Master Meter Readings opens with list ready.
void preloadMasterMeterNames() {
  getMasterMeterNames();
}

/// Invalidate cache so next fetch gets fresh data. Call after creating/updating/deleting a master meter.
void invalidateMasterMeterNamesCache() {
  _masterMeterNamesCache = [];
  _masterMeterNamesCacheTime = null;
  _masterMeterNamesFetchFuture = null;
}

/// Force refresh cache in background. Returns the fresh list when done.
Future<List<String>> refreshMasterMeterNamesCache() async {
  invalidateMasterMeterNamesCache();
  return getMasterMeterNames();
}
