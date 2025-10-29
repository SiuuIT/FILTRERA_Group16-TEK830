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
  final bool isRefreshing;

  StatisticsAreaWidget({
    Key? key,
    required Map<String, dynamic> aggregates,
    required this.aiAnswer,
    this.locationCounts,
    required this.reports,
    this.isRefreshing = false,
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

  String _selectedCategory = 'all'; // !!
  List<Map<String, dynamic>> _filteredReports = []; // !!

  @override
  void initState() {
    super.initState();
    _filteredReports = widget.reports; // !!
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
      setState(() {
        isDataLoaded = false;
        _filteredReports = widget.reports; // !!
      });
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

  // !! filter toggle handler
  void _updateCategoryFilter(String newCategory) {
    setState(() {
      _selectedCategory = newCategory;
      if (newCategory == 'all') {
        _filteredReports = widget.reports;
      } else {
        _filteredReports = widget.reports
            .where((r) => (r['category'] ?? '').toString().toLowerCase() == newCategory)
            .toList();
      }
    });
  }

  // !! recompute map intensity based on filtered type
  Map<String, dynamic> _buildFilteredHeatmapData() {
    if (widget.locationCounts == null) return {};

    if (_selectedCategory == 'all') {
      return widget.locationCounts!;
    }

    final Map<String, dynamic> newData = {};
    final filtered = widget.reports
        .where((r) => (r['category'] ?? '').toString().toLowerCase() == _selectedCategory)
        .toList();

    for (var r in filtered) {
      final where = (r['where'] ?? '').toString().trim();
      final sev = (r['severity'] ?? 0);
      if (where.isEmpty) continue;

      if (!newData.containsKey(where)) {
        newData[where] = {'count': 0, 'total_severity': 0.0};
      }
      newData[where]['count'] += 1;
      newData[where]['total_severity'] +=
          (sev is num ? sev.toDouble() : double.tryParse(sev.toString()) ?? 0.0);
    }

    for (final entry in newData.entries) {
      final total = entry.value['total_severity'] as double;
      final count = entry.value['count'] as int;
      entry.value['avg_severity'] = count == 0 ? 0.0 : total / count;
      entry.value.remove('total_severity');
    }

    return newData;
  }

  // !! build legend UI
  Widget _buildLegendBar() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text("Risk Level: ", style: TextStyle(fontWeight: FontWeight.w600)),
              _legendDot(Colors.yellow.shade600),
              const SizedBox(width: 4),
              const Text("Low (1–3)"),
              const SizedBox(width: 12),
              _legendDot(Colors.orange.shade700),
              const SizedBox(width: 4),
              const Text("Medium (4–6)"),
              const SizedBox(width: 12),
              _legendDot(Colors.red.shade700),
              const SizedBox(width: 4),
              const Text("High (7–10)"),
            ],
          ),
          const Text(
            "Larger circles = More I&A events  ℹ️",
            style: TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  // !! helper for dots
  Widget _legendDot(Color color) {
    return Container(
      width: 14,
      height: 14,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black54, width: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aiData = (widget.aiAnswer is Map<String, dynamic>)
        ? widget.aiAnswer as Map<String, dynamic>
        : {};

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
        // section title
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

        const SizedBox(height: 8),

        // !! category toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ChoiceChip(
              label: const Text('All'),
              selected: _selectedCategory == 'all',
              onSelected: (_) => _updateCategoryFilter('all'),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Accidents'),
              selected: _selectedCategory == 'accident',
              onSelected: (_) => _updateCategoryFilter('accident'),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Incidents'),
              selected: _selectedCategory == 'incident',
              onSelected: (_) => _updateCategoryFilter('incident'),
            ),
          ],
        ),

        // !! legend
        _buildLegendBar(),

        // !! heatmap
        FactoryHeatmapMVP(
          heatmapData: _buildFilteredHeatmapData(),
          reports: _filteredReports,
        ),

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
