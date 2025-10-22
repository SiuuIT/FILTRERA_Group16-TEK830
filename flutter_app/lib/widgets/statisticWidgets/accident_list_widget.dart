// statisticWidgets/accident_list_widget.dart
import 'package:flutter/material.dart';

class RecentAccidentsList extends StatefulWidget {
  // expects a list of maps: [{where, what, category}]
  final List<Map<String, dynamic>> reports;

  const RecentAccidentsList({super.key, required this.reports});

  @override
  State<RecentAccidentsList> createState() => _RecentAccidentsListState();
}

class _RecentAccidentsListState extends State<RecentAccidentsList> {
  late List<Map<String, dynamic>> visible;
  String? selectedCategory; // null | 'accident' | 'incident'

  @override
  void initState() {
    super.initState();
    visible = List<Map<String, dynamic>>.from(widget.reports);
  }

  @override
  void didUpdateWidget(covariant RecentAccidentsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.reports, widget.reports)) {
      // refresh visible list when new data arrives
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

                    return ListTile(
                      title: Text(where),
                      subtitle: Text(what),
                      trailing: Chip(
                        label: Text(
                          category.isEmpty ? 'N/A' : category.toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: _categoryColor(category),
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
        return Colors.red.shade500;     // red for accident
      case 'incident':
        return Colors.green.shade500;   // green for incident
      default:
        return Colors.grey.shade400;
    }
  }
}
