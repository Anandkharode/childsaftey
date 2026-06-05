import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'main_controller.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/tracking_zone.dart';

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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Child Safety',
                style: AppTextStyles.headlineLg(color: Colors.white),
              ),
              const SizedBox(height: 6),
              Obx(
                () => Text(
                  '${controller.childName.value}\'s realtime tracker dashboard',
                  style: AppTextStyles.bodySm(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: controller.toggleBluetooth,
              child: Obx(() {
                final active =
                    controller.isConnected.value || controller.isScanning.value;
                final color = active
                    ? const Color(0xFF144C1C)
                    : const Color(0xFF331F2A);
                final dotColor = active
                    ? const Color(0xFF7AE09D)
                    : const Color(0xFFE47B7B);

                String btnText = 'Connect';
                if (controller.isConnected.value) {
                  btnText = 'Connected';
                } else if (controller.isScanning.value) {
                  btnText = 'Scanning...';
                }

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
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
                      Text(
                        btnText,
                        style: AppTextStyles.bodySm(color: Colors.white),
                      ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                onPressed: controller.logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3A1F1F),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: Text(
                  'Logout',
                  style: AppTextStyles.bodySm(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusBanner extends GetView<MainController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final zone = controller.currentZone.value;
      final isOutOfRange = zone == TrackingZone.outOfRange;

      // Zone-based colors
      final bannerColor = isOutOfRange
          ? const Color(0xFF3A1F1F)
          : zone == TrackingZone.warning
          ? const Color(0xFF3A3018)
          : const Color(0xFF2F3B56);

      final borderColor = isOutOfRange
          ? const Color.fromARGB(255, 230, 123, 123).withValues(alpha: 0.4)
          : zone == TrackingZone.warning
          ? const Color.fromARGB(255, 255, 200, 87).withValues(alpha: 0.4)
          : Colors.white12;

      final iconBgColor = isOutOfRange
          ? const Color(0xFFB82A2A)
          : zone == TrackingZone.warning
          ? const Color(0xFFD4944B)
          : const Color(0xFF2A7F5A);

      final childName = controller.childName.value;
      
      // Zone-based status text and color
      late String statusText;
      late Color statusColor;

      switch (zone) {
        case TrackingZone.safe:
          statusText = '$childName is in SAFE zone';
          statusColor = const Color(0xFF7BE4A5);
          break;
        case TrackingZone.warning:
          statusText = '$childName is in WARNING zone';
          statusColor = const Color(0xFFFFC857);
          break;
        case TrackingZone.outOfRange:
          statusText = '$childName is OUT OF RANGE!';
          statusColor = const Color(0xFFE47B7B);
          break;
        case TrackingZone.disconnected:
          statusText = 'Disconnected from $childName';
          statusColor = const Color(0xFFB0B0B0);
          break;
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bannerColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: isOutOfRange ? 1.5 : 1),
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
                isOutOfRange
                    ? Icons.error_rounded
                    : zone == TrackingZone.warning
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                statusText,
                style: AppTextStyles.titleMd(
                  color: statusColor,
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
          // Direction Display
          Obx(() {
            final direction = controller.directionLabel.value;
            final directionDisplay = direction.isEmpty || direction == "Disconnected"
                ? 'Direction: --'
                : 'Direction: $direction';

            return Text(
              directionDisplay,
              style: AppTextStyles.bodySm(color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          }),
          const SizedBox(height: 16),
          
          // Current Zone Display
          Obx(() {
            final zone = controller.currentZone.value;
            final zoneColor = Color(zone.displayColor);
            
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: zoneColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      zone.displayName,
                      style: AppTextStyles.titleMd(color: zoneColor),
                    ),
                  ],
                ),
              ],
            );
          }),
          const SizedBox(height: 20),
          
          // Zone Slider Control
          Obx(() {
            final distance = controller.distance.value;
            final boundary = controller.boundaryDistance.value;
            // Map distance to zone: 0-2m = Safe, 2-5m = Warning, 5+ = Out of Range
            late String zoneLabel;
            late Color zoneColor;
            
            if (distance <= 2.0) {
              zoneLabel = 'Safe Zone';
              zoneColor = const Color(0xFF7BE4A5);
            } else if (distance <= boundary) {
              zoneLabel = 'Warning Zone';
              zoneColor = const Color(0xFFFFC857);
            } else {
              zoneLabel = 'Out of Range';
              zoneColor = const Color(0xFFE47B7B);
            }
            
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Set Zone for Child',
                      style: AppTextStyles.bodySm(color: Colors.white70),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: zoneColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          zoneLabel,
                          style: AppTextStyles.titleMd(color: zoneColor),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 8.0,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 12.0,
                      elevation: 4.0,
                    ),
                    activeTrackColor: zoneColor,
                    inactiveTrackColor: const Color(0xFF1F3A52),
                    thumbColor: zoneColor,
                  ),
                  child: Slider(
                    value: boundary.clamp(0.0, 10.0),
                    min: 0.0,
                    max: 10.0,
                    divisions: 100,
                    label: 'Boundary',
                    onChanged: (value) {
                      controller.updateBoundaryDistance(value);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Safe',
                      style: AppTextStyles.labelSm(color: const Color(0xFF7BE4A5)),
                    ),
                    Text(
                      'Warning',
                      style: AppTextStyles.labelSm(color: const Color(0xFFFFC857)),
                    ),
                    Text(
                      'Out',
                      style: AppTextStyles.labelSm(color: const Color(0xFFE47B7B)),
                    ),
                  ],
                ),
              ],
            );
          }),
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
                  Obx(
                    () => CustomPaint(
                      painter: _RadarPainter(
                        heading: controller.headingAngle.value,
                        distance: controller.distance.value,
                        boundaryDistance: controller.boundaryDistance.value,
                        zone: controller.currentZone.value,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D314D),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.home,
                      color: Color(0xFF7BE4A5),
                      size: 20,
                    ),
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
                              Text(
                                'Home Base',
                                style: AppTextStyles.titleMd(
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Anchor',
                                style: AppTextStyles.labelSm(
                                  color: Colors.white54,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
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
                              Obx(
                                () => Text(
                                  controller.childName.value,
                                  style: AppTextStyles.titleMd(
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                'Child',
                                style: AppTextStyles.labelSm(
                                  color: Colors.white54,
                                ),
                                overflow: TextOverflow.ellipsis,
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
  final TrackingZone zone;

  _RadarPainter({
    required this.heading,
    required this.distance,
    required this.boundaryDistance,
    required this.zone,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Confine radii to never overflow the box
    final maxRadius =
        (size.width < size.height ? size.width : size.height) / 2.0 * 0.95;

    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color.fromRGBO(255, 255, 255, 0.12);

    // Draw grid natively
    for (int i = 1; i <= 5; i++) {
      canvas.drawCircle(center, maxRadius * 0.2 * i, gridPaint);
    }

    // ─ NEW: Draw zone-based circles with zone colors ─
    _drawZoneCircles(canvas, center, maxRadius);

    // Draw boundary ring natively
    final boundaryPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color.fromRGBO(90, 206, 255, 0.8)
      ..strokeWidth = 2.0;

    final boundaryRadius = maxRadius * ((boundaryDistance / 5.0).clamp(0.0, 1.0));
    canvas.drawCircle(
      center,
      boundaryRadius,
      boundaryPaint,
    );

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

    // Draw Tracker Bead with zone color
    final beadColor = Color(zone.displayColor);
    final beadPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = beadColor;
    canvas.drawCircle(end, 6.0, beadPaint);

    // Labels
    final labelStyle = const TextStyle(color: Colors.white54, fontSize: 11);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 1; i <= 5; i++) {
      textPainter.text = TextSpan(text: '${i}m', style: labelStyle);
      textPainter.layout();
      final offset = Offset(
        center.dx - textPainter.width / 2,
        center.dy - maxRadius * 0.2 * i - textPainter.height / 2,
      );
      textPainter.paint(canvas, offset);
    }
  }

  /// Draw zone-based concentric circles with zone colors
  void _drawZoneCircles(Canvas canvas, Offset center, double maxRadius) {
    // Safe zone circle (0-2m) - Green
    final safePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = const Color(0xFF7BE4A5).withValues(alpha: 0.3);
    canvas.drawCircle(center, maxRadius * 0.2, safePaint);

    // Warning zone circle (2-5m) - Yellow
    final warningPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = const Color(0xFFFFC857).withValues(alpha: 0.25);
    canvas.drawCircle(center, maxRadius * 0.5, warningPaint);

    // Out of range circle (>5m) - Red
    final outOfRangePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = const Color(0xFFE47B7B).withValues(alpha: 0.2);
    canvas.drawCircle(center, maxRadius * 0.8, outOfRangePaint);

    // Highlight the current zone with filled background
    late Paint highlightPaint;
    late double highlightRadius;

    switch (zone) {
      case TrackingZone.safe:
        highlightPaint = Paint()
          ..style = PaintingStyle.fill
          ..color = const Color(0xFF7BE4A5).withValues(alpha: 0.08);
        highlightRadius = maxRadius * 0.2;
        break;
      case TrackingZone.warning:
        highlightPaint = Paint()
          ..style = PaintingStyle.fill
          ..color = const Color(0xFFFFC857).withValues(alpha: 0.08);
        highlightRadius = maxRadius * 0.5;
        break;
      case TrackingZone.outOfRange:
        highlightPaint = Paint()
          ..style = PaintingStyle.fill
          ..color = const Color(0xFFE47B7B).withValues(alpha: 0.1);
        highlightRadius = maxRadius * 0.8;
        break;
      case TrackingZone.disconnected:
        return; // No highlight for disconnected
    }

    canvas.drawCircle(center, highlightRadius, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.heading != heading ||
        oldDelegate.distance != distance ||
        oldDelegate.boundaryDistance != boundaryDistance ||
        oldDelegate.zone != zone;
  }
}
