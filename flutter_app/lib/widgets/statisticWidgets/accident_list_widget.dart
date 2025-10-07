import 'package:flutter/material.dart';

class RecentAccidentsList extends StatefulWidget {
  final List<Map<String, String>> allAccidents;

  const RecentAccidentsList({super.key, required this.allAccidents});

  @override
  State<RecentAccidentsList> createState() => _RecentAccidentsListState();
}

class _RecentAccidentsListState extends State<RecentAccidentsList> {
  late List<Map<String, String>> visibleAccidents;
  String? selectedSeverity;

  @override
  void initState() {
    super.initState();
    // Start with showing all
    visibleAccidents = widget.allAccidents;
  }

  void _filterBySeverity(String? severity) {
    setState(() {
      selectedSeverity = severity;

      if (severity == null) {
        // Show all
        visibleAccidents = widget.allAccidents;
      } else {
        // Filter accidents dynamically
        visibleAccidents = widget.allAccidents
            .where((a) => a['severity']?.toLowerCase() == severity)
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //  Simple dropdown for filtering
        DropdownButton<String?>(
          value: selectedSeverity,
          hint: const Text('Filter by severity'),
          items: const [
            DropdownMenuItem(value: null, child: Text('All')),
            DropdownMenuItem(value: 'high', child: Text('High')),
            DropdownMenuItem(value: 'medium', child: Text('Medium')),
            DropdownMenuItem(value: 'low', child: Text('Low')),
          ],
          onChanged: _filterBySeverity,
        ),

        const SizedBox(height: 8),

        // The scrollable list
        Container(
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            itemCount: visibleAccidents.length,
            itemBuilder: (context, index) {
              final accident = visibleAccidents[index];
              return ListTile( //list tile is a prebuilt widget each item 
                title: Text(accident['location'] ?? ''), //?? ''means if null show empty string
                subtitle: Text(accident['type'] ?? ''),
                trailing: Chip( // trailing is the thing on the right side 
                  label: Text(
                    (accident['severity'] ?? '').toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: _severityColor(accident['severity']),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _severityColor(String? level) {
    switch (level?.toLowerCase()) {
      case 'high':
        return Colors.red.shade400;
      case 'medium':
        return Colors.orange.shade400;
      case 'low':
        return Colors.green.shade400;
      default:
        return Colors.grey.shade400;
    }
  }
}
