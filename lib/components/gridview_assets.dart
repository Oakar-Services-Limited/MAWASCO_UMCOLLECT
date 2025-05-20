// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:um_collect/components/updateDialog.dart';
import 'package:um_collect/models/grid_icons.dart';

class GridViewAssets extends StatefulWidget {
  final String staffid;
  const GridViewAssets({super.key, required this.staffid});
  @override
  State<GridViewAssets> createState() => _GridViewAssetsState();
}

class _GridViewAssetsState extends State<GridViewAssets> {
  List<String> waterNetworkImages = GridIcons().getWaterNetworkImages();
  List<String> waterNetworkTitles = GridIcons().getWaterNetworkTitles();
  List<String> sewerNetworkImages = GridIcons().getSewerNetworkImages();
  List<String> sewerNetworkTitles = GridIcons().getSewerNetworkTitles();
  List<String> newProjectImages = GridIcons().getNewProjectImages();
  List<String> newProjectTitles = GridIcons().getNewProjectTitles();

  void _showDialog(BuildContext context, assetName) async {
    switch (assetName) {
      case 'Customer Meters':
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const DataCollectorsDialog(
                      assetName: 'Customer Meters',
                    )));
        break;
      case 'Water Pipes':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const DataCollectorsDialog(
                    assetName: 'Water Pipes',
                  )),
        );
        break;
      case 'Water Tanks':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const DataCollectorsDialog(
                    assetName: 'Water Tanks',
                  )),
        );
        break;
      case 'Valves':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const DataCollectorsDialog(
                    assetName: 'Valves',
                  )),
        );
        break;
      case 'Master Meters':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const DataCollectorsDialog(
                    assetName: 'Master Meters',
                  )),
        );
        break;
      case 'Washouts':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const DataCollectorsDialog(
                    assetName: 'Washouts',
                  )),
        );
        break;

      case 'Sewer Lines':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const DataCollectorsDialog(
                    assetName: 'Sewer Lines',
                  )),
        );
        break;
      case 'Manholes':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const DataCollectorsDialog(
                    assetName: 'Manholes',
                  )),
        );
        break;
      case 'Project (Lines)':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const DataCollectorsDialog(
                    assetName: 'Project (Lines)',
                  )),
        );
        break;
      case 'Project (Points)':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const DataCollectorsDialog(
                    assetName: 'Project (Points)',
                  )),
        );
        break;
      case 'Customer Chambers':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const DataCollectorsDialog(
                    assetName: 'Customer Chambers',
                  )),
        );
        break;

      case 'Connection Chambers':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const DataCollectorsDialog(
                    assetName: 'Connection Chambers',
                  )),
        );
        break;
      case 'Sewer MainTrunk':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const DataCollectorsDialog(
                    assetName: 'Sewer MainTrunk',
                  )),
        );
        break;
      case 'New Water Connections':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const DataCollectorsDialog(
                    assetName: 'New Water Connections',
                  )),
        );
        break;
      case 'New Sanitation Connections':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const DataCollectorsDialog(
                    assetName: 'New Sanitation Connections',
                  )),
        );
        break;
      case 'Consumer Lines':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const DataCollectorsDialog(
                    assetName: 'Consumer Lines',
                  )),
        );
        break;
      case 'Customer Lines':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const DataCollectorsDialog(
                    assetName: 'Customer Lines',
                  )),
        );
        break;
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Water Network', // Title here
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xff0288D1),
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap:
                true, // Added to prevent the grid from taking extra space
            physics:
                const NeverScrollableScrollPhysics(), // Added to prevent scrolling within the grid
            itemCount: waterNetworkImages.length,
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 250,
            ),
            scrollDirection: Axis.vertical,
            clipBehavior: Clip.hardEdge,
            itemBuilder: (BuildContext context, int index) {
              return GestureDetector(
                onTap: () {
                  _showDialog(context, waterNetworkTitles[index]);
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    color: const Color(0xffEC7C24),
                    elevation: 4,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Material(
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8)),
                          clipBehavior: Clip.hardEdge,
                          color: const Color.fromARGB(255, 207, 236, 252),
                          child: Image.asset(
                            waterNetworkImages[index],
                            width: double.infinity,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(
                          height: 2,
                        ),
                        Text(
                          waterNetworkTitles[index],
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.white),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Sanitation', // Title here
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xff0288D1),
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap:
                true, // Added to prevent the grid from taking extra space
            physics:
                const NeverScrollableScrollPhysics(), // Added to prevent scrolling within the grid
            itemCount: sewerNetworkImages.length,
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 250,
            ),
            scrollDirection: Axis.vertical,
            itemBuilder: (BuildContext context, int index) {
              return GestureDetector(
                onTap: () {
                  _showDialog(context, sewerNetworkTitles[index]);
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    color: const Color(0xffEC7C24),
                    elevation: 4,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Material(
                          color: const Color.fromARGB(255, 252, 230, 224),
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8)),
                          clipBehavior: Clip.hardEdge,
                          child: Image.asset(
                            sewerNetworkImages[index],
                            width: double.infinity,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(
                          height: 2,
                        ),
                        Text(
                          sewerNetworkTitles[index],
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.white),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'New Project', // Title here
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xff0288D1),
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap:
                true, // Added to prevent the grid from taking extra space
            physics:
                const NeverScrollableScrollPhysics(), // Added to prevent scrolling within the grid
            itemCount: newProjectImages.length,
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 250,
            ),
            scrollDirection: Axis.vertical,
            itemBuilder: (BuildContext context, int index) {
              return GestureDetector(
                onTap: () {
                  _showDialog(context, newProjectTitles[index]);
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    color: const Color(0xffEC7C24),
                    elevation: 4,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Material(
                          color: const Color.fromARGB(255, 215, 247, 216),
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8)),
                          child: Image.asset(
                            newProjectImages[index],
                            width: double.infinity,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(
                          height: 2,
                        ),
                        Text(
                          newProjectTitles[index],
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.white),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
