# Architecture & Data Flow Diagram

## System Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         CHILD SAFETY TRACKING SYSTEM                         │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────┐              ┌─────────────────────────────────┐
│    ESP32 DEVICE          │              │   FLUTTER APP (MainController)  │
│                          │              │                                 │
│  • Compass (heading)     │              │  ┌─────────────────────────┐   │
│  • Direction detector    │ ─────BLE────→│  │ listenToBleData()       │   │
│  • WiFi signal meter     │ (data every  │  │                         │   │
│  • Zone calculator       │  notification)│ Parse 4 fields from ESP32 │   │
│                          │              │  └─────────────────────────┘   │
│ BLE Characteristic:      │              │           │                     │
│ Data: heading,direction, │              │           ↓                     │
│ wifiRssi,zone            │              │  ┌─────────────────────────┐   │
└──────────────────────────┘              │  │ Update Reactive Vars:   │   │
                                          │  │ • headingAngle          │   │
                                          │  │ • directionLabel        │   │
                                          │  │ • currentWifiRssi       │   │
                                          │  │ • currentZone           │   │
                                          │  │ • distance              │   │
                                          │  └─────────────────────────┘   │
                                          │           │                     │
                                          │           ↓                     │
                                          │  ┌─────────────────────────┐   │
                                          │  │ Zone Transition Logic   │   │
                                          │  │ • Check if zone changed │   │
                                          │  │ • Trigger alerts if:    │   │
                                          │  │   SAFE/WARNING → OOR    │   │
                                          │  │   OOR → SAFE/WARNING    │   │
                                          │  └─────────────────────────┘   │
                                          │           │                     │
                                          │           ↓                     │
                                          │  ┌─────────────────────────┐   │
                                          │  │ Alert Triggers:         │   │
                                          │  │ • Vibration patterns    │   │
                                          │  │ • Audio alerts          │   │
                                          │  └─────────────────────────┘   │
                                          └─────────────────────────────────┘
                                                     │
                                                     ↓
                                    ┌──────────────────────────────┐
                                    │     UI (main_view.dart)      │
                                    │                              │
                                    │  Obx() watches and updates: │
                                    │  • Radar display (distance)  │
                                    │  • Zone label + color        │
                                    │  • WiFi RSSI value           │
                                    │  • Heading/Direction arrows  │
                                    │  • Connection status         │
                                    │  • Child's location visual   │
                                    └──────────────────────────────┘
```

## Detailed Data Flow Sequence

```
STEP 1: ESP32 Sends Data
┌──────────────────────────────────────────┐
│  ESP32 BLE Characteristic Notification   │
│                                          │
│  Raw bytes: [52, 53, 46, 50, ...]       │ (UTF-8 encoded)
│  Decoded: "45.2,North-East,-62,SAFE"    │
└──────────────────────────────────────────┘
                    │
                    ↓
STEP 2: listenToBleData() receives notification
┌──────────────────────────────────────────┐
│  characteristic.lastValueStream.listen() │
│                                          │
│  1. Decode UTF-8: data = "45.2,..."     │
│  2. Split by ',': [45.2, North-East,   │
│                    -62, SAFE]           │
└──────────────────────────────────────────┘
                    │
                    ↓
STEP 3: Parse individual fields
┌──────────────────────────────────────────┐
│  double heading = 45.2                   │
│  String direction = "North-East"         │
│  int wifiRssi = -62                      │
│  String zoneString = "SAFE"              │
└──────────────────────────────────────────┘
                    │
                    ↓
STEP 4: Update reactive variables
┌──────────────────────────────────────────┐
│  headingAngle.value = 45.2               │
│  directionLabel.value = "North-East"     │
│  currentWifiRssi.value = -62             │
│  [Trigger zone update]                   │
└──────────────────────────────────────────┘
                    │
                    ↓
STEP 5: Parse and update zone
┌──────────────────────────────────────────┐
│  newZone = _parseZoneFromString("SAFE")  │
│  → TrackingZone.safe                     │
│                                          │
│  if (newZone != currentZone.value) {     │
│    Update zone and distance              │
│    Handle transitions                    │
│  }                                       │
└──────────────────────────────────────────┘
                    │
                    ↓
