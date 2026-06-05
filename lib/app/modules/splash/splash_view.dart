// ─────────────────────────────────────────────────────────────────────────────
// app/modules/splash/splash_view.dart
// Stitch Screen ID: befa734bd3f44ed98b0c6415e77bd785 (390×884)
// Title: "ChildSafety - Splash Screen"
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: AppColors.gradientHero,
          ),
          child: Stack(
            children: [
              // ── Decorative blobs ────────────────────────────────────────
              Positioned(
                top: -60, right: -60,
                child: _Blob(
                  size: 280,
                  color: AppColors.primaryContainer.withValues(alpha: 0.35),
                  duration: const Duration(seconds: 8),
                ),
              ),
              Positioned(
                bottom: 80, left: -40,
                child: _Blob(
                  size: 200,
                  color: AppColors.tertiaryContainer.withValues(alpha: 0.2),
                  duration: const Duration(seconds: 10),
                ),
              ),
              Positioned(
                bottom: 220, right: 20,
                child: _Blob(
                  size: 130,
                  color: AppColors.primaryFixedDim.withValues(alpha: 0.15),
                  duration: const Duration(seconds: 7),
                ),
              ),

              // ── Grid dot texture ────────────────────────────────────────
              Positioned.fill(
                child: CustomPaint(painter: _DotGridPainter()),
              ),

              // ── Main content ────────────────────────────────────────────
              SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                    const Spacer(flex: 2),

                    // Shield Logo
                    _ShieldLogo(),
                    const SizedBox(height: 32),

                    // App Name
                    RichText(
                      text: TextSpan(
                        style: AppTextStyles.displayMd(
                          color: AppColors.onPrimary,
                        ).copyWith(fontSize: 36, fontWeight: FontWeight.w800),
                        children: [
                          const TextSpan(text: 'Child'),
                          TextSpan(
                            text: 'Safety',
                            style: TextStyle(
                              color: AppColors.tertiaryFixedDim,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tagline
                    Text(
                      'Protecting your child, always',
                      style: AppTextStyles.bodyLg(
                        color: AppColors.onPrimary.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Feature Pills
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: const [
                        _FeaturePill('🔔 Real-time Alerts'),
                        _FeaturePill('🔒 E2E Encrypted'),
                        _FeaturePill('🕐 24/7 Monitoring'),
                      ],
                    ),

                    const Spacer(flex: 2),

                    // Loading bar
                    Obx(() => _LoadingBar(progress: controller.progress.value)),
                    const SizedBox(height: 20),

                    Text(
                      'SECURED BY CHILDSAFETY™',
                      style: AppTextStyles.labelSm(
                        color: AppColors.onPrimary.withValues(alpha: 0.3),
                      ).copyWith(letterSpacing: 0.12),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shield Logo ──────────────────────────────────────────────────────────────
class _ShieldLogo extends StatefulWidget {
  @override
  State<_ShieldLogo> createState() => _ShieldLogoState();
}

class _ShieldLogoState extends State<_ShieldLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0, end: 20).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) => Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: AppColors.primaryContainer.withValues(alpha: 
                (_pulse.value / 20) * 0.25,
              ),
              blurRadius: 40,
              spreadRadius: _pulse.value,
            ),
          ],
        ),
        child: child,
      ),
      child: Center(
        child: CustomPaint(
          size: const Size(64, 64),
          painter: _ShieldPainter(),
        ),
      ),
    );
  }
}

// Shield Painter
class _ShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width * 0.5, size.height * 0.05)
      ..lineTo(size.width * 0.09, size.height * 0.22)
      ..lineTo(size.width * 0.09, size.height * 0.47)
      ..cubicTo(
        size.width * 0.09, size.height * 0.72,
        size.width * 0.29, size.height * 0.9,
        size.width * 0.5, size.height * 0.96,
      )
      ..cubicTo(
        size.width * 0.71, size.height * 0.9,
        size.width * 0.91, size.height * 0.72,
        size.width * 0.91, size.height * 0.47,
      )
      ..lineTo(size.width * 0.91, size.height * 0.22)
      ..close();

    canvas.drawPath(path, paint);

    // Checkmark
    final checkPaint = Paint()
      ..color = AppColors.primaryContainer
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final checkPath = Path()
      ..moveTo(size.width * 0.28, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.66)
      ..lineTo(size.width * 0.72, size.height * 0.38);

    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Loading Bar ──────────────────────────────────────────────────────────────
class _LoadingBar extends StatelessWidget {
  final double progress;
  const _LoadingBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 3,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(100),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: AppColors.tertiaryFixedDim,
            borderRadius: BorderRadius.circular(100),
          ),
        ),
      ),
    );
  }
}

// ── Feature Pill ─────────────────────────────────────────────────────────────
class _FeaturePill extends StatelessWidget {
  final String label;
  const _FeaturePill(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ── Blob ─────────────────────────────────────────────────────────────────────
class _Blob extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;
  const _Blob({required this.size, required this.color, required this.duration});

  @override
  State<_Blob> createState() => _BlobState();
}

class _BlobState extends State<_Blob> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
    _a = Tween<double>(begin: 0.95, end: 1.08)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, __) => Transform.scale(
        scale: _a.value,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}

// ── Dot Grid Painter ─────────────────────────────────────────────────────────
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeCap = StrokeCap.round;
    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
