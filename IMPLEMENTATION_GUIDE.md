# Implementation Guide - Zone-Based Tracking

## Quick Start

### 1. **ESP32 Firmware Changes**
Your ESP32 must send data in this format:
```
heading,direction,wifiRssi,zone
```

**Example:**
```
45.2,North-East,-62,SAFE
```

**Field Breakdown:**
- `heading`: Compass heading (0-360 degrees) - float
- `direction`: Compass direction label - string
- `wifiRssi`: WiFi signal strength in dBm - integer (negative value)
- `zone`: Zone state - string ("SAFE", "WARNING", or "OUT_OF_RANGE")

### 2. **In Your View (main_view.dart)**

#### Display WiFi RSSI
```dart
Obx(() => Text(
  'WiFi RSSI: ${controller.currentWifiRssi.value ?? "N/A"} dBm',
  style: TextStyle(fontSize: 14),
))
```

#### Display Current Zone
```dart
Obx(() => Text(
  'Zone: ${controller.currentZone.value.displayName}',
  style: TextStyle(
    color: Color(controller.currentZone.value.displayColor),
    fontSize: 16,
    fontWeight: FontWeight.bold,
  ),
))
```

#### Display Distance
```dart
Obx(() => Text(
  'Distance: ${controller.distance.value.toStringAsFixed(1)}m',
  style: TextStyle(fontSize: 14),
))
```

#### Radar Display
The radar should automatically update based on `controller.distance.value`:
```dart
// Distance values:
// SAFE → 2m (inner circle)
// WARNING → 5m (middle circle)
// OUT_OF_RANGE → 8m (outer circle)
```

#### Direction and Heading
```dart
Obx(() => Text(
  'Direction: ${controller.directionLabel.value}',
  style: TextStyle(fontSize: 14),
))

Obx(() => Text(
  'Heading: ${controller.headingAngle.value.toStringAsFixed(1)}°',
  style: TextStyle(fontSize: 14),
))
```

### 3. **Data Flow Example**

**ESP32 sends:** `45.2,North-East,-62,SAFE`

**App processes:**
1. Parses heading: `45.2`
2. Parses direction: `North-East`
3. Parses wifiRssi: `-62`
4. Parses zone: `SAFE`

**Result:**
- `headingAngle = 45.2`
- `directionLabel = "North-East"`
- `currentWifiRssi = -62`
- `currentZone = TrackingZone.safe`
- `distance = 2.0`

**Display:**
- Radar shows inner circle (2m)
- Zone shows: "SAFE" (green)
- WiFi RSSI shows: "-62 dBm"
- Direction shows: "North-East"

### 4. **Zone Transition & Alerts**

**Alert Triggers:**
```
SAFE → OUT_OF_RANGE: Critical alert (4 vibrations + sound)
WARNING → OUT_OF_RANGE: Critical alert (4 vibrations + sound)
OUT_OF_RANGE → SAFE: Success alert (2 gentle vibrations)
OUT_OF_RANGE → WARNING: Success alert (2 gentle vibrations)
```

**No Alerts:**
```
SAFE ↔ WARNING: No alert (same-level transitions are continuous)
```

### 5. **Reactive Variables You Can Use**

```dart
// Zone and distance
controller.currentZone       // Current zone (SAFE, WARNING, OUT_OF_RANGE, DISCONNECTED)
controller.distance          // Distance for display (2m, 5m, 8m, or 0m)

// WiFi signal
controller.currentWifiRssi   // WiFi RSSI value in dBm

// Compass
controller.headingAngle      // Compass heading (0-360°)
controller.directionLabel    // Compass direction label

// Connection
controller.isConnected       // Boolean - BLE connected
controller.isScanning        // Boolean - Currently scanning
controller.directionLabel    // Shows "Disconnected" when not connected

// Alerts
controller.isBoundaryExceeded    // Boolean - Currently in OUT_OF_RANGE
controller.lastAlertTime         // DateTime of last alert

// Child info
controller.childName         // Child's name from Firebase
```

### 6. **Removed / Changed**

