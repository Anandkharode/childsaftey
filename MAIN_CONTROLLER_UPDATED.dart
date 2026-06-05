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
import '../../models/tracking_zone.dart';
import '../../routes/app_routes.dart';

/// MainController - Manages BLE communication and zone-based child tracking
/// 
/// This controller handles:
/// - BLE device scanning and connection
/// - Receiving zone data directly from ESP32
/// - Radar UI updates based on zone
/// - Alert triggering on zone transitions
/// - Distance mapping and display
class MainController extends GetxController {
  static const String boundaryAlertAsset = 'audio/boundary_alert.mp3';

  // ═════════════════════════════════════════════════════════════
  // REACTIVE PROPERTIES - Watched by the UI
  // ═════════════════════════════════════════════════════════════

  /// Distance to display on dashboard and radar (2m, 5m, or 8m based on zone)
  final distance = 2.0.obs;

  /// Heading angle from compass (in degrees, 0-360)
  final headingAngle = 0.0.obs;

  /// Direction label from compass (e.g., "North", "North-East", "South")
  final directionLabel = "Disconnected".obs;

  /// Child's name from Firebase or auth
  final childName = "Child".obs;

  /// BLE connection status
  final isConnected = false.obs;

  /// BLE scanning status
  final isScanning = false.obs;

  /// Track whether boundary has been exceeded for alert state
  final isBoundaryExceeded = false.obs;

  /// Timestamp of last alert to prevent spam
  final lastAlertTime = DateTime.now().obs;

  /// Current zone state from ESP32 (SAFE, WARNING, OUT_OF_RANGE, DISCONNECTED)
  final currentZone = TrackingZone.disconnected.obs;

  /// WiFi RSSI value received from ESP32 (in dBm)
  final currentWifiRssi = RxnInt();

  // ═════════════════════════════════════════════════════════════
  // PRIVATE PROPERTIES
  // ═════════════════════════════════════════════════════════════

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  BluetoothDevice? _espDevice;
  final AudioPlayer _alertPlayer = AudioPlayer();

  /// Track previous zone to detect transitions for alerts
  TrackingZone _previousZone = TrackingZone.disconnected;

  // ═════════════════════════════════════════════════════════════
  // CONSTANTS - BLE UUIDs
  // ═════════════════════════════════════════════════════════════

  static const String serviceUuid = "12345678-1234-1234-1234-123456789abc";
  static const String characteristicUuid =
      "87654321-4321-4321-4321-cba987654321";

  // ═════════════════════════════════════════════════════════════
  // LIFECYCLE METHODS
  // ═════════════════════════════════════════════════════════════

  @override
  void onInit() {
    super.onInit();
    loadChildProfile();
    startBleScan();
  }

  @override
  void onClose() {
    _scanSubscription?.cancel();
    _espDevice?.disconnect();
    _alertPlayer.dispose();
    super.onClose();
  }

  // ═════════════════════════════════════════════════════════════
  // BLUETOOTH CONTROL METHODS
  // ═════════════════════════════════════════════════════════════

  /// Toggle Bluetooth scanning on/off
  void toggleBluetooth() {
    if (isConnected.value || isScanning.value) {
      FlutterBluePlus.stopScan();
      _espDevice?.disconnect();
      isScanning.value = false;
      isConnected.value = false;
      directionLabel.value = "Disconnected";
    } else {
      startBleScan();
    }
  }

  /// Start scanning for ESP32_Compass BLE device
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

