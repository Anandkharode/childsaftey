// ─────────────────────────────────────────────────────────────────────────────
// app/modules/signup/signup_binding.dart
// ─────────────────────────────────────────────────────────────────────────────
import 'package:get/get.dart';
import 'signup_controller.dart';

class SignupBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SignupController>(() => SignupController());
  }
}
