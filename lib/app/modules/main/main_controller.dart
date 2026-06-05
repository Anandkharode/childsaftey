import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/tracking_zone.dart';
import '../../models/safety_zone.dart';
import '../../routes/app_routes.dart';

class MainController extends GetxController {
  static const String boundaryAlertAsset = 'audio/boundary_alert.mp3';
  static const String _selectedZoneKey = 'selected_safety_zone';

  // Reactive properties that the view will listen to
  final distance = 2.0.obs;
  final headingAngle = 0.0.obs; // In degrees
  final directionLabel = "Disconnected".obs;
  final childName = "Child".obs;

  final isConnected = false.obs;
  final isScanning = false.obs;
  final isBoundaryExceeded = false.obs; // Track boundary alert state
  final isAlarmPlaying = false.obs; // Track if alarm is currently playing
  final lastAlertTime = DateTime.now().obs; // Prevent alert spam

  // ─ Zone-based tracking properties from ESP32 ─
  final currentZone = TrackingZone.disconnected.obs;
  final currentWifiRssi = RxnInt(); // WiFi RSSI value received from ESP32

  // ─ Preset Safety Zone properties ─
  final selectedSafetyZone = SafetyZone.sameRoom.obs;
  final isApproachingBoundary = false.obs; // Warning state at 80%
  final distanceStatus = "Disconnected".obs; // Status text for dashboard
  final currentStatus = "SAFE".obs; // SAFE, WARNING, OUT_OF_RANGE

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  BluetoothDevice? _espDevice;
  final AudioPlayer _alertPlayer = AudioPlayer();

  bool _previousBoundaryExceeded = false;

  static const String serviceUuid = "12345678-1234-1234-1234-123456789abc";
  static const String characteristicUuid =
      "87654321-4321-4321-4321-cba987654321";

  @override
  void onInit() {
    super.onInit();
    loadSelectedZone();
    loadChildProfile();
    startBleScan();
  }

  @override
  void onClose() {
    _scanSubscription?.cancel();
    _espDevice?.disconnect();
    _alertPlayer.stop();
    _alertPlayer.dispose();
    super.onClose();
  }

  void toggleBluetooth() {
    if (isConnected.value || isScanning.value) {
      FlutterBluePlus.stopScan();
      _stopBoundaryAlarm();
      _espDevice?.disconnect();
      isScanning.value = false;
      isConnected.value = false;
      directionLabel.value = "Disconnected";
    } else {
      startBleScan();
    }
  }

