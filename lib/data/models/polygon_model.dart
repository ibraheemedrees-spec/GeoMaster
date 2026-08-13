import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'point_model.dart';

part 'polygon_model.g.dart';

@HiveType(typeId: 3)
class PolygonModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  List<PointModel> points;

  @HiveField(3)
  double area; // square meters

  @HiveField(4)
  double perimeter; // meters

  PolygonModel({
    String? id,
    required this.name,
    List<PointModel>? points,
    this.area = 0.0,
    this.perimeter = 0.0,
  })  : id = id ?? const Uuid().v4(),
        points = points ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'points': points.map((p) => p.toMap()).toList(),
      'area': area,
      'perimeter': perimeter,
    };
  }

  factory PolygonModel.fromMap(Map<String, dynamic> map) {
    return PolygonModel(
      id: map['id'],
      name: map['name'] ?? '',
      points: (map['points'] as List<dynamic>?)
              ?.map((p) => PointModel.fromMap(p))
              .toList() ??
          [],
      area: (map['area'] as num?)?.toDouble() ?? 0.0,
      perimeter: (map['perimeter'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
