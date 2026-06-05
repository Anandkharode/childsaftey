# UI Code Snippets - Quick Reference

## 1. Display Zone with Color

```dart
Obx(() {
  final zone = controller.currentZone.value;
  return Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Color(zone.displayColor),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      'Zone: ${zone.displayName}',
      style: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
})
```

## 2. WiFi RSSI Display

```dart
Obx(() => Text(
  'WiFi RSSI: ${controller.currentWifiRssi.value ?? "N/A"} dBm',
  style: TextStyle(fontSize: 14, fontFamily: 'monospace'),
))
```

## 3. Distance Display

```dart
Obx(() => Text(
  'Distance: ${controller.distance.value.toStringAsFixed(1)} m',
  style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.blue,
  ),
))
```

## 4. Heading and Direction

```dart
Row(
  children: [
    Obx(() => Text(
      'Heading: ${controller.headingAngle.value.toStringAsFixed(1)}°',
      style: TextStyle(fontSize: 14),
    )),
    SizedBox(width: 16),
    Obx(() => Text(
      'Direction: ${controller.directionLabel.value}',
      style: TextStyle(fontSize: 14),
    )),
  ],
)
```

## 5. Connection Status Indicator

```dart
Obx(() => Container(
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  decoration: BoxDecoration(
    color: controller.isConnected.value ? Colors.green : Colors.red,
    borderRadius: BorderRadius.circular(20),
  ),
  child: Text(
    controller.isConnected.value ? '✓ Connected' : '✗ Disconnected',
    style: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
  ),
))
```

## 6. Full Dashboard Example

```dart
class DashboardWidget extends StatelessWidget {
  final MainController controller = Get.find<MainController>();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with connection status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(() => Text(
                '${controller.childName.value}',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              )),
              Obx(() => Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: controller.isConnected.value ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  controller.isConnected.value ? '✓ Connected' : '✗ Disconnected',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              )),
            ],
          ),
          SizedBox(height: 24),

          // Zone display card
          Obx(() {
            final zone = controller.currentZone.value;
            return Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(zone.displayColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Zone: ${zone.displayName}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Distance: ${controller.distance.value.toStringAsFixed(1)} m',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            );
          }),
          SizedBox(height: 24),

          // Compass section
          Text(
            'Compass',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Obx(() => Text(
                    'Heading: ${controller.headingAngle.value.toStringAsFixed(1)}°',
                    style: TextStyle(fontSize: 16),
                  )),
                  SizedBox(height: 8),
                  Obx(() => Text(
                    'Direction: ${controller.directionLabel.value}',
                    style: TextStyle(fontSize: 16),
                  )),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),

          // Signal strength
          Text(
            'Signal Strength',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Obx(() => Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'WiFi RSSI: ${controller.currentWifiRssi.value ?? "N/A"} dBm',
                style: TextStyle(fontSize: 16, fontFamily: 'monospace'),
              ),
            ),
          )),
        ],
      ),
    );
  }
}
```

## 7. Radar Widget Update

```dart
Obx(() => Container(
  width: 300,
  height: 300,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    border: Border.all(color: Colors.blue, width: 2),
  ),
  child: Stack(
    alignment: Alignment.center,
    children: [
      // Outer circle (8m - OUT_OF_RANGE)
      Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Center(
          child: Text('8m', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ),
      ),
      
      // Middle circle (5m - WARNING)
      Container(
        width: 187.5, // 62.5% of 300
        height: 187.5,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Center(
          child: Text('5m', style: TextStyle(fontSize: 12, color: Colors.orange)),
        ),
      ),
      
      // Inner circle (2m - SAFE)
      Container(
        width: 75, // 25% of 300
        height: 75,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Center(
          child: Text('2m', style: TextStyle(fontSize: 12, color: Colors.green)),
        ),
      ),
      
      // Child dot (positioned by heading)
      Transform.rotate(
        angle: (controller.headingAngle.value * 3.14159 / 180),
        child: Positioned(
          bottom: 50,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(controller.currentZone.value.displayColor),
            ),
          ),
        ),
      ),
      
      // Center point
      Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blue,
        ),
      ),
    ],
  ),
))
```

## 8. Zone Status Card