  Future<void> loadChildProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      childName.value = "Child";
      return;
    }

    final authName = user.displayName?.trim();
    if (authName != null && authName.isNotEmpty) {
      childName.value = authName;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final firestoreName = doc.data()?['childName']?.toString().trim();
      if (firestoreName != null && firestoreName.isNotEmpty) {
        childName.value = firestoreName;
      }
    } catch (_) {
      // Keep the Auth display name fallback if Firestore is unavailable.
    }
  }

  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      childName.value = "Child";
      isConnected.value = false;
      isScanning.value = false;
      directionLabel.value = "Disconnected";
      await _stopBoundaryAlarm();
      await _espDevice?.disconnect();
      Get.offAllNamed(AppRoutes.login);
    } catch (_) {
      Get.snackbar(
        'Logout Failed',
        'Unable to log out right now. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ─ Preset Safety Zone Methods ─

  /// Load selected safety zone from SharedPreferences
  Future<void> loadSelectedZone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final zoneString = prefs.getString(_selectedZoneKey);
      if (zoneString != null) {
        selectedSafetyZone.value = SafetyZoneExtension.fromStorageString(
          zoneString,
        );
      } else {
        // Default to "Same Room" (5m)
        selectedSafetyZone.value = SafetyZone.sameRoom;
        await saveSelectedZone(SafetyZone.sameRoom);
      }
      debugPrint(
        'Loaded selected zone: ${selectedSafetyZone.value.displayName}',
      );
    } catch (e) {
      debugPrint('Error loading selected zone: $e');
      selectedSafetyZone.value = SafetyZone.sameRoom;
    }
  }

  /// Save selected safety zone to SharedPreferences
  Future<void> saveSelectedZone(SafetyZone zone) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedZoneKey, zone.storageKey);
      selectedSafetyZone.value = zone;
      debugPrint('Saved selected zone: ${zone.displayName}');
    } catch (e) {
      debugPrint('Error saving selected zone: $e');
    }
  }

  /// Calculate distance from WiFi RSSI (in meters)
  /// Using WiFi RSSI to approximate distance:
  /// RSSI > -55 dBm = ~2m (close)
  /// RSSI -55 to -70 dBm = ~5m (medium)
  /// RSSI -70 to -85 dBm = ~10m (far)
  /// RSSI < -85 dBm = ~15m (very far)
  double _calculateDistanceFromRssi(int rssi) {
    if (rssi > -58) return 2.0;
    if (rssi > -90) return 5.0;
    if (rssi > -120) return 10.0;
    return 15.0;
  }

  /// Check if child is within selected safety zone
  /// Returns: 0 = in zone, 1 = approaching (80%), 2 = out of zone
  int _checkZoneBoundary(double currentDistance) {
    final zoneRadius = selectedSafetyZone.value.radiusInMeters;
    final warningThreshold = zoneRadius * 0.8; // 80% of radius

    if (currentDistance <= warningThreshold) {
      return 0; // In zone
    } else if (currentDistance <= zoneRadius) {
      return 1; // Approaching boundary
    } else {
      return 2; // Out of zone
    }
  }

  /// Update status based on distance and selected zone
  void _updateBoundaryStatus(double currentDistance) {
    final boundaryCheck = _checkZoneBoundary(currentDistance);

    late String statusText;
    switch (boundaryCheck) {
      case 0:
        // In zone - SAFE
        statusText = selectedSafetyZone.value.displayName;
        isApproachingBoundary.value = false;
        currentStatus.value = 'SAFE';
        break;
      case 1:
        // Still inside the selected zone.
        statusText = selectedSafetyZone.value.displayName;
        isApproachingBoundary.value = false;
        currentStatus.value = 'SAFE';
        break;
      case 2:
        // Out of zone - OUT_OF_RANGE
        statusText = 'OUT OF RANGE - ${selectedSafetyZone.value.displayName}';
        isApproachingBoundary.value = false;
        currentStatus.value = 'OUT_OF_RANGE';
        break;
    }

    distanceStatus.value = statusText;

    // Check for boundary transitions to trigger alerts
    _handleBoundaryTransition(boundaryCheck);
  }

  /// Handle boundary transitions and trigger alerts
  void _handleBoundaryTransition(int newBoundaryStatus) {
    // Status codes: 0=safe, 1=warning, 2=out
    final wasInZone = !_previousBoundaryExceeded; // 0 or 1
    final isNowOutOfZone = newBoundaryStatus == 2;

    if (wasInZone && isNowOutOfZone) {
      // Transition: IN → OUT (critical alert)
      _triggerBoundaryAlert(true);
      isBoundaryExceeded.value = true;
      _previousBoundaryExceeded = true;
    } else if (!wasInZone && !isNowOutOfZone) {
      // Transition: OUT → IN (success alert)
      _triggerBoundaryAlert(false);
      isBoundaryExceeded.value = false;
      _previousBoundaryExceeded = false;
    }
  }

  /// Trigger boundary exceeded or safe return alert
  Future<void> _triggerBoundaryAlert(bool isCritical) async {
    try {
      if (isCritical) {
        // Critical alert - child left the zone
        await _startBoundaryAlarmLoop();

        // Strong vibration pattern (4 pulses)
        for (int i = 0; i < 4; i++) {
          HapticFeedback.vibrate();
          if (i < 3) await Future.delayed(const Duration(milliseconds: 150));
        }
      } else {
        // Safe return - child returned to zone
        await _stopBoundaryAlarm();

        // Gentle vibration pattern (2 pulses)
        HapticFeedback.vibrate();
        await Future.delayed(const Duration(milliseconds: 200));
        HapticFeedback.vibrate();
      }
    } catch (e) {
      debugPrint('Boundary alert error: $e');
    }
  }

  Future<void> _startBoundaryAlarmLoop() async {
    if (isAlarmPlaying.value) return;

    try {
      isAlarmPlaying.value = true;
      await _alertPlayer.stop();
      await _alertPlayer.setReleaseMode(ReleaseMode.loop);
      await _alertPlayer.play(AssetSource(boundaryAlertAsset));
    } catch (e) {
      isAlarmPlaying.value = false;
      debugPrint('Boundary alert sound error: $e');
    }
  }

  Future<void> _stopBoundaryAlarm() async {
    try {
      isAlarmPlaying.value = false;
      await _alertPlayer.stop();
      await _alertPlayer.setReleaseMode(ReleaseMode.release);
    } catch (e) {
      debugPrint('Boundary alarm stop error: $e');
    }
  }

  Future<void> startBleScan() async {
    isScanning.value = true;
    directionLabel.value = "Starting...";

    // 1. Request permissions for Android seamlessly
    await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    // 2. Wait for adapter to turn on
    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      try {
        if (GetPlatform.isAndroid) {
          directionLabel.value = "Turning on BT...";
          await FlutterBluePlus.turnOn();
          await Future.delayed(const Duration(seconds: 2));
        } else {
          directionLabel.value = "Please turn on BT";
          isScanning.value = false;
          return;
        }
      } catch (e) {
        directionLabel.value = "BT Error";
        isScanning.value = false;
        return;
      }

      // Check again if it successfully connected
      if (await FlutterBluePlus.adapterState.first !=
          BluetoothAdapterState.on) {
        directionLabel.value = "Bluetooth is off";
        isScanning.value = false;
        return;
      }
    }

    directionLabel.value = "Scanning ESP32...";

    // 3. Scan for "ESP32_Compass"
    _scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.platformName == "ESP32_Compass" ||
            r.advertisementData.advName == "ESP32_Compass") {
          FlutterBluePlus.stopScan();
          _connectToDevice(r.device);
          break;
        }
      }
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

    // Auto-timeout hook
    Future.delayed(const Duration(seconds: 15), () {
      if (!isConnected.value && directionLabel.value == "Scanning ESP32...") {
        isScanning.value = false;
        directionLabel.value = "Scan Timeout";
      }
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    directionLabel.value = "Linking...";
    _espDevice = device;

    // Listen to device connection state
    device.connectionState.listen((dynamic state) {
      if (state.toString().toLowerCase().contains('disconnected')) {
        directionLabel.value = "Disconnected";
        isConnected.value = false;
        isScanning.value = false;
        // Reset on disconnect
        currentZone.value = TrackingZone.disconnected;
        currentWifiRssi.value = null;
        currentStatus.value = 'DISCONNECTED';
        distanceStatus.value = 'Disconnected';
        if (!isBoundaryExceeded.value) {
          _stopBoundaryAlarm();
        }
      }
    });

    try {
      await device.connect();
      directionLabel.value = "Connected";
      isConnected.value = true;
      isScanning.value = false;

      // 4. Discover BLE Services and our specific UUID
      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        if (service.uuid.toString() == serviceUuid) {
          for (BluetoothCharacteristic c in service.characteristics) {
            if (c.uuid.toString() == characteristicUuid) {
              // 5. Start receiving notifications!
              await c.setNotifyValue(true);
              listenToBleData(c);
            }
          }
        }
      }
    } catch (e) {
      directionLabel.value = "Error connecting";
    }
  }

  /// Function to process incoming BLE data from the ESP32.
  /// Expected format: heading,direction,wifiRssi,zone
  /// Example: 45.2,North-East,-62,SAFE
  void listenToBleData(BluetoothCharacteristic characteristic) {
    characteristic.lastValueStream.listen((value) async {
      if (value.isEmpty) return;

      try {
        String data = utf8.decode(value);
        List<String> parts = data.split(',');

        if (parts.length >= 4) {
          double heading = double.parse(parts[0]);
          String direction = parts[1].trim();
          int wifiRssi = int.parse(parts[2].trim());
          // String zoneString = parts[3].trim().toUpperCase(); // Not used in new preset system

          // Update heading and direction (compass data)
          headingAngle.value = heading;
          directionLabel.value = direction;

          // Update WiFi RSSI
          currentWifiRssi.value = wifiRssi;

          // Calculate distance from WiFi RSSI
          double calculatedDistance = _calculateDistanceFromRssi(wifiRssi);
          distance.value = calculatedDistance;

          // Update boundary status based on selected zone
          _updateBoundaryStatus(calculatedDistance);

          // Debug output
          debugPrint(
            '═══ BLE DATA RECEIVED ═══\n'
            'Heading: ${heading.toStringAsFixed(1)}°\n'
            'Direction: $direction\n'
            'WiFi RSSI: $wifiRssi dBm\n'
            'Selected Zone: ${selectedSafetyZone.value.displayName}\n'
            'Status: ${currentStatus.value}\n'
            '═════════════════════════',
          );
        }
      } catch (e) {
        debugPrint("BLE Decode Error: $e");
      }
    });
  }
}
