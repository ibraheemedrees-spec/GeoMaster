import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'point_model.dart';
import 'line_model.dart';
import 'polygon_model.dart';
import 'layer_model.dart';

part 'project_model.g.dart';

@HiveType(typeId: 0)
class ProjectModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String description;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  DateTime updatedAt;

  @HiveField(5)
  String coordinateSystem; // WGS84, UTM, Local...

  @HiveField(6)
  List<PointModel> points;

  @HiveField(7)
  List<LineModel> lines;

  @HiveField(8)
  List<PolygonModel> polygons;

  @HiveField(9)
  List<LayerModel> layers;

  ProjectModel({
    String? id,
    required this.name,
    this.description = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.coordinateSystem = 'WGS84',
    List<PointModel>? points,
    List<LineModel>? lines,
    List<PolygonModel>? polygons,
    List<LayerModel>? layers,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        points = points ?? [],
        lines = lines ?? [],
        polygons = polygons ?? [],
        layers = layers ?? [LayerModel(name: 'Default')];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'coordinateSystem': coordinateSystem,
      'points': points.map((p) => p.toMap()).toList(),
      'lines': lines.map((l) => l.toMap()).toList(),
      'polygons': polygons.map((p) => p.toMap()).toList(),
      'layers': layers.map((l) => l.toMap()).toList(),
    };
  }

  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    return ProjectModel(
      id: map['id'],
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      coordinateSystem: map['coordinateSystem'] ?? 'WGS84',
      points: (map['points'] as List<dynamic>?)
              ?.map((p) => PointModel.fromMap(p))
              .toList() ??
          [],
      lines: (map['lines'] as List<dynamic>?)
              ?.map((l) => LineModel.fromMap(l))
              .toList() ??
          [],
      polygons: (map['polygons'] as List<dynamic>?)
              ?.map((p) => PolygonModel.fromMap(p))
              .toList() ??
          [],
      layers: (map['layers'] as List<dynamic>?)
              ?.map((l) => LayerModel.fromMap(l))
              .toList() ??
          [LayerModel(name: 'Default')],
    );
  }

  ProjectModel copyWith({
    String? name,
    String? description,
    String? coordinateSystem,
    List<PointModel>? points,
    List<LineModel>? lines,
    List<PolygonModel>? polygons,
  }) {
    return ProjectModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      coordinateSystem: coordinateSystem ?? this.coordinateSystem,
      points: points ?? this.points,
      lines: lines ?? this.lines,
      polygons: polygons ?? this.polygons,
    );
  }
}