  /// Connect to ESP32 device and setup BLE notifications
  Future<void> _connectToDevice(BluetoothDevice device) async {
    directionLabel.value = "Linking...";
    _espDevice = device;

    // Listen to device connection state
    device.connectionState.listen((dynamic state) {
      if (state.toString().toLowerCase().contains('disconnected')) {
        directionLabel.value = "Disconnected";
        isConnected.value = false;
        isScanning.value = false;
        // Reset zone on disconnect
        currentZone.value = TrackingZone.disconnected;
        _previousZone = TrackingZone.disconnected;
        currentWifiRssi.value = null;
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

  // ═════════════════════════════════════════════════════════════
  // BLE DATA PARSING & ZONE MANAGEMENT
  // ═════════════════════════════════════════════════════════════

  /// Listen to BLE characteristic notifications and parse data
  ///
  /// Expected format from ESP32: heading,direction,wifiRssi,zone
  /// Example: 45.2,North-East,-62,SAFE
  ///
  /// Fields:
  /// - heading: Compass heading in degrees (0-360)
  /// - direction: Compass direction label
  /// - wifiRssi: WiFi signal strength in dBm
  /// - zone: Zone state (SAFE, WARNING, OUT_OF_RANGE)
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
          String zoneString = parts[3].trim().toUpperCase();

          // Update heading and direction
          headingAngle.value = heading;
          directionLabel.value = direction;

          // Update WiFi RSSI
          currentWifiRssi.value = wifiRssi;

          // Parse zone from ESP32 and update
          await _updateZoneFromBleData(zoneString);

          // Debug output
          debugPrint(
            '═══ BLE DATA RECEIVED ═══\n'
            'Heading: ${heading.toStringAsFixed(1)}°\n'
            'Direction: $direction\n'
            'WiFi RSSI: $wifiRssi dBm\n'
            'Zone: $zoneString\n'
            'Distance: ${distance.value.toStringAsFixed(1)}m\n'
            '═════════════════════════'
          );
        }
      } catch (e) {
        debugPrint("BLE Decode Error: $e");
      }
    });
  }

  /// Update zone and distance based on zone string from ESP32
  ///
  /// Triggers alerts on zone transitions:
  /// - SAFE/WARNING → OUT_OF_RANGE: Critical alert
  /// - OUT_OF_RANGE → SAFE/WARNING: Success alert
  Future<void> _updateZoneFromBleData(String zoneString) async {
    TrackingZone newZone = _parseZoneFromString(zoneString);

    // Only process if zone changed
    if (newZone != currentZone.value) {
      final previousZone = currentZone.value;
      currentZone.value = newZone;

      // Update distance based on zone
      distance.value = _getDistanceForZone(newZone);

      // Trigger alert on zone transitions
      await _handleZoneTransition(previousZone, newZone);

      _previousZone = newZone;
      lastAlertTime.value = DateTime.now();
    }
  }

  /// Parse zone enum from ESP32 zone string
  ///
  /// Converts: "SAFE" → TrackingZone.safe
  /// Converts: "WARNING" → TrackingZone.warning
  /// Converts: "OUT_OF_RANGE" → TrackingZone.outOfRange
  TrackingZone _parseZoneFromString(String zoneString) {
    switch (zoneString.toUpperCase()) {
      case 'SAFE':
        return TrackingZone.safe;
      case 'WARNING':
        return TrackingZone.warning;
      case 'OUT_OF_RANGE':
        return TrackingZone.outOfRange;
      default:
        return TrackingZone.disconnected;
    }
  }

  /// Get distance to display based on zone
  ///
  /// Distance mapping:
  /// - SAFE → 2m
  /// - WARNING → 5m
  /// - OUT_OF_RANGE → 8m
  /// - DISCONNECTED → 0m
  double _getDistanceForZone(TrackingZone zone) {
    switch (zone) {
      case TrackingZone.safe:
        return 2.0;
      case TrackingZone.warning:
        return 5.0;
      case TrackingZone.outOfRange:
        return 8.0;
      case TrackingZone.disconnected:
        return 0.0;
    }
  }

  /// Handle zone transitions and trigger alerts
  ///
  /// Alert logic:
  /// - SAFE/WARNING → OUT_OF_RANGE: Trigger critical alert
  /// - OUT_OF_RANGE → SAFE/WARNING: Trigger success alert
  /// - SAFE ↔ WARNING: No alert (same-level transition)
  Future<void> _handleZoneTransition(
    TrackingZone previousZone,
    TrackingZone newZone,
  ) async {
    // Alert only on entering/leaving OUT_OF_RANGE zone

    if (newZone == TrackingZone.outOfRange &&
        (previousZone == TrackingZone.safe ||
            previousZone == TrackingZone.warning)) {
      // Entering OUT_OF_RANGE - critical alert
      await _triggerBoundaryAlert(true);
      isBoundaryExceeded.value = true;
    } else if (newZone != TrackingZone.outOfRange &&
        previousZone == TrackingZone.outOfRange) {
      // Returning to safe/warning - success alert
      await _triggerBoundaryAlert(false);
      isBoundaryExceeded.value = false;
    }
  }

  // ═════════════════════════════════════════════════════════════
  // ALERT & NOTIFICATION METHODS
  // ═════════════════════════════════════════════════════════════

  /// Trigger boundary alert with vibration and sound
  ///
  /// Critical alert (entering OUT_OF_RANGE):
  /// - 4 strong vibration pulses
  /// - Alert sound
  ///
  /// Success alert (returning to SAFE/WARNING):
  /// - 2 gentle vibration pulses
  Future<void> _triggerBoundaryAlert(bool isCritical) async {
    try {
      // Vibrate to get attention
      if (isCritical) {
        // Critical alert - strong vibration pattern
        HapticFeedback.vibrate();
        await Future.delayed(const Duration(milliseconds: 150));
        HapticFeedback.vibrate();
        await Future.delayed(const Duration(milliseconds: 150));
        HapticFeedback.vibrate();
        await Future.delayed(const Duration(milliseconds: 150));
        HapticFeedback.vibrate();
        await _playBoundaryAlertSound();
      } else {
        // Safe return - gentle vibration pattern
        HapticFeedback.vibrate();
        await Future.delayed(const Duration(milliseconds: 200));
        HapticFeedback.vibrate();
      }
    } catch (e) {
      debugPrint("Alert error: $e");
    }
  }

  /// Play boundary alert sound
  Future<void> _playBoundaryAlertSound() async {
    try {
      await _alertPlayer.stop();
      await _alertPlayer.play(AssetSource(boundaryAlertAsset));
    } catch (_) {
      // The asset may not exist yet while the alert file is being prepared.
    }
  }

  // ═════════════════════════════════════════════════════════════
  // USER PROFILE MANAGEMENT
  // ═════════════════════════════════════════════════════════════

  /// Load child profile from Firebase or auth
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

  /// Logout and reset to login screen
  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      childName.value = "Child";
      isConnected.value = false;
      isScanning.value = false;
      directionLabel.value = "Disconnected";
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
}
