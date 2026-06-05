// ─────────────────────────────────────────────────────────────────────────────
// safety_zone.dart – Preset safety zones for child tracking
// ─────────────────────────────────────────────────────────────────────────────

enum SafetyZone { nearChild, sameRoom, homeZone, extendedZone }

extension SafetyZoneExtension on SafetyZone {
  /// Get the display emoji for the zone
  String get emoji {
    switch (this) {
      case SafetyZone.nearChild:
        return '👶';
      case SafetyZone.sameRoom:
        return '🏠';
      case SafetyZone.homeZone:
        return '🏡';
      case SafetyZone.extendedZone:
        return '🌳';
    }
  }

  /// Get the display name for the zone
  String get displayName {
    switch (this) {
      case SafetyZone.nearChild:
        return 'Near Child';
      case SafetyZone.sameRoom:
        return 'Same Room';
      case SafetyZone.homeZone:
        return 'Home Zone';
      case SafetyZone.extendedZone:
        return 'Extended Zone';
    }
  }

  /// Get the radius in meters
  double get radiusInMeters {
    switch (this) {
      case SafetyZone.nearChild:
        return 2.0;
      case SafetyZone.sameRoom:
        return 5.0;
      case SafetyZone.homeZone:
        return 10.0;
      case SafetyZone.extendedZone:
        return 15.0;
    }
  }

  /// Get the radar circle scale factor (0-1)
  double get radarCircleFactor {
    switch (this) {
      case SafetyZone.nearChild:
        return 0.2;
      case SafetyZone.sameRoom:
        return 0.33;
      case SafetyZone.homeZone:
        return 0.67;
      case SafetyZone.extendedZone:
        return 1.0;
    }
  }

  /// Get the hex color code for the zone
  int get displayColor {
    switch (this) {
      case SafetyZone.nearChild:
      case SafetyZone.sameRoom:
        return 0xFF7BE4A5; // Green
      case SafetyZone.homeZone:
      case SafetyZone.extendedZone:
        return 0xFFFFC857; // Yellow/Orange
    }
  }

  /// Get the string key for SharedPreferences
  String get storageKey {
    switch (this) {
      case SafetyZone.nearChild:
        return 'nearChild';
      case SafetyZone.sameRoom:
        return 'sameRoom';
      case SafetyZone.homeZone:
        return 'homeZone';
      case SafetyZone.extendedZone:
        return 'extendedZone';
    }
  }

  /// Parse from storage string
  static SafetyZone fromStorageString(String value) {
    switch (value) {
      case 'nearChild':
        return SafetyZone.nearChild;
      case 'sameRoom':
        return SafetyZone.sameRoom;
      case 'homeZone':
        return SafetyZone.homeZone;
      case 'extendedZone':
        return SafetyZone.extendedZone;
      default:
        return SafetyZone.sameRoom; // Default to Same Room
    }
  }
}
