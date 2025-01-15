// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'NutritionalInfo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NutritionalInfoAdapter extends TypeAdapter<NutritionalInfo> {
  @override
  final int typeId = 5;

  @override
  NutritionalInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NutritionalInfo(
      calories: fields[0] as String,
      protein: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, NutritionalInfo obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.calories)
      ..writeByte(1)
      ..write(obj.protein);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NutritionalInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
