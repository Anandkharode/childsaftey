import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'main_controller.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/safety_zone.dart';

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
                _SafetyZoneSelector(),
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

class _SafetyZoneSelector extends GetView<MainController> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Safety Zone', style: AppTextStyles.titleMd(color: Colors.white)),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [..._buildZoneCards(context)]),
        ),
      ],
    );
  }

  List<Widget> _buildZoneCards(BuildContext context) {
    return [
      SafetyZone.nearChild,
      SafetyZone.sameRoom,
      SafetyZone.homeZone,
      SafetyZone.extendedZone,
    ].map((zone) {
      return Obx(() {
        final isSelected = controller.selectedSafetyZone.value == zone;
        final bgColor = isSelected
            ? const Color(0xFF2A7F5A)
            : const Color(0xFF0F1F3A);
        final borderColor = isSelected
            ? const Color(0xFF7BE4A5)
            : const Color(0xFF3A5A7F);

        return GestureDetector(
          onTap: () => controller.saveSelectedZone(zone),
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(zone.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 6),
                Text(
                  zone.displayName,
                  style: AppTextStyles.labelSm(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      });
    }).toList();
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
      final isOutOfZone = controller.isBoundaryExceeded.value;

      // Status-based colors
      late Color bannerColor;
      late Color borderColor;
      late Color iconBgColor;
      late IconData iconData;
      late Color statusColor;
      late String statusText;

      if (isOutOfZone) {
        bannerColor = const Color(0xFF3A1F1F);
        borderColor = const Color.fromARGB(
          255,
          230,
          123,
          123,
        ).withValues(alpha: 0.4);
        iconBgColor = const Color(0xFFB82A2A);
        iconData = Icons.error_rounded;
        statusColor = const Color(0xFFE47B7B);
        statusText = '🔴 OUT OF RANGE!';
      } else {
        bannerColor = const Color(0xFF2F3B56);
        borderColor = Colors.white12;
        iconBgColor = const Color(0xFF2A7F5A);
        iconData = Icons.check_circle_rounded;
        statusColor = const Color(0xFF7BE4A5);
        statusText = '🟢 ${controller.childName.value} is Safe';
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bannerColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: isOutOfZone ? 1.5 : 1),
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
              child: Icon(iconData, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                statusText,
                style: AppTextStyles.titleMd(color: statusColor),
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
          // Active Safety Zone Display
          Obx(() {
            final zone = controller.selectedSafetyZone.value;
            final status = controller.currentStatus.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Active Safety Zone',
                      style: AppTextStyles.bodySm(color: Colors.white70),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A7F5A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: AppTextStyles.labelSm(
                          color: const Color(0xFF7BE4A5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${zone.emoji} ${zone.displayName}',
                  style: AppTextStyles.titleMd(color: Colors.white),
                ),
              ],
            );
          }),
          const SizedBox(height: 16),

          // Direction Display
          Obx(() {
            final direction = controller.directionLabel.value;
            final directionDisplay =
                direction.isEmpty || direction == "Disconnected"
                ? 'Direction: --'
                : 'Direction: $direction';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  directionDisplay,
                  style: AppTextStyles.bodySm(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          }),
          const SizedBox(height: 16),

          // WiFi Signal Strength Display
          Obx(() {
            final wifiRssi = controller.currentWifiRssi.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF5ACEFF), width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'WiFi Signal',
                    style: AppTextStyles.bodySm(color: Colors.white70),
                  ),
                  Text(
                    wifiRssi != null ? '$wifiRssi dBm' : 'N/A',
                    style: AppTextStyles.titleSm(
                      color: const Color(0xFF5ACEFF),
                    ),
                  ),
                ],
              ),
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
                        selectedZone: controller.selectedSafetyZone.value,
                        currentStatus: controller.currentStatus.value,
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
  final SafetyZone selectedZone;
  final String currentStatus;

  _RadarPainter({
    required this.heading,
    required this.distance,
    required this.selectedZone,
    required this.currentStatus,
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

    // Draw grid circles
    for (int i = 1; i <= 5; i++) {
      canvas.drawCircle(center, maxRadius * 0.2 * i, gridPaint);
    }

    // ─ Draw selected safety zone circles ─
    _drawSafetyZoneCircles(canvas, center, maxRadius);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF5ACEFF)
      ..strokeWidth = 2.4;

    // Keep the tracker bead visible even when the calculated value is tiny.
    final double visualDistance = distance < 0.75 ? 0.75 : distance;

    // Scale the tracker position to the radar.
    final double maxDistanceForScale = 15.0; // Extended zone max
    final double distanceScale = (visualDistance / maxDistanceForScale).clamp(
      0.0,
      1.0,
    );

    final double angleRad = (heading - 90) * math.pi / 180.0;
    final double dx = maxRadius * distanceScale * math.cos(angleRad);
    final double dy = maxRadius * distanceScale * math.sin(angleRad);
    final end = Offset(center.dx + dx, center.dy + dy);

    // Draw tracker line
    canvas.drawLine(center, end, linePaint);

    // Draw Tracker Bead with status color
    late Color beadColor;
    switch (currentStatus) {
      case 'SAFE':
        beadColor = const Color(0xFF7BE4A5); // Green
        break;
      case 'WARNING':
        beadColor = const Color(0xFFFFC857); // Yellow
        break;
      case 'OUT_OF_RANGE':
        beadColor = const Color(0xFFE47B7B); // Red
        break;
      default:
        beadColor = const Color(0xFFB0B0B0); // Gray
    }

    final beadPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = beadColor;
    canvas.drawCircle(end, 6.0, beadPaint);
  }

  /// Draw safety zone circles based on selected zone
  void _drawSafetyZoneCircles(Canvas canvas, Offset center, double maxRadius) {
    final zoneFactor = selectedZone.radarCircleFactor;

    // Draw the selected zone boundary circle
    final zoneBoundaryPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = Color(selectedZone.displayColor).withValues(alpha: 0.6);
    canvas.drawCircle(center, maxRadius * zoneFactor, zoneBoundaryPaint);

    // Draw the zone boundary fill (highlight area)
    final zoneFillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Color(selectedZone.displayColor).withValues(alpha: 0.06);
    canvas.drawCircle(center, maxRadius * zoneFactor, zoneFillPaint);

    // Label for the zone
    final labelStyle = const TextStyle(
      color: Color.fromRGBO(255, 255, 255, 0.7),
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );
    final textPainter = TextPainter(
      text: TextSpan(text: selectedZone.displayName, style: labelStyle),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Position label at top of zone circle
    final labelOffset = Offset(
      center.dx - textPainter.width / 2,
      center.dy - maxRadius * zoneFactor - 30,
    );
    textPainter.paint(canvas, labelOffset);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.heading != heading ||
        oldDelegate.distance != distance ||
        oldDelegate.selectedZone != selectedZone ||
        oldDelegate.currentStatus != currentStatus;
  }
}
