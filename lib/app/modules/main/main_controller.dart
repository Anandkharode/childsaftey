import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class MainController extends GetxController {
  // Reactive properties that the view will listen to
  final distance = 2.8.obs;
  final headingAngle = 0.0.obs; // In degrees
  final directionLabel = "Disconnected".obs;
  final childName = "Child".obs;

  final boundaryDistance = 3.0.obs; // User-defined boundary limit in meters
  final isConnected = false.obs;
  final isScanning = false.obs;
  final isBoundaryExceeded = false.obs; // Track boundary alert state
  final lastAlertTime = DateTime.now().obs; // Prevent alert spam

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  BluetoothDevice? _espDevice;
  bool _previousBoundaryState = false; // Track state change

  static const String SERVICE_UUID = "12345678-1234-1234-1234-123456789abc";
  static const String CHARACTERISTIC_UUID = "87654321-4321-4321-4321-cba987654321";

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
    super.onClose();
  }

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
      if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
        directionLabel.value = "Bluetooth is off";
        isScanning.value = false;
        return;
      }
    }
    
    directionLabel.value = "Scanning ESP32...";

    // 3. Scan for "ESP32_Compass"
    _scanSubscription = FlutterBluePlus.onScanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.platformName == "ESP32_Compass" || r.advertisementData.advName == "ESP32_Compass") {
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
        if (service.uuid.toString() == SERVICE_UUID) {
          for (BluetoothCharacteristic c in service.characteristics) {
            if (c.uuid.toString() == CHARACTERISTIC_UUID) {
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

  DateTime _lastRssiCheck = DateTime.now();

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
          
          // Securely calculate physical meters via RSSI without deadlocking GATT
          // Limited to checking once every 1 second!
          if (DateTime.now().difference(_lastRssiCheck).inMilliseconds >= 1000) {
            _lastRssiCheck = DateTime.now();
            try {
              if (_espDevice != null) {
                int rssi = await _espDevice!.readRssi();
                // Calculate decibel loss physics assuming -59dBm at 1m with a path-loss index of 2
                double calculatedDist = math.pow(10, (-59 - rssi) / 20.0).toDouble();
                distance.value = double.parse(calculatedDist.toStringAsFixed(1));

                // Check boundary and trigger alert only on state change
                bool currentBoundaryExceeded = distance.value > boundaryDistance.value;
                
                if (currentBoundaryExceeded != _previousBoundaryState) {
                  // Boundary state changed - trigger alert
                  _previousBoundaryState = currentBoundaryExceeded;
                  
                  if (currentBoundaryExceeded) {
                    // Child exceeded boundary - critical alert
                    await _triggerBoundaryAlert(true);
                  } else {
                    // Child returned to safe range - success alert
                    await _triggerBoundaryAlert(false);
                  }
                  
                  isBoundaryExceeded.value = currentBoundaryExceeded;
                  lastAlertTime.value = DateTime.now();
                }
                print("RSSI:$rssi");
              }
            } catch (_) {}
          }
        }
      } catch (e) {
        print("BLE Decode Error: $e");
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
      } else {
        // Safe return - gentle vibration pattern
        HapticFeedback.vibrate();
        await Future.delayed(const Duration(milliseconds: 200));
        HapticFeedback.vibrate();
      }
    } catch (e) {
      print("Alert error: $e");
    }
  }
}
