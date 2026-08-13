// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: flutter pub run build_runner build

part of 'point_model.dart';

class PointModelAdapter extends TypeAdapter<PointModel> {
  @override
  final int typeId = 1;

  @override
  PointModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PointModel(
      id: fields[0] as String?,
      name: fields[1] as String,
      latitude: fields[2] as double,
      longitude: fields[3] as double,
      altitude: fields[4] as double,
      accuracy: fields[5] as double,
      description: fields[6] as String,
      photoPath: fields[7] as String?,
      timestamp: fields[8] as DateTime?,
      collectionMode: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PointModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.latitude)
      ..writeByte(3)
      ..write(obj.longitude)
      ..writeByte(4)
      ..write(obj.altitude)
      ..writeByte(5)
      ..write(obj.accuracy)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.photoPath)
      ..writeByte(8)
      ..write(obj.timestamp)
      ..writeByte(9)
      ..write(obj.collectionMode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PointModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
