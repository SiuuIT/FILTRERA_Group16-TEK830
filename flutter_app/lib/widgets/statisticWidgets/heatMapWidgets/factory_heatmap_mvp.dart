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
  const FactoryHeatmapMVP({super.key});

  @override
  Widget build(BuildContext context) {
    final factory = FactoryLayout(
      imageAsset: 'assets/images/factory.jpg',
      points: [
        HeatPoint(x: 0.2, y: 0.3, intensity: 0.7),
        HeatPoint(x: 0.4, y: 0.6, intensity: 0.5),
        HeatPoint(x: 0.7, y: 0.4, intensity: 0.9),
        HeatPoint(x: 0.8, y: 0.8, intensity: 0.3),
        HeatPoint(x: 0.5, y: 0.2, intensity: 1.0),
      ],
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
                  // 🔥 Background factory layout image
                  Image.asset(
                    factory.imageAsset,
                    fit: BoxFit.contain, // was cover – contain works better for scaled view
                  ),

                  // 🔥 Heatmap overlay
                  CustomPaint(painter: HeatmapPainter(factory.points)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            _getColorForIntensity(p.intensity).withOpacity(0.7),
            Colors.transparent,
          ],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: position, radius: 80));

      canvas.drawCircle(position, 80, paint);
    }
  }

  Color _getColorForIntensity(double value) {
    return HSVColor.lerp(
      HSVColor.fromColor(Colors.blue),
      HSVColor.fromColor(Colors.red),
      value.clamp(0.0, 1.0),
    )!
        .toColor();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
