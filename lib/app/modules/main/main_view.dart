import 'dart:math' as math;
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
            Obx(() => Text(
              '${controller.childName.value}\'s realtime tracker dashboard',
              style: AppTextStyles.bodySm(color: Colors.white70),
            )),
          ],
        ),
        GestureDetector(
          onTap: controller.toggleBluetooth,
          child: Obx(() {
            final active = controller.isConnected.value || controller.isScanning.value;
            final color = active ? const Color(0xFF144C1C) : const Color(0xFF331F2A);
            final dotColor = active ? const Color(0xFF7AE09D) : const Color(0xFFE47B7B);
            
            String btnText = 'Connect';
            if (controller.isConnected.value) {
              btnText = 'Connected';
            } else if (controller.isScanning.value) {
              btnText = 'Scanning...';
            }

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
    return Obx(() {
      final isExceeded = controller.isBoundaryExceeded.value;
      final bannerColor = isExceeded ? const Color(0xFF3A1F1F) : const Color(0xFF2F3B56);
      final borderColor = isExceeded
          ? const Color.fromARGB(255, 230, 123, 123).withValues(alpha: 0.4)
          : Colors.white12;
      final iconBgColor = isExceeded ? const Color(0xFFB82A2A) : const Color(0xFF8C4A03);
      final childName = controller.childName.value;
      final warningText = isExceeded 
        ? '$childName is out of safe range!'
        : '$childName is heading ${controller.directionLabel.value} (${controller.distance.value}m)';
      
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bannerColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: isExceeded ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isExceeded ? Icons.error_rounded : Icons.warning_amber_rounded, 
                color: Colors.white, 
                size: 18
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                warningText,
                style: AppTextStyles.titleMd(
                  color: isExceeded ? const Color(0xFFE47B7B) : Colors.white
                ),
                softWrap: true,
              ),
            ),
          ],
        ),
      );
    });
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
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(() => Text(
                controller.distance.value <= controller.boundaryDistance.value 
                  ? '${controller.childName.value} in Safe Range' 
                  : 'Out of Range!', 
                style: AppTextStyles.titleMd(
                  color: controller.distance.value <= controller.boundaryDistance.value 
                    ? const Color(0xFF7BE4A5) 
                    : const Color(0xFFE47B7B),
                )
              )),
              Obx(() => Text(
                'Max: ${controller.boundaryDistance.value.toStringAsFixed(1)}m', 
                style: AppTextStyles.bodySm(color: Colors.white70)
              )),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Obx(() => Text('${controller.distance.value}', style: AppTextStyles.displayMd(color: Colors.white))),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('m', style: AppTextStyles.titleMd(color: Colors.white70)),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Obx(() => Slider(
                  value: controller.boundaryDistance.value,
                  min: 1.0,
                  max: 5.0,
                  divisions: 8,
                  activeColor: const Color(0xFF5ACEFF),
                  inactiveColor: Colors.white12,
                  onChanged: (val) {
                    controller.boundaryDistance.value = val;
                  },
                )),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Distance from Anchor', style: AppTextStyles.bodySm(color: Colors.white70)),
              Obx(() {
                // Determine signal bars inversely mapped to the 5-meter max span
                int bars = 5 - (controller.distance.value).floor();
                bars = bars.clamp(0, 5); // Fallback bounds between 0 and 5 bars

                return Row(
                  children: List.generate(5, (index) {
                    final levelColor = index < bars ? const Color(0xFF7BE4A5) : const Color(0xFF2F4360);
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
                );
              }),
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
                      boundaryDistance: controller.boundaryDistance.value,
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
                              Obx(() => Text(
                                controller.childName.value,
                                style: AppTextStyles.titleMd(color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              )),
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
  final double boundaryDistance;

  _RadarPainter({required this.heading, required this.distance, required this.boundaryDistance});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Confine radii to never overflow the box
    final maxRadius = (size.width < size.height ? size.width : size.height) / 2.0 * 0.95;

    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color.fromRGBO(255, 255, 255, 0.12);

    // Draw grid natively
    for (int i = 1; i <= 5; i++) {
      canvas.drawCircle(center, maxRadius * 0.2 * i, gridPaint);
    }

    // Draw boundary ring natively
    final boundaryPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color.fromRGBO(90, 206, 255, 0.8)
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, maxRadius * (boundaryDistance / 5.0), boundaryPaint);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF5ACEFF)
      ..strokeWidth = 2.4;
    
    // Enforce visual distance
    final double visualDistance = distance < 0.75 ? 0.75 : distance;
    final double distanceScale = (visualDistance / 5.0).clamp(0.0, 1.0);

    final double angleRad = (heading - 90) * math.pi / 180.0;
    final double dx = maxRadius * distanceScale * math.cos(angleRad);
    final double dy = maxRadius * distanceScale * math.sin(angleRad);
    final end = Offset(center.dx + dx, center.dy + dy);

    // Draw tracker line
    canvas.drawLine(center, end, linePaint);

    // Draw Tracker Bead
    final beadPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF5ACEFF);
    canvas.drawCircle(end, 6.0, beadPaint);

    // Labels
    final labelStyle = const TextStyle(color: Colors.white54, fontSize: 11);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 1; i <= 5; i++) {
      textPainter.text = TextSpan(text: '${i}m', style: labelStyle);
      textPainter.layout();
      final offset = Offset(center.dx - textPainter.width / 2, center.dy - maxRadius * 0.2 * i - textPainter.height / 2);
      textPainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.heading != heading || 
           oldDelegate.distance != distance || 
           oldDelegate.boundaryDistance != boundaryDistance;
  }
}

