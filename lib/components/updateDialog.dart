// ignore_for_file: use_build_context_synchronously, prefer_typing_uninitialized_variables

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:http/http.dart';
import 'package:um_collect/components/Utils.dart';
import 'package:um_collect/models/SearchAsset.dart';
import 'package:um_collect/pages/Forms/Appurtenances.dart';
import 'package:um_collect/pages/Forms/Boreholes.dart';
import 'package:um_collect/pages/Forms/GritChamber.dart';
import 'package:um_collect/pages/Forms/Kiosks.dart';
import 'package:um_collect/pages/Forms/PointProjects.dart';
import 'package:um_collect/pages/Forms/PumpingStations.dart';
import 'package:um_collect/pages/Forms/SewerTreatment.dart';
import 'package:um_collect/pages/Forms/Washouts.dart';
import 'package:um_collect/pages/Forms/ConnectionChambers.dart';
import 'package:um_collect/pages/Forms/ConsumerLine.dart';
import 'package:um_collect/pages/Forms/CustomerChambers%20.dart';
import 'package:um_collect/pages/Forms/CustomerLines.dart';
import 'package:um_collect/pages/Forms/CustomerMeters.dart';
import 'package:um_collect/pages/Forms/DormantMeterForm.dart';
import 'package:um_collect/pages/dormant_survey.dart';
import 'package:um_collect/pages/Forms/ManHoles.dart';
import 'package:um_collect/pages/Forms/MasterMeters.dart';
import 'package:um_collect/pages/Forms/NewSanConn.dart';
import 'package:um_collect/pages/Forms/NewWaterConn.dart';
import 'package:um_collect/pages/Forms/Offtakers.dart';
import 'package:um_collect/pages/Forms/SewerLines.dart';
import 'package:um_collect/pages/Forms/SewerMainTrunk.dart';
import 'package:um_collect/pages/Forms/Tanks.dart';
import 'package:um_collect/pages/Forms/Valves.dart';
import 'package:um_collect/pages/Forms/WaterPipes.dart';
import 'package:um_collect/pages/MappingLines.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class DataCollectorsDialog extends StatefulWidget {
  final String assetName;

  const DataCollectorsDialog({super.key, required this.assetName});

  @override
  State<DataCollectorsDialog> createState() => _DataCollectorsDialogState();
}

class _DataCollectorsDialogState extends State<DataCollectorsDialog> {
  final storage = const FlutterSecureStorage();
  bool isUpdating = false;
  String searchItem = '';
  String assetname = '';
  int objectID = 0;
  String error = "";
  var fetchedData = '';
  var isLoading;
  final bool _isCheckboxChecked = false;
  final TextEditingController _searchController = TextEditingController();

  List<SearchAsset> entries = <SearchAsset>[];
  List<SearchOfftakes> oentries = <SearchOfftakes>[];
  List<Map<String, dynamic>> cmentries = <Map<String, dynamic>>[];
  List<SearchCustomerChambers> ccentries = <SearchCustomerChambers>[];

  List<SearchProductionMeter> bmentries = <SearchProductionMeter>[];
  List<SearchDMAMeter> dmaentries = <SearchDMAMeter>[];
  List<Map<String, dynamic>> dormantEntries = <Map<String, dynamic>>[];

  late GlobalKey<_DataCollectorsDialogState> dialogKey;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> searchAsset(v, searchItem) async {
    await storage.write(key: 'editing', value: 'true');
    await storage.write(key: "data", value: '');
    setState(() {
      isLoading = LoadingAnimationWidget.staggeredDotsWave(
        color: const Color(0xff0288D1),
        size: 50,
      );

      error = "";
      entries.clear();
      oentries.clear();
      cmentries.clear();
      ccentries.clear();
      bmentries.clear();
      dmaentries.clear();
      dormantEntries.clear();
    });

    if (widget.assetName == 'Dormant Meters') {
      if (v.toString().trim().isEmpty) {
        setState(() {
          dormantEntries.clear();
          isLoading = null;
          error = "Enter an account number to search dormant accounts.";
        });
        return;
      }
      try {
        final searchTerm = v.toString().trim();
        final url =
            "${getUrl()}bl/customer-billing?accountStatus=Dormant&limit=20&accountNo=${Uri.encodeComponent(searchTerm)}";
        final response = await get(Uri.parse(url), headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json'
        });
        if (response.statusCode != 200) {
          throw Exception(
              'Server returned ${response.statusCode}: ${response.body}');
        }
        var data = json.decode(response.body);
        setState(() {
          dormantEntries.clear();
          isLoading = null;
          error = "";
          if (data['success'] == true && data['data'] != null && data['data'] is List) {
            for (var item in data['data']) {
              dormantEntries.add(Map<String, dynamic>.from(item));
            }
            if (dormantEntries.isEmpty) {
              error = "No dormant account found with that account number.";
            }
          } else {
            error = "No dormant account found with that account number.";
          }
        });
      } catch (e) {
        setState(() {
          isLoading = null;
          error = "Error searching: ${e.toString()}";
        });
      }
      return;
    }

