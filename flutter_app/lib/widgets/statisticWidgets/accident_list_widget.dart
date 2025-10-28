// statisticWidgets/accident_list_widget.dart
import 'package:flutter/material.dart';

class RecentAccidentsList extends StatefulWidget {
  final List<Map<String, dynamic>> reports;

  const RecentAccidentsList({super.key, required this.reports});

  @override
  State<RecentAccidentsList> createState() => _RecentAccidentsListState();
}

class _RecentAccidentsListState extends State<RecentAccidentsList> {
  late List<Map<String, dynamic>> visible;
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    visible = List<Map<String, dynamic>>.from(widget.reports);
  }

  @override
  void didUpdateWidget(covariant RecentAccidentsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.reports, widget.reports)) {
      _applyFilter(selectedCategory);
    }
  }

  void _applyFilter(String? category) {
    selectedCategory = category;
    if (category == null) {
      visible = List<Map<String, dynamic>>.from(widget.reports);
    } else {
      visible = widget.reports
          .where((m) =>
              (m['category']?.toString().toLowerCase().trim() ?? '') == category)
          .toList();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<String?>(
          value: selectedCategory,
          hint: const Text('All'),
          items: const [
            DropdownMenuItem<String?>(value: null, child: Text('All')),
            DropdownMenuItem<String?>(value: 'accident', child: Text('Accident')),
            DropdownMenuItem<String?>(value: 'incident', child: Text('Incident')),
          ],
          onChanged: _applyFilter,
        ),
        const SizedBox(height: 8),
        Container(
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: visible.isEmpty
              ? const Center(child: Text('No reports to show'))
              : ListView.builder(
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final r = visible[index];

                    final where = (r['where'] ?? '').toString();
                    final what = (r['what'] ?? '').toString();
                    final category =
                        (r['category'] ?? '').toString().toLowerCase().trim();
                    final severity = (r['severity'] ?? '').toString();

                    return ListTile(
                      title: Text(where),
                      subtitle: Text(what),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Builder(builder: (context) {
                            final color = _categoryColor(category);
                            return Chip(
                              label: Text(
                                category.isEmpty ? 'N/A' : category.toUpperCase(),
                                style: TextStyle(color: color, fontWeight: FontWeight.bold),
                              ),
                              
                              side: BorderSide(color: color),
                              
                              backgroundColor: color.withValues(alpha: 0.15),
                            );
                          }),
                          const SizedBox(width: 6),
                          Builder(builder: (context) {
                            final color = _severityColor(int.tryParse(severity) ?? 0);
                            return Chip(
                              label: Text(
                                'Severity: $severity',
                                style: TextStyle(color: color, fontWeight: FontWeight.bold),
                              ),
                              side: BorderSide(color: color),
                              backgroundColor: color.withValues(alpha: 0.15),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'accident':
        return Colors.redAccent;
      case 'incident':
        return Colors.orangeAccent;
      default:
        return Colors.grey.shade400;
    }
  }

  Color _severityColor(int level) {
    level = level.clamp(1, 10);
    final t = (level - 1) / 9.0;
    if (t < 0.33) {
      return Color.lerp(Colors.green, Colors.yellow, t / 0.33)!;
    } else if (t < 0.66) {
      return Color.lerp(Colors.yellow, Colors.orange, (t - 0.33) / 0.33)!;
    } else {
      return Color.lerp(Colors.orange, Colors.red, (t - 0.66) / 0.34)!;
    }
  }
}
