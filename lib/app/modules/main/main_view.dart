import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'main_controller.dart';
import '../../core/theme/app_text_styles.dart';

class MainView extends GetView<MainController> {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07121F),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DashboardHeader(),
                const SizedBox(height: 18),
                _StatusBanner(),
                const SizedBox(height: 20),
                _StatusCard(),
                const SizedBox(height: 22),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.45, 
                  child: _RadarCard(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends GetView<MainController> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Child Safety', style: AppTextStyles.headlineLg(color: Colors.white)),
            const SizedBox(height: 6),
            Text('Realtime tracker dashboard', style: AppTextStyles.bodySm(color: Colors.white70)),
          ],
        ),
        GestureDetector(
          onTap: controller.toggleBluetooth,
          child: Obx(() {
            final active = controller.isConnected.value || controller.isScanning.value;
            final color = active ? const Color(0xFF144C1C) : const Color(0xFF331F2A);
            final dotColor = active ? const Color(0xFF7AE09D) : const Color(0xFFE47B7B);
            
            String btnText = 'Connect';
            if (controller.isConnected.value) btnText = 'Connected';
            else if (controller.isScanning.value) btnText = 'Scanning...';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dotColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(btnText, style: AppTextStyles.bodySm(color: Colors.white)),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _StatusBanner extends GetView<MainController> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF2F3B56),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF8C4A03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(() => Text(
              'Child is heading ${controller.directionLabel.value} (${controller.distance.value}m)',
              style: AppTextStyles.titleMd(color: Colors.white),
            )),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends GetView<MainController> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1F3A),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Child in Safe Range', style: AppTextStyles.titleMd(color: const Color(0xFF7BE4A5))),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Obx(() => Text('${controller.distance.value}', style: AppTextStyles.displayMd(color: Colors.white))),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('m', style: AppTextStyles.titleMd(color: const Color(0xFF7BE4A5))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Distance from Anchor', style: AppTextStyles.bodySm(color: Colors.white70)),
              Row(
                children: List.generate(5, (index) {
                  final levelColor = index < 4 ? const Color(0xFF7BE4A5) : const Color(0xFF2F4360);
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 8,
                    height: 24 - index * 3,
                    decoration: BoxDecoration(
                      color: levelColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              )
            ],
          ),
          const SizedBox(height: 6),
          Text('Signal Strength', style: AppTextStyles.labelMd(color: Colors.white54)),
        ],
      ),
    );
  }
}

class _RadarCard extends GetView<MainController> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B33),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Obx(() => CustomPaint(
                    painter: _RadarPainter(
                      heading: controller.headingAngle.value,
                      distance: controller.distance.value,
                    ),
                    child: const SizedBox.expand(),
                  )),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D314D),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.home, color: Color(0xFF7BE4A5), size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF101F39),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF7BE4A5),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Home Base', style: AppTextStyles.titleMd(color: Colors.white), overflow: TextOverflow.ellipsis),
                              Text('Anchor', style: AppTextStyles.labelSm(color: Colors.white54), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF5ACEFF),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Child Name', style: AppTextStyles.titleMd(color: Colors.white), overflow: TextOverflow.ellipsis),
                              Text('Child', style: AppTextStyles.labelSm(color: Colors.white54), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double heading;
  final double distance;

  _RadarPainter({required this.heading, required this.distance});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.stroke;
    
    // Confine radii to the smallest dimension to never overflow the box
    final maxRadius = (size.width < size.height ? size.width : size.height) / 2.0 * 0.95;

    for (int i = 1; i <= 5; i++) {
      paint.color = Color.fromRGBO(255, 255, 255, 0.08 * (6 - i));
      paint.strokeWidth = 1.2;
      canvas.drawCircle(center, maxRadius * 0.2 * i, paint);
    }

    paint.color = Color.fromRGBO(90, 206, 255, 0.65);
    paint.strokeWidth = 2;
    canvas.drawCircle(center, maxRadius * 0.75, paint);

    final radarPaint = Paint()
      ..color = Color.fromRGBO(90, 206, 255, 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center.translate(maxRadius * 0.35, -maxRadius * 0.25), 10, radarPaint);

    paint
      ..color = const Color(0xFF5ACEFF)
      ..strokeWidth = 2.3;
    
    // Convert heading degrees to radians, where 0 degrees is North (top)
    final double angleRad = (heading - 90) * math.pi / 180.0;
    
    // Scale distance based on max supported distance (5m)
    final double distanceScale = (distance / 5.0).clamp(0.0, 1.0);

    final double dx = maxRadius * distanceScale * math.cos(angleRad);
    final double dy = maxRadius * distanceScale * math.sin(angleRad);
    final end = Offset(center.dx + dx, center.dy + dy);
    canvas.drawLine(center, end, paint);

    final arrowPaint = Paint()..color = const Color(0xFF5ACEFF);
    final double angle = math.atan2(dy, dx);
    final double arrowSize = 14.0;
    
    final Path arrowPath = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(end.dx - arrowSize * math.cos(angle - math.pi / 7), end.dy - arrowSize * math.sin(angle - math.pi / 7))
      ..lineTo(end.dx - arrowSize * math.cos(angle + math.pi / 7), end.dy - arrowSize * math.sin(angle + math.pi / 7))
      ..close();
    canvas.drawPath(arrowPath, arrowPaint);

    final labelStyle = const TextStyle(color: Colors.white54, fontSize: 11);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 1; i <= 5; i++) {
      textPainter.text = TextSpan(text: '${i}m', style: labelStyle);
      textPainter.layout();
      // Draw labels vertically along the top center axis to avoid the house box
      final offset = Offset(center.dx - textPainter.width / 2, center.dy - maxRadius * 0.2 * i - textPainter.height / 2);
      textPainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.heading != heading || oldDelegate.distance != distance;
  }
}

