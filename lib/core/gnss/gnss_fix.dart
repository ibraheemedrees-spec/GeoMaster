/// Unified GNSS solution snapshot. Missing values stay null (UI shows "--").
class GnssFix {
  final double? latitude;
  final double? longitude;
  final double? ellipsoidalHeight;
  final double? orthometricHeight;
  final double? geoidSeparation;
  final double? horizontalAccuracy;
  final double? verticalAccuracy;
  final String fixType; // none | gps | dgps | rtk_float | rtk_fixed | estimated
  final String rtkStatus; // NONE | FLOAT | FIXED | DGPS | SINGLE
  final int? satellitesVisible;
  final int? satellitesUsed;
  final double? pdop;
  final double? hdop;
  final double? vdop;
  final double? correctionAgeSec;
  final double? heading;
  final double? speedMps;
  final DateTime? gnssTime;
  final String source; // internal | bluetooth | ntrip | unknown
  final DateTime timestamp;

  const GnssFix({
    this.latitude,
    this.longitude,
    this.ellipsoidalHeight,
    this.orthometricHeight,
    this.geoidSeparation,
    this.horizontalAccuracy,
    this.verticalAccuracy,
    this.fixType = 'none',
    this.rtkStatus = 'NONE',
    this.satellitesVisible,
    this.satellitesUsed,
    this.pdop,
    this.hdop,
    this.vdop,
    this.correctionAgeSec,
    this.heading,
    this.speedMps,
    this.gnssTime,
    this.source = 'unknown',
    required this.timestamp,
  });

  static GnssFix empty() => GnssFix(timestamp: DateTime.now());

  bool get hasPosition => latitude != null && longitude != null;

  String fmt(num? v, [int digits = 3]) =>
      v == null ? '--' : v.toStringAsFixed(digits);

  String get latStr => latitude == null ? '--' : latitude!.toStringAsFixed(8);
  String get lonStr => longitude == null ? '--' : longitude!.toStringAsFixed(8);
}
