import 'dart:math' as math;

class CoordConverter {
  // WGS84 constants
  static const double a = 6378137.0; // semi-major axis
  static const double f = 1 / 298.257223563; // flattening
  static const double e2 = f * (2 - f); // eccentricity squared
  static const double k0 = 0.9996; // UTM scale factor

  /// Convert WGS84 lat/lon to UTM
  /// Returns [easting, northing, zoneNumber, zoneLetter]
  static List<dynamic> wgs84ToUtm(double lat, double lon) {
    final zoneNumber = ((lon + 180) / 6).floor() + 1;
    final lonOrigin = (zoneNumber - 1) * 6 - 180 + 3; // central meridian

    final latRad = lat * math.pi / 180;
    final lonRad = lon * math.pi / 180;
    final lonOriginRad = lonOrigin * math.pi / 180;

    final N = a / math.sqrt(1 - e2 * math.sin(latRad) * math.sin(latRad));
    final T = math.tan(latRad) * math.tan(latRad);
    final C = e2 / (1 - e2) * math.cos(latRad) * math.cos(latRad);
    final A = math.cos(latRad) * (lonRad - lonOriginRad);

    final M = a * ((1 - e2 / 4 - 3 * e2 * e2 / 64 - 5 * e2 * e2 * e2 / 256) * latRad
        - (3 * e2 / 8 + 3 * e2 * e2 / 32 + 45 * e2 * e2 * e2 / 1024) * math.sin(2 * latRad)
        + (15 * e2 * e2 / 256 + 45 * e2 * e2 * e2 / 1024) * math.sin(4 * latRad)
        - (35 * e2 * e2 * e2 / 3072) * math.sin(6 * latRad));

    final easting = k0 * N * (A + (1 - T + C) * A * A * A / 6
        + (5 - 18 * T + T * T + 72 * C - 58 * e2 / (1 - e2)) * A * A * A * A * A / 120) + 500000.0;

    var northing = k0 * (M + N * math.tan(latRad) * (A * A / 2
        + (5 - T + 9 * C + 4 * C * C) * A * A * A * A / 24
        + (61 - 58 * T + T * T + 600 * C - 330 * e2 / (1 - e2)) * A * A * A * A * A * A / 720));

    if (lat < 0) northing += 10000000.0; // southern hemisphere

    final zoneLetter = _utmLetter(lat);
    return [easting, northing, zoneNumber, zoneLetter];
  }

  static String _utmLetter(double lat) {
    const letters = 'CDEFGHJKLMNPQRSTUVWX';
    if (lat < -80 || lat > 84) return 'Z';
    return letters[((lat + 80) / 8).floor()];
  }

  /// Simple local grid: origin + offsets in meters (approximate flat earth)
  static List<double> toLocalGrid(double lat, double lon, double originLat, double originLon) {
    final dx = distance(originLat, originLon, originLat, lon) * (lon > originLon ? 1 : -1);
    final dy = distance(originLat, originLon, lat, originLon) * (lat > originLat ? 1 : -1);
    return [dx, dy];
  }

  static double distance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) * math.cos(_rad(lat2)) * math.sin(dLon / 2) * math.sin(dLon / 2);
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _rad(double d) => d * math.pi / 180;

  /// Format coordinates based on system
  static String format(double lat, double lon, String system, {double? originLat, double? originLon}) {
    switch (system) {
      case 'UTM':
        final r = wgs84ToUtm(lat, lon);
        return 'E: ${r[0].toStringAsFixed(2)}  N: ${r[1].toStringAsFixed(2)}  Zone ${r[2]}${r[3]}';
      case 'Local':
        if (originLat != null && originLon != null) {
          final g = toLocalGrid(lat, lon, originLat, originLon);
          return 'X: ${g[0].toStringAsFixed(2)} m  Y: ${g[1].toStringAsFixed(2)} m';
        }
        return '${lat.toStringAsFixed(8)}, ${lon.toStringAsFixed(8)}';
      default:
        return '${lat.toStringAsFixed(8)}, ${lon.toStringAsFixed(8)}';
    }
  }
}