STEP 6: Set distance based on zone
┌──────────────────────────────────────────┐
│  zone = TrackingZone.safe                │
│  distance.value = 2.0  // SAFE = 2m      │
└──────────────────────────────────────────┘
                    │
                    ↓
STEP 7: Check for zone transitions
┌──────────────────────────────────────────┐
│  previousZone = OUT_OF_RANGE             │
│  newZone = SAFE                          │
│                                          │
│  Is transition valid for alert?          │
│  OUT_OF_RANGE → SAFE = YES! ✓            │
│                                          │
│  Trigger success alert:                  │
│  • 2 gentle vibrations                   │
│  • isBoundaryExceeded = false             │
└──────────────────────────────────────────┘
                    │
                    ↓
STEP 8: UI reacts via Obx()
┌──────────────────────────────────────────┐
│  All Obx() listeners detect changes:     │
│                                          │
│  Obx(() => Radar(                        │
│    distance: 2.0  ← Updates inner circle │
│  ))                                      │
│                                          │
│  Obx(() => ZoneLabel(                    │
│    zone: "SAFE"  ← Shows green label     │
│  ))                                      │
│                                          │
│  Obx(() => WiFiDisplay(                  │
│    rssi: -62  ← Shows dBm value          │
│  ))                                      │
└──────────────────────────────────────────┘
                    │
                    ↓
STEP 9: Display updates on screen
┌──────────────────────────────────────────┐
│  ╔═══════════════════════════════════╗   │
│  ║  TRACKING STATUS                 ║   │
│  ║  ──────────────────────────────   ║   │
│  ║  Distance: 2.0m                  ║   │
│  ║  Zone: SAFE (Green)              ║   │
│  ║  WiFi RSSI: -62 dBm              ║   │
│  ║  Heading: 45.2° (NE)             ║   │
│  ║                                  ║   │
│  ║  ╔═════════════════════╗         ║   │
│  ║  ║  [Radar]            ║         ║   │
│  ║  ║   • Inner circle     ║         ║   │
│  ║  ║   • Connected ✓      ║         ║   │
│  ║  ╚═════════════════════╝         ║   │
│  ╚═══════════════════════════════════╝   │
└──────────────────────────────────────────┘
```

## Zone Transition Matrix

```
                   FROM
           ┌─────┬─────────┬─────────────┬─────────────┐
           │ ✗   │ SAFE    │ WARNING     │ OUT_OF_RG   │
        ─  ├─────┼─────────┼─────────────┼─────────────┤
        T  │ ✗   │   -     │    -        │    -        │
        O  │     │         │             │             │
           ├─────┼─────────┼─────────────┼─────────────┤
           │SAFE │   -     │   CONT      │ ◄─ ALERT ◄─ │
           │     │    (no  │  (no alert) │ (Critical)  │
        ─  ├─────┤    alert)             │             │
           │WARN │ CONT    │   -         │ ◄─ ALERT ◄─ │
           │     │(no alert)  (no alert) │ (Critical)  │
        ─  ├─────┼─────────┼─────────────┼─────────────┤
           │OOR  │ ALERT   │ ALERT       │   -         │
           │     │ ►────►  │ ►────►      │  (no alert) │
           │     │(Success)│ (Success)   │             │
           └─────┴─────────┴─────────────┴─────────────┘

Legend:
  CONT = Continuous (same zone level, no alert)
  ALERT ►──► = Alert triggered
  - = N/A (same state)
```

## Distance Mapping

```
┌─────────────────────────────────────────────────────┐
│                  ZONE → DISTANCE MAPPING            │
├─────────────────────────────────────────────────────┤
│                                                     │
│  SAFE:                                              │
│  ┌──────────────┐                                   │
│  │     2m       │  <- Inner circle on radar        │
│  └──────────────┘                                   │
│                                                     │
│  WARNING:                                           │
│  ┌──────────────────────────────┐                  │
│  │           5m                 │  <- Middle circle │
│  └──────────────────────────────┘                  │
│                                                     │
│  OUT_OF_RANGE:                                      │
│  ┌───────────────────────────────────────────┐     │
│  │                 8m                         │     │
│  └───────────────────────────────────────────┘     │
│                                                     │
│  DISCONNECTED:                                      │
│  0m (no radar display)                              │
│                                                     │
└─────────────────────────────────────────────────────┘
```

## Alert Decision Tree

```
                   Zone Changed?
                       │
         ┌─────────────┴─────────────┐
         NO                          YES
         │                            │
      Return                  Previous ≠ Current?
                                      │
                              Check transition:
                                      │
                   ┌──────────────────┼──────────────────┐
                   │                  │                  │
              SAFE→OOR            OOR→SAFE/W        Other
              WARNING→OOR         OOR→WARNING        transitions
              │                      │                  │
              ↓                      ↓                  ↓
           ╔════════════╗         ╔════════════╗    No Alert
           ║  CRITICAL  ║         ║  SUCCESS   ║    │
           ║   ALERT    ║         ║   ALERT    ║    Return
           ║ • 4 strong │         ║ • 2 gentle │
           ║   vibrations         │   vibrations      
           ║ • Sound    ║         ║            ║
           ║ • isBoundary         ║ • isBoundary= 
           ║   Exceeded=T         ║   false
           ╚════════════╝         ╚════════════╝
