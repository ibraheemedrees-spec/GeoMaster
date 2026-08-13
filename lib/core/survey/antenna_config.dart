class AntennaConfig {
  String manufacturer;
  String model;
  double heightM;
  String measureType; // vertical | slant
  double? arpToPhaseCenterM;

  AntennaConfig({
    this.manufacturer = 'Generic',
    this.model = 'Default',
    this.heightM = 0.0,
    this.measureType = 'vertical',
    this.arpToPhaseCenterM,
  });

  /// Antenna height contribution to mark elevation (simplified vertical).
  double get verticalOffset {
    if (measureType == 'slant' && heightM > 0) {
      // Without antenna radius, slant cannot be reduced accurately.
      return heightM;
    }
    return heightM;
  }

  Map<String, dynamic> toMap() => {
        'manufacturer': manufacturer,
        'model': model,
        'heightM': heightM,
        'measureType': measureType,
        'arpToPhaseCenterM': arpToPhaseCenterM,
      };

  factory AntennaConfig.fromMap(Map map) => AntennaConfig(
        manufacturer: map['manufacturer'] as String? ?? 'Generic',
        model: map['model'] as String? ?? 'Default',
        heightM: (map['heightM'] as num?)?.toDouble() ?? 0.0,
        measureType: map['measureType'] as String? ?? 'vertical',
        arpToPhaseCenterM: (map['arpToPhaseCenterM'] as num?)?.toDouble(),
      );
}