```dart
Obx(() {
  final zone = controller.currentZone.value;
  final zoneColor = Color(zone.displayColor);
  final distance = controller.distance.value;
  
  return Card(
    elevation: 4,
    child: Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: zoneColor, width: 3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zone name
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: zoneColor,
                ),
              ),
              SizedBox(width: 8),
              Text(
                zone.displayName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: zoneColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          
          // Distance
          Text(
            'Distance: ${distance.toStringAsFixed(1)}m',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 8),
          
          // WiFi RSSI
          Text(
            'WiFi: ${controller.currentWifiRssi.value ?? "N/A"} dBm',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          SizedBox(height: 8),
          
          // Status message
          Text(
            _getStatusMessage(zone),
            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  );
})

// Helper function
String _getStatusMessage(TrackingZone zone) {
  switch (zone) {
    case TrackingZone.safe:
      return 'Child is within safe zone';
    case TrackingZone.warning:
      return 'Child is approaching boundary';
    case TrackingZone.outOfRange:
      return 'Child has exceeded boundary!';
    case TrackingZone.disconnected:
      return 'No connection with device';
  }
}
```

## 9. Alert Status Display

```dart
Obx(() => Container(
  padding: EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: controller.isBoundaryExceeded.value 
      ? Colors.red.withOpacity(0.1)
      : Colors.green.withOpacity(0.1),
    border: Border.all(
      color: controller.isBoundaryExceeded.value 
        ? Colors.red
        : Colors.green,
    ),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text(
    controller.isBoundaryExceeded.value
      ? '⚠️ BOUNDARY EXCEEDED'
      : '✓ Within Boundary',
    style: TextStyle(
      color: controller.isBoundaryExceeded.value
        ? Colors.red
        : Colors.green,
      fontWeight: FontWeight.bold,
    ),
  ),
))
```

## 10. Simple Info Row

```dart
Obx(() => Column(
  children: [
    _infoRow('Child', controller.childName.value),
    _infoRow('Connection', controller.isConnected.value ? 'Connected' : 'Disconnected'),
    _infoRow('Zone', controller.currentZone.value.displayName),
    _infoRow('Distance', '${controller.distance.value.toStringAsFixed(1)}m'),
    _infoRow('Heading', '${controller.headingAngle.value.toStringAsFixed(1)}°'),
    _infoRow('Direction', controller.directionLabel.value),
    _infoRow('WiFi RSSI', '${controller.currentWifiRssi.value ?? "N/A"} dBm'),
  ],
))

Widget _infoRow(String label, String value) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        Text(value, style: TextStyle(fontFamily: 'monospace')),
      ],
    ),
  );
}
```

## 11. Remove Old Code Examples

### ❌ OLD - Remove this:
```dart
// OLD RSSI-based display
Obx(() => Text('RSSI: ${controller.currentRssi.value} dBm'))

// OLD boundary slider
Slider(
  value: controller.boundaryDistance.value.toDouble(),
  onChanged: controller.updateBoundaryDistance,
  divisions: 20,
  label: '${controller.boundaryDistance.value.toStringAsFixed(1)}m',
)

// OLD zone calculation
Text(controller.getZoneName())

// OLD RSSI smoothing display
Text('Smoothed RSSI: ${controller.smoothedRssi.value}')
```

### ✅ NEW - Replace with this:
```dart
// NEW WiFi display
Obx(() => Text('WiFi RSSI: ${controller.currentWifiRssi.value ?? "N/A"} dBm'))

// No slider needed - zones come from ESP32
// Zone display
Obx(() => Text('Zone: ${controller.currentZone.value.displayName}'))

// No smoothing needed - distance is fixed per zone
Text('Distance: ${controller.distance.value.toStringAsFixed(1)}m')
```

## 12. Testing Widget

```dart
/// Debug widget to display all reactive values
class DebugPanel extends StatelessWidget {
  final MainController controller = Get.find<MainController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
      padding: EdgeInsets.all(12),
      color: Colors.grey[200],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DEBUG INFO:', style: TextStyle(fontWeight: FontWeight.bold)),
          _debugLine('Connected', controller.isConnected.value.toString()),
          _debugLine('Scanning', controller.isScanning.value.toString()),
          _debugLine('Zone', controller.currentZone.value.displayName),
          _debugLine('Distance', '${controller.distance.value}m'),
          _debugLine('Heading', '${controller.headingAngle.value}°'),
          _debugLine('Direction', controller.directionLabel.value),
          _debugLine('WiFi RSSI', '${controller.currentWifiRssi.value} dBm'),
          _debugLine('Child Name', controller.childName.value),
          _debugLine('Boundary Exceeded', controller.isBoundaryExceeded.value.toString()),
          _debugLine('Last Alert', controller.lastAlertTime.value.toString()),
        ],
      ),
    ));
  }

  Widget _debugLine(String key, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(fontSize: 11, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
```

## 13. Error Handling Display

```dart
Obx(() {
  if (!controller.isConnected.value) {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.red.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connection Error',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Status: ${controller.directionLabel.value}',
            style: TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }
  return SizedBox.shrink();
})
```

These snippets provide everything needed to build the UI around the new zone-based tracking system!