```

## Reactive Variables & Updates

```
BLE Data Received: "45.2,North-East,-62,SAFE"
                        │
                        ↓
    ┌───────────────────────────────────────────┐
    │  Parse: 45.2 | North-East | -62 | SAFE   │
    └───────────────────────────────────────────┘
                        │
        ┌───────────────┼───────────────┐
        │               │               │
        ↓               ↓               ↓
    heading         direction       wifiRssi
      45.2          North-East        -62
        │               │               │
        ↓               ↓               ↓
    headingAngle    direction       current
    .value = 45.2   Label.value   WifiRssi
                   = "North-E"    .value = -62
        │               │               │
        └───────────────┼───────────────┘
                        │
                   Parse zone
                        │
                   "SAFE" → enum
                        │
                        ↓
                  currentZone.value
                  = TrackingZone.safe
                        │
                        ↓
                  _getDistanceForZone()
                        │
                   Return 2.0
                        │
                        ↓
                  distance.value = 2.0
                        │
        ┌───────────────┴───────────────┐
        ↓                               ↓
    UI Updates              Update RSSI Display
    • Radar circles         WiFi RSSI: -62 dBm
    • Zone color
    • Zone label
```

## BLE Characteristic Data Format

```
Raw BLE Notification: [0x34, 0x35, 0x2E, ...]
                      │
                      ↓ UTF-8 Decode
                      │
String: "45.2,North-East,-62,SAFE"
        │      │         │   │
        ├──────┼─────────┼───┼─ Split by ','
        │      │         │   │
        ↓      ↓         ↓   ↓
       45.2  North-East  -62  SAFE
        │      │         │   │
        ├──────┼─────────┼───┤ Parse types
        │      │         │   │
        ↓      ↓         ↓   ↓
      double  String    int String
      45.2   "North-E"  -62  "SAFE"
        │      │         │   │
        └──────┼─────────┼───┤ Assign to
               │         │   │ variables
               ↓         ↓   ↓
        heading       wifi  zone
        45.2          -62   SAFE
```

## UI Component Hierarchy & Reactivity

```
main_view.dart
├── Obx(() => RadarDisplay)
│   └── Watches: controller.distance
│       ├── 2m → Inner circle (SAFE)
│       ├── 5m → Middle circle (WARNING)
│       └── 8m → Outer circle (OUT_OF_RANGE)
│
├── Obx(() => ZoneLabel)
│   └── Watches: controller.currentZone
│       ├── Color: controller.currentZone.displayColor
│       └── Text: controller.currentZone.displayName
│
├── Obx(() => WiFiDisplay)
│   └── Watches: controller.currentWifiRssi
│       └── Displays: "-62 dBm"
│
├── Obx(() => CompassDisplay)
│   ├── Watches: controller.headingAngle
│   │   └── Rotates needle to angle
│   └── Watches: controller.directionLabel
│       └── Shows: "North-East"
│
├── Obx(() => ConnectionStatus)
│   └── Watches: controller.isConnected
│       ├── Connected → "✓ Connected"
│       └── Disconnected → "✗ Disconnected"
│
└── Obx(() => ChildName)
    └── Watches: controller.childName
        └── Shows: Name from Firebase
```

This diagram shows how the entire system flows from ESP32 data through the MainController to the reactive UI updates. Each Obx() widget automatically rebuilds when its watched observable changes.
