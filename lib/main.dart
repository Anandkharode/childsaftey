// ─────────────────────────────────────────────────────────────────────────────
// main.dart – ChildSafety App Entry Point
// Framework: Flutter + GetX
// Design: Stitch Project 1654352290469224973
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'app/core/theme/app_theme.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Lock to portrait mode
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status + nav bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(const ChildSafetyApp());
}

class ChildSafetyApp extends StatelessWidget {
  const ChildSafetyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'ChildSafety',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: AppRoutes.splash,
      getPages: AppPages.routes,
      defaultTransition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
      // Edge-to-edge rendering
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
          child: child!,
        );
      },
    );
  }
}
