// ignore_for_file: file_names
import 'dart:convert';

String getUrl() {
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