    switch (widget.assetName) {
      case 'Water Pipes':
        searchItem = 'wt_water_pipes';
        break;
      case 'Water Tanks':
        searchItem = 'wt_tanks';
        break;
      case 'Valves':
        searchItem = 'wt_valves';
        break;
      case 'Master Meters':
        searchItem = 'wt_master_meters';
        break;
      case 'Washouts':
        searchItem = 'wt_washouts';
        break;
      case 'Kiosks':
        searchItem = 'wt_kiosks';
        break;
      default:
        searchItem = 'customers';
    }

    try {
      String url;
      if (searchItem == 'customers') {
        url = "${getUrl()}wt/customer-meters?accountNo=$v&limit=5";
      } else {
        url = "${getUrl()}wt/assetsearch/$searchItem/$v";
      }
      final response = await get(Uri.parse(url), headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json'
      });

      if (response.statusCode != 200) {
        throw Exception(
            'Server returned ${response.statusCode}: ${response.body}');
      }

      var data = json.decode(response.body);
      setState(() {
        entries.clear();
        oentries.clear();
        cmentries.clear();
        ccentries.clear();
        bmentries.clear();
        dmaentries.clear();
        isLoading = null;
        error = "";

        if (searchItem == 'customers') {
          if (data['success'] == true &&
              data['data'] != null &&
              data['data'] is List) {
            for (var item in data['data']) {
              cmentries.add(item);
            }
            fetchedData = json.encode(data['data']);
            if (cmentries.isEmpty) {
              error =
                  "No customer found with that account number, meter number, or name";
            }
          } else {
            error =
                "No customer found with that account number, meter number, or name";
          }
        } else {
          // Handle other asset types
          if (data is List) {
            if (data.isEmpty) {
              error = "Not found!";
            } else {
              for (var item in data) {
                if (searchItem == 'customerchamber') {
                  ccentries.add(SearchCustomerChambers(
                      AccountNo:
                          int.tryParse(item["AccountNo"]?.toString() ?? "0") ??
                              0));
                } else if (searchItem == 'productionmeters') {
                  bmentries.add(SearchProductionMeter(
                      AccountNumber: item["AccountNumber"]?.toString() ?? ""));
                } else if (searchItem == 'dmameters') {
                  dmaentries.add(SearchDMAMeter(
                      DMAName: item["DMAName"]?.toString() ?? ""));
                } else if (searchItem == 'offtakes') {
                  oentries.add(SearchOfftakes(
                      AccountName: item["AccountName"]?.toString() ?? ""));
                } else {
                  entries.add(
                      SearchAsset(Name: item["ObjectID"]?.toString() ?? ""));
                  // Store the complete item data
                  fetchedData = json.encode(item);
                }
              }
            }
          } else {
            error = "Invalid response format";
          }
        }
      });
    } catch (e) {
      setState(() {
        isLoading = null;
        error = "Error searching: ${e.toString()}";
      });
    }
  }

  Future<void> navigateToForm(
      BuildContext context, assetName, Map<String, dynamic> item) async {
    // Only set editing to true if we have an item with an ID
    if (item.isNotEmpty && item["id"] != null) {
      await storage.write(key: 'editing', value: 'true');
      await storage.write(key: "data", value: json.encode([item]));
    } else {
      // For new assets, set editing to false and clear any existing data
      await storage.write(key: 'editing', value: 'false');
      await storage.write(key: "data", value: '');
    }

    if (!mounted) return;

    switch (assetName) {
      case 'Customer Meters':
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => CustomerMeters(
                      customerMeter: item,
                    )));
        break;
      case 'Water Pipes':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => MappingLines(
                    assetName: widget.assetName,
                    staffid: '',
                  )),
        );
        break;
      case 'Water Tanks':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Tanks()),
        );
        break;
      case 'Valves':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Valves()),
        );
        break;
      case 'Master Meters':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MasterMeters()),
        );
        break;
      case 'Washouts':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Washouts()),
        );
        break;
      case 'Kiosks':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Kiosks()),
        );
        break;
      case 'Offtakes':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Offtakes()),
        );
        break;
      case 'Boreholes':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Boreholes()),
        );
        break;
      case 'Appurtenances':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Appurtenances()),
        );
        break;
      case 'Sewer Lines':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => MappingLines(
                    assetName: widget.assetName,
                    staffid: '',
                  )),
        );
        break;
      case 'Manholes':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ManHoles()),
        );
        break;
      case 'Pumping Stations':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PumpingStations()),
        );
        break;
      case 'Grit Chambers':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GritChambers()),
        );
        break;
      case 'Sewer Treatment':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SewerTreatment()),
        );
        break;

      case 'Project (Points)':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PointProjects()),
        );
        break;
      case 'Project (Lines)':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => MappingLines(
                    assetName: widget.assetName,
                    staffid: '',
                  )),
        );
        break;
      case 'Customer Chambers':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CustomerChambers()),
        );
        break;
      case 'Connection Chambers':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ConnectionChambers()),
        );
        break;
      case 'Sewer MainTrunk':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  MappingLines(assetName: widget.assetName, staffid: '')),
        );
        break;
      case 'New Water Connections':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const NewWaterConn()),
        );
        break;
      case 'New Sanitation Connections':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const NewSanConn()),
        );
        break;
      case 'Consumer Lines':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  MappingLines(assetName: widget.assetName, staffid: '')),
        );
        break;
      case 'Customer Lines':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  MappingLines(assetName: widget.assetName, staffid: '')),
        );
        break;
      default:
    }
  }

  Future<void> updateAssetInfo(
      BuildContext context, String assetName, Map<String, dynamic> item) async {
    await storage.write(key: 'editing', value: 'true');
    await storage.write(key: "data", value: fetchedData);

    if (!mounted) return;

    switch (assetName) {
      case 'Customer Meters':
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => CustomerMeters(
                      customerMeter: item,
                    )));
        break;
      case 'Water Pipes':
        if (_isCheckboxChecked == true) {
          setState(() {
            _isCheckboxChecked == false;
          });
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => MappingLines(
                      assetName: widget.assetName,
                      staffid: '',
                    )),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => const WaterPipes(
                      coordinates: [],
                    )),
          );
        }

        break;
      case 'Water Tanks':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Tanks()),
        );
        break;

      case 'Valves':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Valves()),
        );
        break;
      case 'Master Meters':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MasterMeters()),
        );
        break;
      case 'Washouts':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Washouts()),
        );
        break;
      case 'Kiosks':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Kiosks()),
        );
        break;
      case 'Offtakes':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Offtakes()),
        );
        break;
      case 'Boreholes':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Boreholes()),
        );
        break;
      case 'Appurtenances':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Appurtenances()),
        );
        break;

      case 'Sewer Lines':
        if (_isCheckboxChecked == true) {
          setState(() {
            _isCheckboxChecked == false;
          });
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => MappingLines(
                      assetName: widget.assetName,
                      staffid: '',
                    )),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => const SewerLines(
                      coordinates: [],
                    )),
          );
        }
        break;
      case 'Manholes':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ManHoles()),
        );
        break;
      case 'Customer Chambers':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CustomerChambers()),
        );
        break;
      case 'Connection Chambers':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ConnectionChambers()),
        );
        break;
      case 'Sewer MainTrunk':
        if (_isCheckboxChecked == true) {
          setState(() {
            _isCheckboxChecked == false;
          });
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => MappingLines(
                      assetName: widget.assetName,
                      staffid: '',
                    )),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => const SewerMainTrunk(
                      coordinates: [],
                    )),
          );
        }

        break;
      case 'New Water Connections':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const NewWaterConn()),
        );
        break;
      case 'New Sanitation Connections':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const NewSanConn()),
        );
        break;
      case 'Line Project':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => MappingLines(
                    assetName: widget.assetName,
                    staffid: '',
                  )),
        );
        break;
      case 'Consumer Lines':
        if (_isCheckboxChecked == true) {
          setState(() {
            _isCheckboxChecked == false;
          });
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => MappingLines(
                      assetName: widget.assetName,
                      staffid: '',
                    )),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => const ConsumerLines(
                      coordinates: [],
                    )),
          );
        }
        break;
      case 'Customer Lines':
        if (_isCheckboxChecked == true) {
          setState(() {
            _isCheckboxChecked == false;
          });
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => MappingLines(
                      assetName: widget.assetName,
                      staffid: '',
                    )),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => const CustomerLines(
                      coordinates: [],
                    )),
          );
        }
        break;
      default:
    }
  }

  void getSearchItem() {
    switch (widget.assetName) {
      case "Customer Meters":
        setState(() {
          searchItem = "customers";
        });
        break;
      case "Water Pipes":
        setState(() {
          searchItem = "water-pipes";
        });
        break;
      case "Water Tanks":
        setState(() {
          searchItem = "tanks";
        });
        break;
      case "Valves":
        setState(() {
          searchItem = "valves";
        });
        break;
      case "Master Meters":
        setState(() {
          searchItem = "dmameters";
        });
        break;
      case "Washouts":
        setState(() {
          searchItem = "productionmeters";
        });
        break;
      case "Kiosks":
        setState(() {
          searchItem = "kiosks";
        });
        break;
      case "Dormant Meters":
        setState(() {
          searchItem = "dormant";
        });
        break;
      case "Offtakes":
        setState(() {
          searchItem = "offtakes";
        });
        break;

      case "Boreholes":
        setState(() {
          searchItem = "boreholes";
        });
        break;
      case "Appurtenances":
        setState(() {
          searchItem = "appurtenances";
        });
        break;
      case "Sewer Lines":
        setState(() {
          searchItem = "sewerlines";
        });
        break;
      case "Manholes":
        setState(() {
          searchItem = "manholes";
        });
        break;
      case "Pumping Stations":
        setState(() {
          searchItem = "pumpingstations";
        });
        break;
      case "Grit Chambers":
        setState(() {
          searchItem = "gritchambers";
        });
        break;
      case "Sewer Treatment":
        setState(() {
          searchItem = "sewertreatment";
        });
        break;
      case "Customer Chambers":
        setState(() {
          searchItem = "customerchamber";
        });
        break;
      case "Connection Chambers":
        setState(() {
          searchItem = "connectionchamber";
        });
        break;
      case "Sewer MainTrunk":
        setState(() {
          searchItem = "sewermaintrunk";
        });
        break;
      case "New Water Connections":
        setState(() {
          searchItem = "newwaterconnections";
        });
        break;
      case "New Sanitation Connections":
        setState(() {
          searchItem = "newsanitationconnections";
        });
        break;
      case "Consumer Lines":
        setState(() {
          searchItem = "consumerlines";
        });
        break;
      case "Customer Lines":
        setState(() {
          searchItem = "customerlines";
        });
        break;
      default:
    }
  }

  @override
  void initState() {
    dialogKey = GlobalKey<_DataCollectorsDialogState>();
    getSearchItem();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.assetName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xff0288D1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: Colors.grey[50],
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (widget.assetName != 'Dormant Meters')
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              navigateToForm(context, widget.assetName, {});
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff0288D1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text(
                              'New Asset',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (widget.assetName != 'Dormant Meters') const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search existing asset...',
                            prefixIcon: const Icon(Icons.search,
                                color: Color(0xff0288D1)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                          ),
                          onChanged: (value) {
                            searchAsset(value, searchItem);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: isLoading != null
                  ? Center(child: isLoading)
                  : error.isNotEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  error,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: entries.length +
                              oentries.length +
                              cmentries.length +
                              ccentries.length +
                              bmentries.length +
                              dmaentries.length +
                              dormantEntries.length,
                          itemBuilder: (context, index) {
                            Widget item;
                            if (index < entries.length) {
                              item = _buildAssetItem(entries[index].Name);
                            } else if (index <
                                entries.length + oentries.length) {
                              item = _buildAssetItem(
                                  oentries[index - entries.length].AccountName);
                            } else if (index <
                                entries.length +
                                    oentries.length +
                                    cmentries.length) {
                              final customerIndex =
                                  index - entries.length - oentries.length;

                              if (customerIndex < cmentries.length) {
                                final customerMeter = cmentries[customerIndex];

                                item = _buildAssetItem(
                                  customerMeter["name"] ?? "",
                                  customerMeter: customerMeter,
                                );
                              } else {
                                item = const SizedBox.shrink();
                              }
                            } else if (index <
                                entries.length +
                                    oentries.length +
                                    cmentries.length +
                                    ccentries.length) {
                              item = _buildAssetItem(ccentries[index -
                                      entries.length -
                                      oentries.length -
                                      cmentries.length]
                                  .AccountNo
                                  .toString());
                            } else if (index <
                                entries.length +
                                    oentries.length +
                                    cmentries.length +
                                    ccentries.length +
                                    bmentries.length) {
                              item = _buildAssetItem(bmentries[index -
                                      entries.length -
                                      oentries.length -
                                      cmentries.length -
                                      ccentries.length]
                                  .AccountNumber
                                  .toString());
                            } else if (index <
                                entries.length +
                                    oentries.length +
                                    cmentries.length +
                                    ccentries.length +
                                    bmentries.length +
                                    dmaentries.length) {
                              item = _buildAssetItem(dmaentries[index -
                                      entries.length -
                                      oentries.length -
                                      cmentries.length -
                                      ccentries.length -
                                      bmentries.length]
                                  .DMAName);
                            } else {
                              final dormantIndex = index -
                                  entries.length -
                                  oentries.length -
                                  cmentries.length -
                                  ccentries.length -
                                  bmentries.length -
                                  dmaentries.length;
                              item = _buildDormantItem(
                                  dormantEntries[dormantIndex]);
                            }
                            return item;
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetItem(String name, {Map<String, dynamic>? customerMeter}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          if (customerMeter != null) {
            navigateToForm(context, widget.assetName, customerMeter);
          } else {
            // For non-customer meter items, pass the complete item data
            Map<String, dynamic> itemData = {};
            try {
              itemData = json.decode(fetchedData);
            } catch (e) {
              itemData = {"ObjectID": name};
            }
            navigateToForm(context, widget.assetName, itemData);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xff0288D1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.edit_location_alt,
                  color: Color(0xff0288D1),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: customerMeter != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customerMeter["name"] ?? "",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xff0288D1),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Account: ${customerMeter["accountNo"]} | Meter: ${customerMeter["meterNo"]}",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (customerMeter["Location"]?.isNotEmpty == true)
                            Text(
                              "Location: ${customerMeter["location"]}",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${widget.assetName}:",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xff0288D1),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "ObjectID: $name",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xff0288D1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDormantItem(Map<String, dynamic> billing) {
    final accountNo = billing["accountNo"]?.toString() ?? "";
    final name = billing["name"]?.toString() ?? "";
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xff0288D1).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.water_drop_outlined,
                      color: Color(0xff0288D1),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isEmpty ? "Account $accountNo" : name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xff0288D1),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Account: $accountNo (Dormant)",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (accountNo.isEmpty) return;
                        final prefill = Map<String, dynamic>.from(billing);
                        final nested = billing["customerMeter"];
                        if (nested is Map) {
                          for (final e in nested.entries) {
                            if (e.value != null) prefill[e.key] = e.value;
                          }
                        }
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DormantMeterForm(dormantData: prefill),
                          ),
                        );
                      },
                      icon: const Icon(Icons.app_registration, size: 18),
                      label: const Text('Register'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xff0288D1),
                        side: const BorderSide(color: Color(0xff0288D1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const DormantSurveyPage()),
                        );
                      },
                      icon: const Icon(Icons.fact_check, size: 18),
                      label: const Text('Dormant Survey'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff0288D1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
      ),
    );
  }
}
