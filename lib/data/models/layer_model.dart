import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'layer_model.g.dart';

@HiveType(typeId: 4)
class LayerModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  bool visible;

  @HiveField(3)
  int colorValue; // Color value

  LayerModel({
    String? id,
    required this.name,
    this.visible = true,
    this.colorValue = 0xFF1A73E8,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'visible': visible,
        'colorValue': colorValue,
      };

  factory LayerModel.fromMap(Map<String, dynamic> map) => LayerModel(
        id: map['id'],
        name: map['name'] ?? 'Layer',
        visible: map['visible'] ?? true,
        colorValue: map['colorValue'] ?? 0xFF1A73E8,
      );
}
