# QUICK REFERENCE CARD

## BLE Data Format
```
heading,direction,wifiRssi,zone
45.2,North-East,-62,SAFE
```

## Reactive Variables
| Variable | Type | Example | Use Case |
|----------|------|---------|----------|
| `distance` | double | 2.0, 5.0, 8.0 | Radar display |
| `currentZone` | TrackingZone | SAFE, WARNING, OOR | Zone display |
| `currentWifiRssi` | int | -62 | WiFi signal |
| `headingAngle` | double | 45.2 | Compass rotation |
| `directionLabel` | string | "North-East" | Direction arrow |
| `isConnected` | bool | true/false | Status indicator |
| `isBoundaryExceeded` | bool | true/false | Alert status |
| `childName` | string | "Tommy" | Header display |

## Distance Mapping
```
Zone              → Distance
SAFE              → 2m
WARNING           → 5m
OUT_OF_RANGE      → 8m
DISCONNECTED      → 0m
```

## Alert Triggers
```
SAFE/WARNING → OUT_OF_RANGE  = CRITICAL (4 vibrations + sound)
OUT_OF_RANGE → SAFE/WARNING  = SUCCESS (2 gentle vibrations)
SAFE ↔ WARNING               = NO ALERT
```

## UI Display Code

### Zone with Color
```dart
Obx(() => Container(
  color: Color(controller.currentZone.value.displayColor),
  child: Text(controller.currentZone.value.displayName)
))
```

### WiFi RSSI
```dart
Obx(() => Text('WiFi: ${controller.currentWifiRssi.value} dBm'))
```

### Distance
```dart
Obx(() => Text('${controller.distance.value}m'))
```

### Heading & Direction
```dart
Obx(() => Text('${controller.headingAngle.value}° ${controller.directionLabel.value}'))
```

## Console Debug Output
```
═══ BLE DATA RECEIVED ═══
Heading: 45.2°
Direction: North-East
WiFi RSSI: -62 dBm
Zone: SAFE
Distance: 2.0m
═════════════════════════
```

## Zone Colors
- SAFE: 🟢 Green (0xFF7BE4A5)
- WARNING: 🟡 Yellow (0xFFFFC857)
- OUT_OF_RANGE: 🔴 Red (0xFFE47B7B)
- DISCONNECTED: ⚪ Gray (0xFFB0B0B0)

## Removed / Changed
| Old | New | Status |
|-----|-----|--------|
| `currentRssi` | `currentWifiRssi` | Renamed |
| `_startRssiUpdates()` | N/A | Removed |
| `updateBoundaryDistance()` | N/A | Removed |
| `getZoneName()` | `.displayName` | Replaced |
| 2 BLE fields | 4 BLE fields | Updated |

## Common Issues Quick Fix

**WiFi shows null?**
→ Check ESP32 sends valid integer in field 3

**Zone not updating?**
→ Check zone string matches "SAFE", "WARNING", "OUT_OF_RANGE" exactly

**Alerts not working?**
→ Test transition between SAFE/WARNING ↔ OUT_OF_RANGE

**App crashes on data?**
→ Check console for "BLE Decode Error", verify all 4 fields present

## Files to Review
1. `FINAL_SUMMARY.md` - Start here
2. `IMPLEMENTATION_GUIDE.md` - How to integrate
3. `UI_CODE_SNIPPETS.md` - Copy-paste ready code
4. `ARCHITECTURE_DIAGRAM.md` - How it works
5. `TESTING_CHECKLIST.md` - Verification steps

## ESP32 Firmware Checklist
- [ ] Sends 4 comma-separated values
- [ ] Heading is 0-360 degrees (float)
- [ ] Direction is valid string
- [ ] WiFi RSSI is negative integer
- [ ] Zone is "SAFE", "WARNING", or "OUT_OF_RANGE"
- [ ] Sends at least once per second
- [ ] BLE characteristic UUID matches app

## Flutter Integration Checklist
- [ ] Remove RSSI sliders from UI
- [ ] Replace `currentRssi` with `currentWifiRssi`
- [ ] Replace `getZoneName()` with `.displayName`
- [ ] Update distance display (fixed 2/5/8m)
- [ ] Test with actual ESP32 data
- [ ] Verify all alerts work
- [ ] Check radar updates correctly
- [ ] Run full testing checklist

## Performance Notes
- ✓ No RSSI polling (event-driven)
- ✓ Faster zone updates
- ✓ Lower battery drain
- ✓ More responsive alerts
- ✓ Cleaner code

## Commands
```bash
# Check code
flutter analyze

# Run tests
flutter test

# Build APK
flutter build apk

# Build iOS
flutter build ios
```

---
**Print this card and keep it handy during development!**
