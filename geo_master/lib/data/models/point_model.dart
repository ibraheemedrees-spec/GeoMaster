import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'point_model.g.dart';

@HiveType(typeId: 1)
class PointModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double latitude;

  @HiveField(3)
  double longitude;

  @HiveField(4)
  double altitude;

  @HiveField(5)
  double accuracy;

  @HiveField(6)
  String description;

  @HiveField(7)
  String? photoPath;

  @HiveField(8)
  DateTime timestamp;

  @HiveField(9)
  String collectionMode; // single | base_rover | external_gnss

  PointModel({
    String? id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.altitude = 0.0,
    this.accuracy = 0.0,
    this.description = '',
    this.photoPath,
    DateTime? timestamp,
    this.collectionMode = 'single',
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'accuracy': accuracy,
      'description': description,
      'photoPath': photoPath,
      'timestamp': timestamp.toIso8601String(),
      'collectionMode': collectionMode,
    };
  }

  factory PointModel.fromMap(Map<String, dynamic> map) {
    return PointModel(
      id: map['id'],
      name: map['name'] ?? '',
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      altitude: (map['altitude'] as num?)?.toDouble() ?? 0.0,
      accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] ?? '',
      photoPath: map['photoPath'],
      timestamp: DateTime.parse(map['timestamp']),
      collectionMode: map['collectionMode'] ?? 'single',
    );
  }

  PointModel copyWith({
    String? name,
    double? latitude,
    double? longitude,
    double? altitude,
    double? accuracy,
    String? description,
    String? photoPath,
    String? collectionMode,
  }) {
    return PointModel(
      id: id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      accuracy: accuracy ?? this.accuracy,
      description: description ?? this.description,
      photoPath: photoPath ?? this.photoPath,
      timestamp: timestamp,
      collectionMode: collectionMode ?? this.collectionMode,
    );
  }
}
