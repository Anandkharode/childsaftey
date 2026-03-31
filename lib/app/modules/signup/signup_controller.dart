// ─────────────────────────────────────────────────────────────────────────────
// app/modules/signup/signup_controller.dart
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../routes/app_routes.dart';

class SignupController extends GetxController {
  final formKey       = GlobalKey<FormState>();
  final childNameCtrl = TextEditingController();
  final emailCtrl     = TextEditingController();
  final passwordCtrl  = TextEditingController();

  final RxBool isLoading        = false.obs;
  final RxBool obscurePassword  = true.obs;

  @override
  void onClose() {
    childNameCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  Future<void> register() async {
    if (!formKey.currentState!.validate()) return;
    isLoading.value = true;
    try {
      // 1️⃣  Create the Firebase Auth user
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text,
      );

      final user = credential.user!;

      // 2️⃣  Update the display name in Auth
      await user.updateDisplayName(childNameCtrl.text.trim());

      // 3️⃣  Persist all info to Firestore → users/{uid}
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid':          user.uid,
        'childName':    childNameCtrl.text.trim(),
        'email':        emailCtrl.text.trim(),
        'createdAt':    FieldValue.serverTimestamp(),
        'provider':     'email_password',
      });

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
    } catch (e) {
      Get.snackbar(
        'Error', 'Something went wrong. Please try again.',
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
