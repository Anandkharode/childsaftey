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

class MainController extends GetxController {
  static const String boundaryAlertAsset = 'audio/boundary_alert.mp3';

  // Reactive properties that the view will listen to
  final distance = 2.8.obs;
  final headingAngle = 0.0.obs; // In degrees
  final directionLabel = "Disconnected".obs;
  final childName = "Child".obs;

  final boundaryDistance = 3.0.obs; // User-defined boundary limit in meters
  final isConnected = false.obs;
  final isScanning = false.obs;
  final isBoundaryExceeded = false.obs; // Track boundary alert state
  final currentRssi = RxnInt(); // Live RSSI value from the connected ESP32
  final lastAlertTime = DateTime.now().obs; // Prevent alert spam

  // ─ NEW: Zone-based tracking properties ─
  final currentZone = TrackingZone.disconnected.obs;
  final smoothedRssi = 0.0.obs;
  final smoothedDistance = 0.0.obs;

  // ─ NEW: Configurable zone boundaries (RSSI thresholds) ─
  final safeBoundary = (-75).obs;      // Safe zone threshold in dBm (closer = more negative)
  final warningBoundary = (-82).obs;   // Warning zone threshold in dBm
  final outOfRangeBoundary = (-90).obs; // Out of range threshold in dBm

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  BluetoothDevice? _espDevice;
  Timer? _rssiTimer;
  bool _isReadingRssi = false;
  final AudioPlayer _alertPlayer = AudioPlayer();

  // ─ NEW: Smoothing instances ─
  late RssiSmoother _rssiSmoother;
  late DistanceSmoother _distanceSmoother;
  TrackingZone _previousZone = TrackingZone.disconnected;

  static const String serviceUuid = "12345678-1234-1234-1234-123456789abc";
  static const String characteristicUuid =
      "87654321-4321-4321-4321-cba987654321";

  @override
  void onInit() {
    super.onInit();
    // Initialize smoothers
    _rssiSmoother = RssiSmoother();
    _distanceSmoother = DistanceSmoother();
    loadChildProfile();
    startBleScan();
  }

  @override
  void onClose() {
    _stopRssiUpdates();
    _scanSubscription?.cancel();
    _espDevice?.disconnect();
    _alertPlayer.dispose();
    super.onClose();
  }

  void toggleBluetooth() {
    if (isConnected.value || isScanning.value) {
      FlutterBluePlus.stopScan();
      _stopRssiUpdates();
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
      _stopRssiUpdates();
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
        _stopRssiUpdates();
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

      _startRssiUpdates();
    } catch (e) {
      _stopRssiUpdates();
      directionLabel.value = "Error connecting";
    }
  }

