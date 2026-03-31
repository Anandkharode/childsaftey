// ─────────────────────────────────────────────────────────────────────────────
// app/modules/splash/splash_controller.dart
// ─────────────────────────────────────────────────────────────────────────────
import 'package:get/get.dart';
import '../../routes/app_routes.dart';

class SplashController extends GetxController {
  final RxDouble progress = 0.0.obs;

  @override
  void onReady() {
    super.onReady();
    _startSplash();
  }

  Future<void> _startSplash() async {
    // Animate loading bar
    await Future.delayed(const Duration(milliseconds: 400));
    progress.value = 0.45;
    await Future.delayed(const Duration(milliseconds: 600));
    progress.value = 0.72;
    await Future.delayed(const Duration(milliseconds: 500));
    progress.value = 1.0;
    await Future.delayed(const Duration(milliseconds: 700));
    Get.offAllNamed(AppRoutes.login);
  }
}
