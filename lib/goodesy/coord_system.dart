class CoordSystemDef {
  final String id;
  final String name;
  final String type; // geographic | utm | projected | local
  final String? epsg;
  final String? datum;
  final String? projection;
  final int? utmZone;
  final bool northern;

  const CoordSystemDef({
    required this.id,
    required this.name,
    required this.type,
    this.epsg,
    this.datum,
    this.projection,
    this.utmZone,
    this.northern = true,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'epsg': epsg,
        'datum': datum,
        'projection': projection,
        'utmZone': utmZone,
        'northern': northern,
      };

  factory CoordSystemDef.fromMap(Map map) => CoordSystemDef(
        id: map['id'] as String? ?? 'wgs84',
        name: map['name'] as String? ?? 'WGS 84',
        type: map['type'] as String? ?? 'geographic',
        epsg: map['epsg'] as String?,
        datum: map['datum'] as String?,
        projection: map['projection'] as String?,
        utmZone: map['utmZone'] as int?,
        northern: map['northern'] as bool? ?? true,
      );
}

class CoordSystemCatalog {
  static final List<CoordSystemDef> builtIn = [
    const CoordSystemDef(id: 'wgs84', name: 'WGS 84 (Geographic)', type: 'geographic', epsg: 'EPSG:4326', datum: 'WGS84'),
    const CoordSystemDef(id: 'utm36n', name: 'UTM Zone 36N', type: 'utm', epsg: 'EPSG:32636', datum: 'WGS84', utmZone: 36, northern: true),
    const CoordSystemDef(id: 'utm37n', name: 'UTM Zone 37N', type: 'utm', epsg: 'EPSG:32637', datum: 'WGS84', utmZone: 37, northern: true),
    const CoordSystemDef(id: 'utm35n', name: 'UTM Zone 35N', type: 'utm', epsg: 'EPSG:32635', datum: 'WGS84', utmZone: 35, northern: true),
    const CoordSystemDef(id: 'webmerc', name: 'Web Mercator', type: 'projected', epsg: 'EPSG:3857', datum: 'WGS84'),
    const CoordSystemDef(id: 'local', name: 'Local Grid (user)', type: 'local', datum: 'Local'),
  ];

  static CoordSystemDef byId(String id) =>
      builtIn.firstWhere((e) => e.id == id, orElse: () => builtIn.first);
}