❌ **No longer available:**
- `controller.currentRssi` → Use `controller.currentWifiRssi` instead
- `controller.boundaryDistance` → Removed (distance is now fixed per zone)
- `controller.safeBoundary` → Removed
- `controller.warningBoundary` → Removed
- `controller.outOfRangeBoundary` → Removed
- `controller.smoothedRssi` → Removed
- `controller.smoothedDistance` → Removed
- `controller.updateBoundaryDistance()` → Removed
- `controller.updateSafeBoundary()` → Removed
- `controller.updateWarningBoundary()` → Removed
- `controller.updateOutOfRangeBoundary()` → Removed
- `controller.getZoneName()` → Use `controller.currentZone.value.displayName` instead

### 7. **Common UI Updates**

**Remove boundary sliders:**
If you had sliders for RSSI thresholds or boundary distances, remove them entirely since zones are now sent from ESP32.

**Update RSSI display:**
```dart
// OLD
Text('RSSI: ${controller.currentRssi.value} dBm')

// NEW
Text('WiFi RSSI: ${controller.currentWifiRssi.value} dBm')
```

**Update zone display:**
```dart
// OLD
Text(controller.getZoneName())

// NEW
Text(controller.currentZone.value.displayName)
```

**Update distance display:**
Distance is now automatically set based on zone, no manual calculation needed:
```dart
// Just display it
Text('Distance: ${controller.distance.value.toStringAsFixed(1)}m')
```

### 8. **Testing Steps**

1. **Build and run the app**
   ```bash
   flutter run
   ```

2. **Simulate ESP32 data** (if needed for testing)
   - Use a BLE terminal app to send: `0.0,North,-75,SAFE`
   - Verify app displays correct values

3. **Check console output**
   The app prints debug info each time data is received:
   ```
   ═══ BLE DATA RECEIVED ═══
   Heading: 45.2°
   Direction: North-East
   WiFi RSSI: -62 dBm
   Zone: SAFE
   Distance: 2.0m
   ═════════════════════════
   ```

4. **Test zone transitions**
   - Send SAFE → OUT_OF_RANGE: Should trigger critical alert
   - Send OUT_OF_RANGE → SAFE: Should trigger success alert
   - Send SAFE ↔ WARNING: Should NOT trigger alert

5. **Test displays**
   - WiFi RSSI shows correct dBm value
   - Zone shows correct color and label
   - Distance matches zone (2m, 5m, or 8m)
   - Heading and direction match sent data

### 9. **Troubleshooting**

**App not receiving data:**
- Check ESP32 is sending all 4 comma-separated values
- Verify BLE connection is established ("Connected" status)
- Check console for "BLE Decode Error" messages

**Zone not updating:**
- Ensure zone string is exactly "SAFE", "WARNING", or "OUT_OF_RANGE"
- Check for extra spaces: use `.trim()` in parsing

**Alerts not triggering:**
- Verify zone transitions match the alert logic
- Check that alerts only trigger on SAFE/WARNING ↔ OUT_OF_RANGE changes
- Test with actual zone transitions

**WiFi RSSI shows as null:**
- Check ESP32 is sending valid integer for wifiRssi field
- Verify format: `heading,direction,wifiRssi,zone` (4 fields required)

## Summary of Key Changes

| Aspect | Before | After |
|--------|--------|-------|
| Distance Calculation | RSSI-based EWMA smoothing | Direct zone from ESP32 |
| Zone Boundary Config | User-configurable thresholds | Fixed per zone |
| BLE Data | 2 fields (heading, direction) | 4 fields (heading, direction, wifiRssi, zone) |
| RSSI Updates | Polled every 1 second | Received with notification |
| Display Distance | Calculated from RSSI | 2m/5m/8m based on zone |
| Alert Triggers | Based on RSSI thresholds | Based on zone transitions |
| WiFi Signal Display | Unavailable | Direct WiFi RSSI |

## File References

- **Updated Controller:** `lib/app/modules/main/main_controller.dart`
- **Reference Copy:** `MAIN_CONTROLLER_UPDATED.dart` (in project root)
- **Full Documentation:** `REFACTOR_SUMMARY.md` (in project root)
