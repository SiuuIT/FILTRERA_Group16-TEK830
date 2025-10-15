import 'package:flutter/material.dart';
import 'statisticWidgets/accident_list_widget.dart';
import 'statisticWidgets/accidents_report_card.dart';
import 'statisticWidgets/heatMapWidgets/factory_heatmap_mvp.dart';
//this is the usable widget
class StatisticsAreaWidget extends StatefulWidget{
  final Map<String, dynamic> aggregates;
  final String aiAnswer;
  const StatisticsAreaWidget({super.key
  ,required this.aggregates, 
  required this.aiAnswer});
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
  return ListView(
    padding: const EdgeInsets.all(8.0),
    children: [
      //  Heatmap section
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "Factory Heatmap",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            FactoryHeatmapMVP(),
          ],
        ),
      ),
      //this is just a simple ai section
      if (widget.aiAnswer.isNotEmpty)
        TextField(
          controller: TextEditingController(text: widget.aiAnswer),
          readOnly: true,
          maxLines: null,
          decoration: const InputDecoration(
            labelText: "AI's Safety Summary",
            border: OutlineInputBorder(),
          ),
        )
      else
        const Text("No AI analysis available yet."),
      RecentAccidentsList(allAccidents: allAccidents),
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
      const SizedBox(height: 16),

      

      const SizedBox(height: 24),
    ],
  );
}


}