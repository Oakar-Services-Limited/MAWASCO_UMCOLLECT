// ignore_for_file: file_names
import 'dart:convert';

String getUrl() {
  // return "http://192.168.1.136:3003/api/";

  return "https://api-utilitymanager.mawasco.co.ke/api/";
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
    "Gathugu",
    "Indian",
    "Mathaithi A",
    "Mathaithi B",
    "Muthua",
    "Blue Valley",
    "Giakairu",
    "Industry",
    "Sofia",
    "Saigon",
    "Karumaruma",
    "Karindindu",
    "Jamaica",
    "Ragati",
    "Kirimara Secondary",
    "Ndiriti",
    "Kiriko",
    "Kiangai",
    "Githaiti",
    "Kiamuthumbi",
    "Waweru",
    "Factory line",
    "Kiamariga Lower",
    "Mutiini",
    "King'ukiro",
    "Gichoru",
    "Itoga",
    "Gikumbo",
    "Mbogoini B",
    "Mbari Njora",
    "Ikonju",
    "Kaiyaba",
    "Mbari Ya Miiria",
    "Karogoto",
    "Rugoka",
    "Gathumbi",
    "Kimathi",
    "Mugugutu",
    "Migingo",
    "Gatheu",
    "Kirima",
    "Gikore",
    "Kiamucheru",
    "Magutu",
    "Giakimuru",
    "Kanjuri",
    "Gitumbi",
    "Karembu",
    "Mukangu",
    "Ihwagi",
    "Mbari ya Kaigi",
    "Mbari ya Kanja",
    "Cheru- rititi",
    "Gitugu",
    "Kaigi",
    "N/A"
  ];
}

List<String> getZones() {
  return [
    "--Select--",
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

List<String> getSubZones() {
  return [
    "--Select--",
    "011-1 Kiamumb",
    "009-6 makaja",
    "001-7 Project",
    "009- Kamiti B",
    "009-7 Gachiru",
    "009-3 Samaki",
    "007-2 640",
    "006-5 Vee",
    "006-6 Ndichu",
    "006-4 Kairo",
    "001-4 Kimana",
    "001-3 Watetu",
    "005-3 K.K",
    "003-23 Nyautu",
    "005-2 D.C",
    "004-2 P E F A",
    "005-1 Hospital",
    "003-25 Njunu",
    "004-1 Posta",
    "002-8 Ngegu",
    "003-21 Barua",
    "009-1 Kamiti C",
    "010-1 Thindigu",
    "009-4 Kiu-Rive",
    "007-1 Rock-line",
    "009-5 Kiu Kend",
    "008-2 Lower Ki",
    "008-1 Upper Ki",
    "001-1 Kiambu H",
    "008-4 Gichocho",
    "006-7 Ruthiru-i",
    "006-2 Bara-Bar",
    "006-3 Wamuthe",
    "006-1 Shopping",
    "001-5 Thathi-in",
    "001-2 Kamanda",
    "002-4 Edden V",
    "002-1 Route 41",
    "002- 412-Umon",
    "002- Karambai",
    "003-24 Gatiti B",
    "004-3 River Sid",
    "003-16 karunga",
    "003-2 Ndumbe",
    "002-6 Lower Ka",
    "003-22 Gachie",
    "002-2 Kanjata",
    "003-13 Kabae",
    "003-7 gatitu",
    "003-3 Allan",
    "003-6 kiriguini",
    "003-14 DEB",
    "003-9 Ngaita",
    "002-3 Upper Ka",
    "003-11 tingang",
    "003-1 Mburaria",
    "003-10 Kagong",
    "003-15 Tumbur",
    "003-19 Kamuny"
  ];
}
