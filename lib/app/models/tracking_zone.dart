// ─────────────────────────────────────────────────────────────────────────────
// tracking_zone.dart – Zone-based BLE tracking definitions
// ─────────────────────────────────────────────────────────────────────────────

enum TrackingZone {
  safe,        // RSSI >= -82 (0-2m) | Calibrated at -75 dBm for 1m
  warning,     // RSSI >= -90 (2-5m)
  outOfRange,  // RSSI < -95 (>5m)
  disconnected // No connection
}

extension TrackingZoneExtension on TrackingZone {
  /// Get the display name for the zone
  String get displayName {
    switch (this) {
      case TrackingZone.safe:
        return 'SAFE';
      case TrackingZone.warning:
        return 'WARNING';
      case TrackingZone.outOfRange:
        return 'OUT OF RANGE';
      case TrackingZone.disconnected:
        return 'DISCONNECTED';
    }
  }

  /// Get the display color for the zone
  int get displayColor {
    switch (this) {
      case TrackingZone.safe:
        return 0xFF7BE4A5; // Green
      case TrackingZone.warning:
        return 0xFFFFC857; // Yellow
      case TrackingZone.outOfRange:
        return 0xFFE47B7B; // Red
      case TrackingZone.disconnected:
        return 0xFFB0B0B0; // Gray
    }
  }

  /// Get the estimated distance to display (in meters)
  double get estimatedDistance {
    switch (this) {
      case TrackingZone.safe:
        return 2.0;
      case TrackingZone.warning:
        return 4.0;
      case TrackingZone.outOfRange:
        return 5.0;
      case TrackingZone.disconnected:
        return 0.0;
    }
  }

  /// Get the circle radius factor for radar display (0-1)
  double get radarRadiusFactor {
    switch (this) {
      case TrackingZone.safe:
        return 0.2; // Inner circle
      case TrackingZone.warning:
        return 0.4; // Middle circle
      case TrackingZone.outOfRange:
        return 0.5; // Outer circle
      case TrackingZone.disconnected:
        return 0.0;
    }
  }
}

/// Determine zone from RSSI value
/// Calibrated: -75 dBm = 1m reference
/// Thresholds calculated using path loss formula: distance = 10^((-75 - rssi) / 20)
TrackingZone getZoneFromRssi(int? rssi) {
  if (rssi == null) {
    return TrackingZone.disconnected;
  }

  if (rssi >= -75) {
    return TrackingZone.safe;
  } else if (rssi >= -80) {
    return TrackingZone.warning;
  } else {
    return TrackingZone.outOfRange;
  }
}

/// RSSI Smoothing using EWMA (Exponentially Weighted Moving Average)
class RssiSmoother {
  static const double alpha = 0.3; // Smoothing factor

  double? _previousSmoothedRssi;

  /// Apply EWMA smoothing to RSSI value
  double smooth(int currentRssi) {
    if (_previousSmoothedRssi == null) {
      _previousSmoothedRssi = currentRssi.toDouble();
      return currentRssi.toDouble();
    }

    final smoothed = alpha * currentRssi +
        (1 - alpha) * _previousSmoothedRssi!;
    _previousSmoothedRssi = smoothed;
    return smoothed;
  }

  /// Reset the smoother
  void reset() {
    _previousSmoothedRssi = null;
  }
}

/// Smooth distance interpolation for radar display
class DistanceSmoother {
  double _currentDistance = 0.0;

  /// Apply smooth interpolation to distance
  /// distance = distance * 0.7 + estimatedDistance * 0.3
  double smoothDistance(double estimatedDistance) {
    _currentDistance =
        _currentDistance * 0.7 + estimatedDistance * 0.3;
    return _currentDistance;
  }

  /// Reset to initial state
  void reset() {
    _currentDistance = 0.0;
  }
}
