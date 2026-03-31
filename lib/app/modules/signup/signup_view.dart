// ─────────────────────────────────────────────────────────────────────────────
// app/modules/signup/signup_view.dart
// Stitch Screen ID: 188ae21af22d4056aa5246c5cb012521 (390×838)
// Title: "Create Account / Join ChildSafety today"
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_input_field.dart';
import 'signup_controller.dart';

class SignupView extends GetView<SignupController> {
  const SignupView({super.key});

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
            _SignupHero(),

            // ── Form (scrollable) ────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                  child: Form(
                    key: controller.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Child Name
                        AppInputField(
                          label: "Child's Name",
                          hint: "Enter child's full name",
                          controller: controller.childNameCtrl,
                          keyboardType: TextInputType.name,
                          validator: controller.nameValidator,
                          prefix: Icon(
                            Icons.child_care_rounded,
                            color: AppColors.primaryContainer,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Email
                        AppInputField(
                          label: 'Parent Email',
                          hint: 'Enter your email address',
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
                          hint: 'Create a strong password',
                          controller: controller.passwordCtrl,
                          obscureText: true,
                          validator: controller.passwordValidator,
                          prefix: Icon(
                            Icons.lock_outline_rounded,
                            color: AppColors.primaryContainer,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Terms note
                        _TermsNote(),
                        const SizedBox(height: 32),

                        // Register Button
                        Obx(() => AppButton(
                          label: 'Create Account',
                          isLoading: controller.isLoading.value,
                          onPressed: controller.register,
                        )),
                        const SizedBox(height: 28),

                        // Already have account
                        Center(
                          child: RichText(
                            text: TextSpan(
                              style: AppTextStyles.bodyMd(
                                color: AppColors.onSurfaceVariant,
                              ),
                              children: [
                                const TextSpan(text: 'Already have an account?  '),
                                WidgetSpan(
                                  child: GestureDetector(
                                    onTap: controller.goToLogin,
                                    child: Text(
                                      'Log In',
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

                        const SizedBox(height: 32),

                        // Quote card
                        _QuoteCard(),
                      ],
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

// ── Signup Hero ───────────────────────────────────────────────────────────────
class _SignupHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.gradientHero,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
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
                  // Back + Logo row
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2), width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 16,
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
                  const SizedBox(height: 28),
                  Text(
                    'Create Account',
                    style: AppTextStyles.headlineLg(color: AppColors.onPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join ChildSafety today',
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


// ── Terms note ────────────────────────────────────────────────────────────────
class _TermsNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'By registering, you agree to our Terms of Service and acknowledge that your data is protected by end-to-end encryption.',
      style: AppTextStyles.bodySm(color: AppColors.onSurfaceVariant),
    );
  }
}

// ── Quote Card ────────────────────────────────────────────────────────────────
class _QuoteCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryFixed.withValues(alpha: 0.5),
            AppColors.secondaryFixed.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primaryFixed.withValues(alpha: 0.6), width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('💬', style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '"Your peace of mind is our priority."',
                  style: AppTextStyles.titleSm(
                    color: AppColors.onPrimaryFixed,
                  ).copyWith(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 6),
                Text(
                  '— ChildSafety Team',
                  style: AppTextStyles.labelMd(
                    color: AppColors.onPrimaryFixedVar,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
