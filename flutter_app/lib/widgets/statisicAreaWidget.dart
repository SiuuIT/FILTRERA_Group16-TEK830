import 'package:flutter/material.dart';
import 'statisticWidgets/accident_list_widget.dart';
import 'statisticWidgets/accidents_report_card.dart';
import 'statisticWidgets/heatMapWidgets/factory_heatmap_mvp.dart';

/// The main statistics area shown on the right side of your UI.
class StatisticsAreaWidget extends StatefulWidget {
  final Map<String, dynamic> aggregates;
  final Map<String, dynamic>? aiAnswer;
  final Map<String, dynamic>? locationCounts; // <-- Added

  const StatisticsAreaWidget({
    super.key,
    required this.aggregates,
    required this.aiAnswer,
    this.locationCounts, // <-- Added
  });

  @override
  State<StatisticsAreaWidget> createState() => _StatisticsAreaWidgetState();
}

class _StatisticsAreaWidgetState extends State<StatisticsAreaWidget> {
  bool showStats = false;
  int counter = 0;

  final List<Map<String, String>> allAccidents = [
    {'location': 'Assembly Line 1', 'type': 'Repetitive strain injury', 'severity': 'low'},
    {'location': 'Warehouse', 'type': 'Falling object injury', 'severity': 'high'},
    {'location': 'Loading Dock', 'type': 'Slip and fall', 'severity': 'medium'},
    {'location': 'Packaging Area', 'type': 'Cut injury', 'severity': 'low'},
    {'location': 'Maintenance', 'type': 'Burn injury', 'severity': 'high'},
  ];

  @override
  void initState() {
    super.initState();
    showStats = true;
    counter++;
  }

  @override
  Widget build(BuildContext context) {
    final aiData = widget.aiAnswer ?? {};
    final locationCounts = widget.locationCounts ?? {}; // <-- Extract safe map

    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: [
        // --- Heatmap section ---
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
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "Factory Heatmap",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Pass backend data to heatmap
              FactoryHeatmapMVP(locationCounts: locationCounts),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // --- AI section ---
        const Text(
          "AI Safety Summary by Location",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        if (aiData.isNotEmpty)
          ...aiData.entries.map(
            (entry) => Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.location_on_outlined, color: Colors.blueAccent),
                title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(entry.value.toString()),
              ),
            ),
          ),
        if (aiData.isEmpty)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text("No AI analysis available yet."),
          ),

        const SizedBox(height: 16),

        // --- Recent accidents list ---
        RecentAccidentsList(allAccidents: allAccidents),

        // --- Example report card (static sample) ---
        SafetyIncidentReportCard(
          factoryName: "Factory B - South Plant",
          accidents: 2,
          incidents: 1,
          generatedDate: DateTime(2025, 10, 7, 12, 51),
        ),
      ],
    );
  }
}
