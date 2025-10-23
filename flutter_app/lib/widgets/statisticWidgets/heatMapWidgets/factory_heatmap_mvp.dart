import 'package:flutter/material.dart';

// ------------------ MODEL ------------------
class HeatPoint {
  final double x; // normalized 0–1
  final double y; // normalized 0–1
  final double intensity; // 0–1

  HeatPoint({required this.x, required this.y, required this.intensity});
}

class FactoryLayout {
  final String imageAsset;
  final List<HeatPoint> points;

  FactoryLayout({required this.imageAsset, required this.points});
}

// ------------------ MAIN SCREEN ------------------
class FactoryHeatmapMVP extends StatelessWidget {
  final Map<String, dynamic> locationCounts; // from backend JSON

  const FactoryHeatmapMVP({super.key, required this.locationCounts});

  // --- Map each area name to approximate coordinates on the image ---
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
    final points = _generateHeatPoints(locationCounts);

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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background factory layout image
                  Image.asset(
                    factory.imageAsset,
                    fit: BoxFit.contain,
                  ),
                  // Heatmap overlay
                  CustomPaint(painter: HeatmapPainter(factory.points)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Generate heat points dynamically from backend data ---
  List<HeatPoint> _generateHeatPoints(Map<String, dynamic> counts) {
    if (counts.isEmpty) return [];

    final maxValue = counts.values
        .map((e) => e as num)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return counts.entries.map((entry) {
      final area = entry.key;
      final count = (entry.value as num).toDouble();
      final normalized = (count / maxValue).clamp(0.0, 1.0);

      final pos = _locationCoordinates[area];
      if (pos == null) return null; // skip unknown areas

      return HeatPoint(x: pos.dx, y: pos.dy, intensity: normalized);
    }).whereType<HeatPoint>().toList();
  }
}

// ------------------ HEATMAP PAINTER ------------------
class HeatmapPainter extends CustomPainter {
  final List<HeatPoint> points;

  HeatmapPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in points) {
      final position = Offset(p.x * size.width, p.y * size.height);

      // Radius scales with intensity: 5px (low) → 50x (high)
      final radius = 5 + (p.intensity * 50);

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            _getColorForIntensity(p.intensity).withOpacity(0.8),
            Colors.transparent,
          ],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: position, radius: radius));

      canvas.drawCircle(position, radius, paint);
    }
  }

  // Color transitions smoothly between yellow (low) and red (high)
  Color _getColorForIntensity(double value) {
    return HSVColor.lerp(
      HSVColor.fromColor(Colors.green),
      HSVColor.fromColor(Colors.red),
      value.clamp(0.0, 1.0),
    )!
        .toColor();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
