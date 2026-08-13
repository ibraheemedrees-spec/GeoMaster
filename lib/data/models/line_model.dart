import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'point_model.dart';

part 'line_model.g.dart';

@HiveType(typeId: 2)
class LineModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  List<PointModel> points;

  @HiveField(3)
  double length; // meters

  LineModel({
    String? id,
    required this.name,
    List<PointModel>? points,
    this.length = 0.0,
  })  : id = id ?? const Uuid().v4(),
        points = points ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'points': points.map((p) => p.toMap()).toList(),
      'length': length,
    };
  }

  factory LineModel.fromMap(Map<String, dynamic> map) {
    return LineModel(
      id: map['id'],
      name: map['name'] ?? '',
      points: (map['points'] as List<dynamic>?)
              ?.map((p) => PointModel.fromMap(p))
              .toList() ??
          [],
      length: (map['length'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
