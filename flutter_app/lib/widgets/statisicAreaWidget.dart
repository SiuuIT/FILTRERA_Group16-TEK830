import 'package:flutter/material.dart';
import 'statisticWidgets/accident_list_widget.dart';
import 'statisticWidgets/accidents_report_card.dart';
import 'statisticWidgets/heatMapWidgets/app.dart';
import 'statisticWidgets/heatMapWidgets/factory_heatmap_mvp.dart';
//this is the usable widget
class StatisticsAreaWidget extends StatefulWidget{
  const StatisticsAreaWidget({super.key});
  @override
  State<StatisticsAreaWidget> createState() => _StatisticsAreaWidgetState();

}

class _StatisticsAreaWidgetState extends State<StatisticsAreaWidget>{
  bool showStats = false; 
  int counter = 0;
  final List<Map<String, String>> allAccidents = [
    {'location': 'Assembly Line 1', 'type': 'Repetitive strain injury', 'severity': 'low'},
    {'location': 'Warehouse', 'type': 'Falling object injury', 'severity': 'high'},
    {'location': 'Loading Dock', 'type': 'Slip and fall', 'severity': 'medium'},
    {'location': 'Packaging Area', 'type': 'Cut injury', 'severity': 'low'},
    {'location': 'Maintenance', 'type': 'Burn injury', 'severity': 'high'},
  ];
  // toggles between beeing loaded and not loaded
  @override
  void initState(){
    super.initState();
    showStats = true; 
    counter++;
  }
  
@override
Widget build(BuildContext context) {
  return SingleChildScrollView(
    child: ConstrainedBox(
      // prevent children from receiving unbounded height
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height,
      ),
      child: ListView(
        // allow ListView to size itself inside the outer scroll view
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          RecentAccidentsList(allAccidents:  allAccidents),
          SafetyIncidentReportCard(
            factoryName: "Factory B - South Plant",
            totalEvents: 3,
            highSeverity: 1,
            mediumSeverity: 1,
            lowSeverity: 1,
            accidents: 2,
            incidents: 1,
            nearMisses: 0,
            generatedDate: DateTime(2025, 10, 7, 12, 51),
          ),
          // Give the heatmap a bounded height so it can render
          SizedBox(
            height: 320,
            child: FactoryHeatmapMVP(),
          ),
        ],
      ),
    ),
  );
}

}