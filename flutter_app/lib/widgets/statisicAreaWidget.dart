import 'package:flutter/material.dart';
import 'statisticWidgets/accident_list_widget.dart';
import 'statisticWidgets/accidents_report_card.dart';
import 'statisticWidgets/heatMapWidgets/factory_heatmap_mvp.dart';

String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

int _coerceToInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

int _readIntFromAggregates(
  Map<String, dynamic> aggregates,
  List<String> candidateKeys,
) {
  if (aggregates.isEmpty) return 0;
  final normToKey = {for (final k in aggregates.keys) _norm(k): k};
  for (final cand in candidateKeys) {
    final hit = normToKey[_norm(cand)];
    if (hit != null) return _coerceToInt(aggregates[hit]);
  }
  for (final value in aggregates.values) {
    if (value is Map) {
      final nested = Map<String, dynamic>.from(value as Map);
      final nestedNorm = {for (final k in nested.keys) _norm(k.toString()): k.toString()};
      for (final cand in candidateKeys) {
        final hit = nestedNorm[_norm(cand)];
        if (hit != null) return _coerceToInt(nested[hit]);
      }
    }
  }
  return 0;
}

class StatisticsAreaWidget extends StatefulWidget {
  final Map<String, dynamic> aggregates;
  final dynamic aiAnswer;
  final Map<String, dynamic>? locationCounts;
  final List<Map<String, dynamic>> reports;
  final int accidentsCount;
  final int incidentsCount;
  final bool isRefreshing; // NEW

  StatisticsAreaWidget({
    Key? key,
    required Map<String, dynamic> aggregates,
    required this.aiAnswer,
    this.locationCounts,
    required this.reports,
    this.isRefreshing = false, // NEW
    String? accidentsKey,
    String? incidentsKey,
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
  bool isDataLoaded = false;
  bool isFirstBuild = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, _updateLoadingState);
  }

  @override
  void didUpdateWidget(covariant StatisticsAreaWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final dataChanged = oldWidget.aggregates != widget.aggregates ||
        oldWidget.reports != widget.reports ||
        oldWidget.locationCounts != widget.locationCounts ||
        oldWidget.aiAnswer != widget.aiAnswer;

    if (dataChanged) {
      setState(() => isDataLoaded = false);
      Future.delayed(const Duration(milliseconds: 300), _updateLoadingState);
    }
  }

  void _updateLoadingState() {
    final hasData = widget.aggregates.isNotEmpty ||
        widget.reports.isNotEmpty ||
        (widget.locationCounts?.isNotEmpty ?? false);

    if (hasData) {
      setState(() => isDataLoaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final aiData = (widget.aiAnswer is Map<String, dynamic>)
        ? widget.aiAnswer as Map<String, dynamic>
        : {};
    final locationCounts = widget.locationCounts ?? {};

    if (widget.isRefreshing || !isDataLoaded) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(strokeWidth: 3),
            SizedBox(height: 20),
            Text(
              "Loading factory statistics and AI analysis...",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }


    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: [
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
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Factory Heatmap",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        FactoryHeatmapMVP(locationCounts: locationCounts),
        const SizedBox(height: 16),
        const Text(
          "AI Safety Summary by Location",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (aiData.isNotEmpty)
          ...aiData.entries.map((entry) {
            final location = entry.key;
            final details = entry.value is Map<String, dynamic>
                ? entry.value as Map<String, dynamic>
                : <String, dynamic>{};
            final problem = details['problem'] ?? "No problem data";
            final actions = details['actions'] ?? "No action suggestions";

            return Card(
              color: Colors.grey.shade50,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: Colors.blueAccent),
                        const SizedBox(width: 8),
                        Text(
                          location,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Problem:",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                    ),
                    Text(problem),
                    const SizedBox(height: 6),
                    const Text(
                      "Suggested Actions:",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    Text(actions),
                  ],
                ),
              ),
            );
          })
        else
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text("No AI analysis available yet."),
          ),
        const SizedBox(height: 16),
        RecentAccidentsList(reports: widget.reports),
        SafetyIncidentReportCard(
          factoryName: "Factory B - South Plant",
          accidents: widget.accidentsCount,
          incidents: widget.incidentsCount,
          generatedDate: DateTime.now(),
        ),
      ],
    );
  }
}
