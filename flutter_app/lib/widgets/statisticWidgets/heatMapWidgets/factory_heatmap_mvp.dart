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
      imageAsset: 'assets/images/factory.jpg', // ensure the file exists here
      points: [
        HeatPoint(x: 0.2, y: 0.3, intensity: 0.7),
        HeatPoint(x: 0.4, y: 0.6, intensity: 0.5),
        HeatPoint(x: 0.7, y: 0.4, intensity: 0.9),
        HeatPoint(x: 0.8, y: 0.8, intensity: 0.3),
        HeatPoint(x: 0.5, y: 0.2, intensity: 1.0),
      ],
    );

    // Fill whatever space the parent provides (no fixed height here)
    return LayoutBuilder(
      builder: (context, constraints) {
        // If parent gives unbounded height/width, limit to something sensible:
        final w = constraints.maxWidth.isFinite ? constraints.maxWidth : MediaQuery.of(context).size.width;
        final h = constraints.maxHeight.isFinite ? constraints.maxHeight : MediaQuery.of(context).size.height * 0.5;

        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: w,
            height: h,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  factory.imageAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) {
                    return Container(
                      color: Colors.grey.shade200,
                      child: const Center(child: Text('Image not found')),
                    );
                  },
                ),
                CustomPaint(
                  size: Size(w, h),
                  painter: HeatmapPainter(factory.points),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ------------------ HEATMAP PAINTER ------------------
class HeatmapPainter extends CustomPainter {
  final List<HeatPoint> points;

  HeatmapPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final baseRadius = size.shortestSide * 0.12; // scale with widget size
    for (var p in points) {
      final position = Offset(p.x * size.width, p.y * size.height);
      final radius = baseRadius * (0.6 + p.intensity * 1.4); // vary by intensity
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            _getColorForIntensity(p.intensity).withOpacity(0.75),
            Colors.transparent,
          ],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: position, radius: radius));

      canvas.drawCircle(position, radius, paint);
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
