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

  const FactoryHeatmapMVP({super.key, required this.heatmapData});

  Map<String, Offset> get _locationCoordinates => {
        'Warehouse Zone A': const Offset(0.10, 0.70),
        'Warehouse Zone B': const Offset(0.30, 0.70),
        'Loading Dock': const Offset(0.25, 0.43),
        'Maintenance Bay': const Offset(0.45, 0.40),
        'Storage Yard': const Offset(0.45, 0.17),
        'Wood Cutting Section': const Offset(0.80, 0.15),
        'Finishing Line': const Offset(0.51, 0.65),
        'Packaging Line': const Offset(0.51, 0.90),
        'Assembly Area': const Offset(0.80, 0.55),
        'Varnish Room': const Offset(0.70, 0.85),
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
                          child: _HeatPointWidget(point: p),
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

    final maxCount = data.values
        .map((v) => (v['count'] ?? 0).toDouble())
        .fold<double>(0, (a, b) => a > b ? a : b);

    final maxSeverity = data.values
        .map((v) => (v['avg_severity'] ?? 0).toDouble())
        .fold<double>(0, (a, b) => a > b ? a : b);

    return data.entries.map((entry) {
      final area = entry.key;
      final value = entry.value as Map<String, dynamic>;
      final count = (value['count'] ?? 0).toDouble();
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
  const _HeatPointWidget({required this.point});

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
    _removePopup();
    final renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    _popupEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx + 70,
        top: position.dy - 20,
        child: _InfoBox(area: widget.point.area, onClose: _removePopup),
      ),
    );

    Overlay.of(context).insert(_popupEntry!);
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
  const _InfoBox({required this.area, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final items = List.generate(
      15,
      (i) => {
        'category': i.isEven ? 'Accident' : 'Incident',
        'severity': (i % 10 + 1).toString(),
        'what': 'Example report #$i in $area',
      },
    );

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      color: Colors.white,
      child: Container(
        width: 240,
        height: 200,
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(area,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
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
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final r = items[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            r['category'] == 'Accident'
                                ? Icons.warning
                                : Icons.info,
                            color: r['category'] == 'Accident'
                                ? Colors.red
                                : Colors.orange,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${r['category']} (Severity ${r['severity']})\n${r['what']}',
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
