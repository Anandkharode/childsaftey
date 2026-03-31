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
          child: Stack(
            children: [
              child!,
              Positioned(
                bottom: 80,
                right: 20,
                child: Material(
                  color: Colors.transparent,
                  child: FloatingActionButton(
                    heroTag: 'dev_menu',
                    backgroundColor: Colors.black87,
                    mini: true,
                    onPressed: () {
                      Get.bottomSheet(
                        Container(
                          color: Colors.white,
                          child: SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text('Dev Menu (Skip Auth) - All Screens', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                ListTile(title: const Text('Splash Screen'), onTap: () => Get.offAllNamed(AppRoutes.splash)),
                                ListTile(title: const Text('Login Screen'), onTap: () => Get.offAllNamed(AppRoutes.login)),
                                ListTile(title: const Text('Signup Screen'), onTap: () => Get.offAllNamed(AppRoutes.signup)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    child: const Icon(Icons.developer_mode, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
