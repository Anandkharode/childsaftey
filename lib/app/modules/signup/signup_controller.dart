// ─────────────────────────────────────────────────────────────────────────────
// app/modules/signup/signup_controller.dart
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../routes/app_routes.dart';

class SignupController extends GetxController {
  final formKey          = GlobalKey<FormState>();
  final childNameCtrl    = TextEditingController();
  final emailCtrl        = TextEditingController();
  final passwordCtrl     = TextEditingController();
  final RxBool isLoading = false.obs;

  @override
  void onClose() {
    childNameCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.onClose();
  }

  Future<void> register() async {
    if (!formKey.currentState!.validate()) return;
    isLoading.value = true;
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text,
      );
      
      Get.snackbar(
        'Success', 'Account created successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF004E32),
        colorText: Colors.white,
      );
      
      Get.offNamed(AppRoutes.login);
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Signup Failed', e.message ?? 'Unknown error occurred.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFBA1A1A),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void goToLogin() => Get.offNamed(AppRoutes.login);

  String? nameValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter child\'s name';
    return null;
  }

  String? emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter email';
    if (!GetUtils.isEmail(v.trim())) return 'Enter a valid email address';
    return null;
  }

  String? passwordValidator(String? v) {
    if (v == null || v.isEmpty) return 'Please enter your password';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }
}
