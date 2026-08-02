// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'polygon_model.dart';

class PolygonModelAdapter extends TypeAdapter<PolygonModel> {
  @override
  final int typeId = 3;

  @override
  PolygonModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PolygonModel(
      id: fields[0] as String?,
      name: fields[1] as String,
      points: (fields[2] as List?)?.cast<PointModel>(),
      area: fields[3] as double,
      perimeter: fields[4] as double,
    );
  }

  @override
  void write(BinaryWriter writer, PolygonModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.points)
      ..writeByte(3)
      ..write(obj.area)
      ..writeByte(4)
      ..write(obj.perimeter);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PolygonModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
