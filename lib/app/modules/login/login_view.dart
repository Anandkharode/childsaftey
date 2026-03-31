// ─────────────────────────────────────────────────────────────────────────────
// app/modules/login/login_view.dart
// Stitch Screen ID: 08d07b8575d249f5bcfc976614bceb4a (390×884)
// Title: "ChildSafety - Login" | "Welcome Back / Login to keep your child safe."
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_input_field.dart';
import 'login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Column(
          children: [
            // ── Hero Header ─────────────────────────────────────────────
            _LoginHero(),

            // ── Form Card (scrollable) ───────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                    child: Form(
                      key: controller.formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Email
                          AppInputField(
                            label: 'Email Address',
                            hint: 'Enter your email',
                            controller: controller.emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            validator: controller.emailValidator,
                            prefix: Icon(
                              Icons.email_outlined,
                              color: AppColors.primaryContainer,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Password
                          AppInputField(
                            label: 'Password',
                            hint: 'Enter your password',
                            controller: controller.passwordCtrl,
                            obscureText: true,
                            validator: controller.passwordValidator,
                            prefix: Icon(
                              Icons.lock_outline_rounded,
                              color: AppColors.primaryContainer,
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ── Security badge ─────────────────────────────
                          _SecurityBadge(),
                          const SizedBox(height: 32),

                          // ── Login Button ───────────────────────────────
                          Obx(() => AppButton(
                            label: 'Login',
                            isLoading: controller.isLoading.value,
                            onPressed: controller.login,
                          )),
                          const SizedBox(height: 28),

                          // ── Divider ────────────────────────────────────
                          _Divider(),
                          const SizedBox(height: 28),

                          // ── Signup link ────────────────────────────────
                          Center(
                            child: RichText(
                              text: TextSpan(
                                style: AppTextStyles.bodyMd(
                                  color: AppColors.onSurfaceVariant,
                                ),
                                children: [
                                  const TextSpan(text: "Don't have an account? "),
                                  WidgetSpan(
                                    child: GestureDetector(
                                      onTap: controller.goToSignup,
                                      child: Text(
                                        'Sign Up',
                                        style: AppTextStyles.bodyMd(
                                          color: AppColors.primaryContainer,
                                        ).copyWith(fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ── Encrypted note ─────────────────────────────
                          _EncryptedNote(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Login Hero ────────────────────────────────────────────────────────────────
class _LoginHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.gradientHero,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(36),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Dot texture
            Positioned.fill(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(36)),
                child: CustomPaint(painter: _DotPainter()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mini logo
                  Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2), width: 1,
                          ),
                        ),
                        child: Center(
                          child: CustomPaint(
                            size: const Size(20, 20),
                            painter: _MiniShieldPainter(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                          children: [
                            const TextSpan(
                                text: 'Child',
                                style: TextStyle(color: Colors.white)),
                            TextSpan(
                              text: 'Safety',
                              style: TextStyle(
                                  color: AppColors.tertiaryFixedDim),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),

                  // Title
                  Text(
                    'Welcome Back',
                    style: AppTextStyles.headlineLg(
                      color: AppColors.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Login to keep your child safe.',
                    style: AppTextStyles.bodyLg(
                      color: AppColors.onPrimary.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ── Security Badge ─────────────────────────────────────────────────────────────
class _SecurityBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.tertiaryContainer.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.tertiaryContainer.withValues(alpha: 0.2), width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.tertiaryContainer,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Your data is protected by end-to-end encryption',
            style: AppTextStyles.labelMd(
              color: AppColors.onTertiaryFixedVar,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Divider ────────────────────────────────────────────────────────────────────
class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: AppTextStyles.labelMd().copyWith(
              letterSpacing: 0.08,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}

// ── Encrypted Note ─────────────────────────────────────────────────────────────
class _EncryptedNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded,
              size: 18, color: AppColors.primaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'We use industry-standard encryption to protect your account and your child\'s data.',
              style: AppTextStyles.bodySm(color: AppColors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

// Painters
class _DotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeCap = StrokeCap.round;
    const sp = 24.0;
    for (double x = 0; x < size.width; x += sp) {
      for (double y = 0; y < size.height; y += sp) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _MiniShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width * 0.5, 0)
      ..lineTo(0, size.height * 0.25)
      ..lineTo(0, size.height * 0.5)
      ..quadraticBezierTo(
        0, size.height * 0.85, size.width * 0.5, size.height,
      )
      ..quadraticBezierTo(
        size.width, size.height * 0.85, size.width, size.height * 0.5,
      )
      ..lineTo(size.width, size.height * 0.25)
      ..close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_) => false;
}
