import 'package:flutter/material.dart';

// ------------------ MODEL ------------------
class HeatPoint {
  final String area;
  final double x;
  final double y;
  final double count;
  final double severity;

  HeatPoint({
    required this.area,
    required this.x,
    required this.y,
    required this.count,
    required this.severity,
  });
}

class FactoryLayout {
  final String imageAsset;
  final List<HeatPoint> points;

  FactoryLayout({required this.imageAsset, required this.points});
}

// ------------------ MAIN SCREEN ------------------
class FactoryHeatmapMVP extends StatelessWidget {
  final Map<String, dynamic> heatmapData;
  final List<Map<String, dynamic>> reports; 
  const FactoryHeatmapMVP({
    super.key,
    required this.heatmapData,
    required this.reports, // !!
  });

  Map<String, Offset> get _locationCoordinates => {
        'Warehouse Zone A': const Offset(0.10, 0.65),
        'Warehouse Zone B': const Offset(0.30, 0.65),
        'Loading Dock': const Offset(0.22, 0.37),
        'Maintenance Bay': const Offset(0.45, 0.35),
        'Storage Yard': const Offset(0.45, 0.09),
        'Wood Cutting Section': const Offset(0.77, 0.10),
        'Finishing Line': const Offset(0.45, 0.55),
        'Packaging Line': const Offset(0.50, 0.82),
        'Assembly Area': const Offset(0.77, 0.46),
        'Varnish Room': const Offset(0.69, 0.80),
      };

  @override
  Widget build(BuildContext context) {
    final points = _generateHeatPoints(heatmapData);

    final factory = FactoryLayout(
      imageAsset: 'assets/images/factory.jpg',
      points: points,
    );

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black12,
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: InteractiveViewer(
            boundaryMargin: const EdgeInsets.all(50),
            minScale: 0.5,
            maxScale: 4.0,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final height = constraints.maxHeight;

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(factory.imageAsset, fit: BoxFit.contain),
                      ...factory.points.map((p) {
                        return Positioned(
                          left: p.x * width,
                          top: p.y * height,
                          child: _HeatPointWidget(
                            point: p,
                            allReports: reports,
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

      List<HeatPoint> _generateHeatPoints(Map<String, dynamic> data) {
    if (data.isEmpty) return [];

    // get set of valid areas that actually exist in reports
    final reportedAreas = reports
        .map((r) => (r['where'] ?? '').toString().trim().toLowerCase())
        .where((r) => r.isNotEmpty)
        .toSet();

    // find max values for normalization
    final validEntries = data.entries.where((entry) {
      final areaName = entry.key.toString().trim().toLowerCase();
      final count = (entry.value['count'] ?? 0);
      return reportedAreas.contains(areaName) && (count is num && count > 0);
    }).toList();

    if (validEntries.isEmpty) return [];

    final maxCount = validEntries
        .map((v) => (v.value['count'] ?? 0).toDouble())
        .fold<double>(0, (a, b) => a > b ? a : b);

    final maxSeverity = validEntries
        .map((v) => (v.value['avg_severity'] ?? 0).toDouble())
        .fold<double>(0, (a, b) => a > b ? a : b);

    // now create points only for truly existing reported areas
    return validEntries.map((entry) {
      final area = entry.key;
      final value = entry.value as Map<String, dynamic>;

      final count = (value['count'] ?? 0).toDouble();
      if (count <= 0) return null;

      final avgSeverity = (value['avg_severity'] ?? 0).toDouble();
      final pos = _locationCoordinates[area];
      if (pos == null) return null;

      final normalizedSeverity =
          maxSeverity == 0 ? 0.0 : (avgSeverity / maxSeverity).clamp(0.0, 1.0);

      return HeatPoint(
        area: area,
        x: pos.dx,
        y: pos.dy,
        count: count,
        severity: normalizedSeverity,
      );
    }).whereType<HeatPoint>().toList();
  }


}

// ------------------ POINT WIDGET ------------------
class _HeatPointWidget extends StatefulWidget {
  final HeatPoint point;
  final List<Map<String, dynamic>> allReports; // !! added field for all reports
  const _HeatPointWidget({
    required this.point,
    required this.allReports, // !!
  });

  @override
  State<_HeatPointWidget> createState() => _HeatPointWidgetState();
}

class _HeatPointWidgetState extends State<_HeatPointWidget> {
  bool _hovering = false;
  OverlayEntry? _popupEntry;

  Color get _baseColor => HSVColor.lerp(
        HSVColor.fromColor(Colors.green),
        HSVColor.fromColor(Colors.red),
        widget.point.severity,
      )!
          .toColor();

  @override
  void dispose() {
    _removePopup();
    super.dispose();
  }

  void _removePopup() {
    _popupEntry?.remove();
    _popupEntry = null;
  }

  void _showPopup(BuildContext context) {
  // !! filter reports for this area
  final matchingReports = widget.allReports
      .where((r) =>
          (r['where'] ?? '').toString().toLowerCase() ==
          widget.point.area.toLowerCase())
      .toList();

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFFF8F8F8),
      title: Text(widget.point.area,
          style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 280,
        height: 260,
        child: Scrollbar(
          thumbVisibility: true,
          radius: const Radius.circular(6),
          child: ListView.builder(
            itemCount: matchingReports.length,
            itemBuilder: (context, index) {
              final r = matchingReports[index];
              final category = r['category'] ?? 'unknown';
              final severity = r['severity'] ?? '-';
              final what = r['what'] ?? '';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      category == 'accident' ? Icons.warning : Icons.info,
                      color: category == 'accident'
                          ? Colors.red
                          : Colors.orange,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${category[0].toUpperCase()}${category.substring(1)} (Severity $severity)\n$what',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.grey,
          ),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}


  double _calculateSize(double count) {
    const minSize = 40.0;
    const maxSize = 120.0;
    final scaled = (count / 10).clamp(0.0, 1.0);
    return minSize + scaled * (maxSize - minSize);
  }

  @override
  Widget build(BuildContext context) {
    final color = _baseColor.withOpacity(0.75);
    final size = _calculateSize(widget.point.count);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showPopup(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: _hovering ? size * 1.1 : size,
          height: _hovering ? size * 1.1 : size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 2),
            boxShadow: _hovering
                ? [BoxShadow(color: Colors.black38, blurRadius: 10, spreadRadius: 2)]
                : [],
          ),
        ),
      ),
    );
  }
}

// ------------------ POPUP INFO BOX ------------------
class _InfoBox extends StatelessWidget {
  final String area;
  final VoidCallback onClose;
  final List<Map<String, dynamic>> reports; // !! added to display real reports

  const _InfoBox({
    required this.area,
    required this.onClose,
    required this.reports, // !!
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      color: Colors.white,
      child: Container(
        width: 260,
        height: 240,
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    area,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, size: 18),
                  splashRadius: 18,
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                radius: const Radius.circular(6),
                child: ListView.builder(
                  itemCount: reports.length, 
                  itemBuilder: (context, index) {
                    final r = reports[index]; 
                    final category = r['category'] ?? 'unknown'; 
                    final severity = r['severity'] ?? '-'; 
                    final what = r['what'] ?? ''; 

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            category == 'accident'
                                ? Icons.warning
                                : Icons.info,
                            color: category == 'accident'
                                ? Colors.red
                                : Colors.orange,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${category[0].toUpperCase()}${category.substring(1)} (Severity $severity)\n$what',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
