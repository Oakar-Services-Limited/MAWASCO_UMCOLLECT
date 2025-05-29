// ignore_for_file: use_build_context_synchronously, prefer_typing_uninitialized_variables

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:http/http.dart';
import 'package:um_collect/components/DialogInput.dart';
import 'package:um_collect/components/Utils.dart';
import 'package:um_collect/models/SearchAsset.dart';
import 'package:um_collect/pages/Forms/Appurtenances.dart';
import 'package:um_collect/pages/Forms/Boreholes.dart';
import 'package:um_collect/pages/Forms/GritChamber.dart';
import 'package:um_collect/pages/Forms/LineProjects.dart';
import 'package:um_collect/pages/Forms/PointProjects.dart';
import 'package:um_collect/pages/Forms/PumpingStations.dart';
import 'package:um_collect/pages/Forms/SewerTreatment.dart';
import 'package:um_collect/pages/Forms/Washouts.dart';
import 'package:um_collect/pages/Forms/ConnectionChambers.dart';
import 'package:um_collect/pages/Forms/ConsumerLine.dart';
import 'package:um_collect/pages/Forms/CustomerChambers%20.dart';
import 'package:um_collect/pages/Forms/CustomerLines.dart';
import 'package:um_collect/pages/Forms/CustomerMeters.dart';
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
  bool _isCheckboxChecked = false;
  final TextEditingController _searchController = TextEditingController();

  List<SearchAsset> entries = <SearchAsset>[];
  List<SearchOfftakes> oentries = <SearchOfftakes>[];
  List<Map<String, dynamic>> cmentries = <Map<String, dynamic>>[];
  List<SearchCustomerChambers> ccentries = <SearchCustomerChambers>[];

  List<SearchProductionMeter> bmentries = <SearchProductionMeter>[];
  List<SearchDMAMeter> dmaentries = <SearchDMAMeter>[];

  late GlobalKey<_DataCollectorsDialogState> dialogKey;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  searchAsset(v, searchItem) async {
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
    });

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
      case 'Washouts':
        searchItem = 'wt_washouts';
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

      print('searched value: $v, searched item: $searchItem');

      final response = await get(Uri.parse(url), headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json'
      });

      if (response.statusCode != 200) {
        throw Exception(
            'Server returned ${response.statusCode}: ${response.body}');
      }

      var data = json.decode(response.body);

      print(data);

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
    } catch (e, stackTrace) {
      print("505 ERROR: $e, $stackTrace");
      setState(() {
        isLoading = null;
        error = "Error searching: ${e.toString()}";
      });
    }
  }

  navigateToForm(
      BuildContext context, assetName, Map<String, dynamic> item) async {
    await storage.write(key: 'editing', value: 'true');
    await storage.write(key: "data", value: json.encode([item]));

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

  updateAssetInfo(
      BuildContext context, String assetName, Map<String, dynamic> item) async {
    await storage.write(key: 'editing', value: 'true');
    await storage.write(key: "data", value: fetchedData);

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

  getSearchItem() {
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
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
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
                  const SizedBox(height: 16),
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
                              dmaentries.length,
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
                            } else {
                              item = _buildAssetItem(dmaentries[index -
                                      entries.length -
                                      oentries.length -
                                      cmentries.length -
                                      ccentries.length -
                                      bmentries.length]
                                  .DMAName);
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
              print("Error decoding item data: $e");
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
                  color: const Color(0xff0288D1).withOpacity(0.1),
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
}
