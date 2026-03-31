import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'main_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class MainView extends GetView<MainController> {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.widgets_rounded, size: 80, color: AppColors.primaryContainer),
            const SizedBox(height: 16),
            Text(
              'Main Placeholder',
              style: AppTextStyles.headlineMd(),
            ),
          ],
        ),
      ),
    );
  }
}
