part of 'project_model.dart';

class ProjectModelAdapter extends TypeAdapter<ProjectModel> {
  @override
  final int typeId = 0;

  @override
  ProjectModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProjectModel(
      id: fields[0] as String?,
      name: fields[1] as String,
      description: fields[2] as String,
      createdAt: fields[3] as DateTime?,
      updatedAt: fields[4] as DateTime?,
      coordinateSystem: fields[5] as String,
      points: (fields[6] as List?)?.cast<PointModel>(),
      lines: (fields[7] as List?)?.cast<LineModel>(),
      polygons: (fields[8] as List?)?.cast<PolygonModel>(),
      layers: (fields[9] as List?)?.cast<LayerModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, ProjectModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt)
      ..writeByte(5)
      ..write(obj.coordinateSystem)
      ..writeByte(6)
      ..write(obj.points)
      ..writeByte(7)
      ..write(obj.lines)
      ..writeByte(8)
      ..write(obj.polygons)
      ..writeByte(9)
      ..write(obj.layers);
  }
}
