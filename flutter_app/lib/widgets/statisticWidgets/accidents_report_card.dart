import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SafetyIncidentReportCard extends StatelessWidget {
  final String factoryName;
  final int accidents;
  final int incidents;

  final DateTime generatedDate;

  const SafetyIncidentReportCard({
    super.key,
    required this.factoryName,
    required this.incidents,
    required this.accidents,
    required this.generatedDate,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        DateFormat('MMM dd, yyyy HH:mm').format(generatedDate);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //  Title
          const Text(
            "Safety Incident Report",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            factoryName,
            style: TextStyle(color: Colors.grey[700]),
          ),

          const SizedBox(height: 10),

          //  Top row: Date info
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                "All dates\nGenerated: $formattedDate",
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // --- Removed severity and total event widgets (as requested) ---

          //  Lower summary row (kept)
          Row(
            children: [
              _buildSummaryBox(context,
                  count: accidents, label: "Accidents"),
              const SizedBox(width: 8),
              _buildSummaryBox(context,
                  count: incidents, label: "Incidents"),
            
            ],
          ),
        ],
      ),
    );
  }

  // Helper for individual statistic boxes
  Widget _buildSummaryBox(
    BuildContext context, {
    required int count,
    required String label,
    Color? color,
    Color? textColor,
  }) {
    return Expanded(
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: color ?? Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor ?? Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: textColor ?? Colors.black54,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
