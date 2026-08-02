part of 'layer_model.dart';

class LayerModelAdapter extends TypeAdapter<LayerModel> {
  @override
  final int typeId = 4;

  @override
  LayerModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LayerModel(
      id: fields[0] as String?,
      name: fields[1] as String,
      visible: fields[2] as bool,
      colorValue: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, LayerModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.visible)
      ..writeByte(3)
      ..write(obj.colorValue);
  }
}
