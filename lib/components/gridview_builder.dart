import 'package:flutter/material.dart';
import 'package:kiambu_umcollect/models/grid_icons.dart';
import 'package:kiambu_umcollect/pages/reportIncident.dart';

class GridViewBuilderWidget extends StatelessWidget {
  const GridViewBuilderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    List<String> imagePaths = GridIcons().getImagePaths();
    List<String> incidences = GridIcons().getIncidences();
    return GridView.builder(
        itemCount: imagePaths.length,
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 250),
        scrollDirection: Axis.vertical,
        itemBuilder: (BuildContext context, int index) {
          return Card(
            color: Colors.lightGreen.shade50,
            child: InkWell(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: Image.asset(
                      imagePaths[index],
                      width: 120,
                      height: 120,
                    ),
                  ),
                  const Divider(),
                  Text(
                    incidences[index],
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  )
                ],
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ReportIncident(
                    incidences[index],
                    categoryId:
                        "1", // Default category ID for legacy grid items
                  ),
                ),
              ),
            ),
          );
        });
  }
}
