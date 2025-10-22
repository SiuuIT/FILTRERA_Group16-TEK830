import 'package:flutter/material.dart';
import 'statisticWidgets/accident_list_widget.dart';
import 'statisticWidgets/accidents_report_card.dart';
import 'statisticWidgets/heatMapWidgets/factory_heatmap_mvp.dart';

/// ---- helpers ---------------------------------------------------------------

String _norm(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

int _coerceToInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

/// Reads an int from a (possibly messy) aggregates map by trying several
/// candidate keys and doing light normalization (case / underscores).
int _readIntFromAggregates(
  Map<String, dynamic> aggregates,
  List<String> candidateKeys,
) {
  if (aggregates.isEmpty) return 0;

  // 1) direct hit with normalization
  final normToKey = {
    for (final k in aggregates.keys) _norm(k): k,
  };

  for (final cand in candidateKeys) {
    final hit = normToKey[_norm(cand)];
    if (hit != null) return _coerceToInt(aggregates[hit]);
  }

  // 2) one-level nested maps: look into Map values
  for (final value in aggregates.values) {
    if (value is Map) {
      final nested = Map<String, dynamic>.from(value as Map);
      final nestedNorm = {
        for (final k in nested.keys) _norm(k.toString()): k.toString(),
      };
      for (final cand in candidateKeys) {
        final hit = nestedNorm[_norm(cand)];
        if (hit != null) return _coerceToInt(nested[hit]);
      }
    }
  }

  return 0;
}

/// ---------------------------------------------------------------------------

/// The main statistics area shown on the right side of your UI.
class StatisticsAreaWidget extends StatefulWidget {
  final Map<String, dynamic> aggregates;
  final Map<String, dynamic>? aiAnswer;
  final Map<String, dynamic>? locationCounts; // counts all locations
  final int accidentsCount;
  final int incidentsCount;

  /// You can optionally pass custom keys if your backend uses different names.
  StatisticsAreaWidget({
    Key? key,
    required Map<String, dynamic> aggregates,
    required this.aiAnswer,
    this.locationCounts,
    String? accidentsKey, // e.g. "totalAccidents"
    String? incidentsKey, // e.g. "total_incidents"
  })  : aggregates = aggregates,
        accidentsCount = _readIntFromAggregates(
          aggregates,
          [
            if (accidentsKey != null) accidentsKey,
            'total_accidents',
            'accidents_total',
            'accident_total',
            'accidents',
            'totalAccidents',
          ],
        ),
        incidentsCount = _readIntFromAggregates(
          aggregates,
          [
            if (incidentsKey != null) incidentsKey,
            'total_incidents',
            'incidents_total',
            'incident_total',
            'incidents',
            'totalIncidents',
          ],
        ),
        super(key: key);

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
    final locationCounts = widget.locationCounts ?? {};

    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: [
        // Heatmap
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        FactoryHeatmapMVP(locationCounts: locationCounts),

        const SizedBox(height: 16),

        // AI section
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
          )
        else
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text("No AI analysis available yet."),
          ),

        const SizedBox(height: 16),

        // Recent accidents list
        RecentAccidentsList(allAccidents: allAccidents),

        // Report card (uses dynamic counts)
        SafetyIncidentReportCard(
          factoryName: "Factory B - South Plant",
          accidents: widget.accidentsCount,
          incidents: widget.incidentsCount,
          generatedDate: DateTime(2025, 10, 7, 12, 51),
        ),
      ],
    );
  }
}