  void _startRssiUpdates() {
    _rssiTimer?.cancel();
    _readAndUpdateRssi();
    _rssiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _readAndUpdateRssi();
    });
  }

  void _stopRssiUpdates() {
    _rssiTimer?.cancel();
    _rssiTimer = null;
    _isReadingRssi = false;
    currentRssi.value = null;
    // Reset zone on disconnect
    currentZone.value = TrackingZone.disconnected;
    _previousZone = TrackingZone.disconnected;
    _rssiSmoother.reset();
    _distanceSmoother.reset();
  }

  Future<void> _readAndUpdateRssi() async {
    if (_isReadingRssi) return;

    final device = _espDevice;
    if (device == null || !isConnected.value) return;

    _isReadingRssi = true;
    try {
      int rawRssi = await device.readRssi();
      if (!isConnected.value || device != _espDevice) return;

      // ─ NEW: Apply EWMA smoothing ─
      double smoothed = _rssiSmoother.smooth(rawRssi);
      smoothedRssi.value = double.parse(smoothed.toStringAsFixed(1));

      // Update current RSSI for display
      currentRssi.value = rawRssi;

      // ─ NEW: Use zone-based tracking instead of exact distance ─
      await _updateZoneFromSmoothedRssi(smoothed.toInt());

      // Debug output
      _printDebugInfo(rawRssi, smoothed);

      // Update zone display based on current distance
      _updateZoneFromDistance();
    } catch (e) {
      debugPrint("RSSI read error: $e");
    } finally {
      _isReadingRssi = false;
    }
  }

  /// Print debug information to console
  void _printDebugInfo(int rawRssi, double smoothedRssi) {
    debugPrint(
      '═══ BLE DEBUG INFO ═══\n'
      'Raw RSSI: $rawRssi dBm\n'
      'Smoothed RSSI: ${smoothedRssi.toStringAsFixed(1)} dBm\n'
      'Current Zone: ${currentZone.value.displayName}\n'
      'Estimated Distance: ${distance.value.toStringAsFixed(1)}m\n'
      '══════════════════════'
    );
  }

  /// Update zone and distance based on smoothed RSSI
  Future<void> _updateZoneFromSmoothedRssi(int smoothedRssi) async {
    // Determine zone from smoothed RSSI
    TrackingZone newZone = getZoneFromRssi(smoothedRssi);
    currentZone.value = newZone;

    // Get zone-based estimated distance
    double estimatedDist = newZone.estimatedDistance;

    // Apply smooth interpolation to distance for radar
    smoothedDistance.value =
        _distanceSmoother.smoothDistance(estimatedDist);
    distance.value = double.parse(smoothedDistance.value.toStringAsFixed(1));

    // Check for zone transition to trigger alerts
    if (newZone != _previousZone) {
      _previousZone = newZone;

      // Alert logic: Only trigger when:
      // 1. Entering OUT_OF_RANGE from SAFE/WARNING
      // 2. Returning to SAFE/WARNING from OUT_OF_RANGE
      if (newZone == TrackingZone.outOfRange &&
          (_previousZone == TrackingZone.safe ||
              _previousZone == TrackingZone.warning)) {
        // Entering OUT_OF_RANGE - critical alert
        await _triggerBoundaryAlert(true);
        isBoundaryExceeded.value = true;
      } else if (newZone != TrackingZone.outOfRange &&
          _previousZone == TrackingZone.outOfRange) {
        // Returning to safe/warning - success alert
        await _triggerBoundaryAlert(false);
        isBoundaryExceeded.value = false;
      }

      lastAlertTime.value = DateTime.now();
    }
  }

  /// Function to process incoming BLE data from the ESP32.
  void listenToBleData(BluetoothCharacteristic characteristic) {
    characteristic.lastValueStream.listen((value) async {
      if (value.isEmpty) return;

      try {
        String data = utf8.decode(value);
        List<String> parts = data.split(',');

        if (parts.length >= 2) {
          double heading = double.parse(parts[0]);
          String direction = parts[1].trim();

          // Update our reactive variables
          headingAngle.value = heading;
          directionLabel.value = direction;
        }
      } catch (e) {
        debugPrint("BLE Decode Error: $e");
      }
    });
  }

  /// Trigger boundary exceeded or safe return alert
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

  Future<void> _playBoundaryAlertSound() async {
    try {
      await _alertPlayer.stop();
      await _alertPlayer.play(AssetSource(boundaryAlertAsset));
    } catch (_) {
      // The asset may not exist yet while the alert file is being prepared.
    }
  }

  /// Update zone based on current distance and boundaries
  void _updateZoneFromDistance() {
    final currDistance = distance.value;
    final boundary = boundaryDistance.value;
    TrackingZone newZone;
    
    if (currDistance <= 2.0) {
      // Safe zone
      newZone = TrackingZone.safe;
    } else if (currDistance <= boundary) {
      // Warning zone
      newZone = TrackingZone.warning;
    } else {
      // Out of range
      newZone = TrackingZone.outOfRange;
    }
    
    // Check if zone changed and trigger alert if needed
    if (newZone != currentZone.value) {
      final previousZone = currentZone.value;
      currentZone.value = newZone;
      
      // Trigger alert if entering out of range
      if (newZone == TrackingZone.outOfRange && 
          previousZone != TrackingZone.disconnected) {
        _triggerBoundaryAlert(true);
        isBoundaryExceeded.value = true;
      } 
      // Trigger alert if returning to safe/warning
      else if (newZone != TrackingZone.outOfRange && isBoundaryExceeded.value) {
        _triggerBoundaryAlert(false);
        isBoundaryExceeded.value = false;
      }
    }
  }

  /// Update zone boundary and trigger recalculation
  void updateSafeBoundary(int newValue) {
    safeBoundary.value = newValue;
    _updateZoneFromDistance();
  }

  /// Update warning boundary and trigger recalculation
  void updateWarningBoundary(int newValue) {
    warningBoundary.value = newValue;
    _updateZoneFromDistance();
  }

  /// Update out of range boundary and trigger recalculation
  void updateOutOfRangeBoundary(int newValue) {
    outOfRangeBoundary.value = newValue;
    _updateZoneFromDistance();
  }

  /// Get zone name based on configured boundaries
  String getZoneName() {
    final dist = distance.value;
    final boundDist = boundaryDistance.value;
    
    if (dist <= 2.0) {
      return 'Safe Zone';
    } else if (dist <= boundDist) {
      return 'Warning Zone';
    } else {
      return 'Out of Range';
    }
  }

  /// Update boundary distance from slider and recalculate zone
  void updateBoundaryDistance(double newBoundary) {
    boundaryDistance.value = newBoundary;
    _updateZoneFromDistance();
  }
}
