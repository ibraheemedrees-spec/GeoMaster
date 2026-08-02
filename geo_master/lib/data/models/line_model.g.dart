// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'line_model.dart';

class LineModelAdapter extends TypeAdapter<LineModel> {
  @override
  final int typeId = 2;

  @override
  LineModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LineModel(
      id: fields[0] as String?,
      name: fields[1] as String,
      points: (fields[2] as List?)?.cast<PointModel>(),
      length: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, LineModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.points)
      ..writeByte(3)
      ..write(obj.length);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LineModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
