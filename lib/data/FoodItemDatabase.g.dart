// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'FoodItemDatabase.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FoodItemDatabaseAdapter extends TypeAdapter<FoodItemDatabase> {
  @override
  final int typeId = 3;

  @override
  FoodItemDatabase read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FoodItemDatabase(
      id: fields[0] as String,
      name: fields[1] as String,
      calories: fields[2] as String,
      protein: fields[3] as String,
      carbs: fields[4] as String,
      fats: fields[5] as String,
      date: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, FoodItemDatabase obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.calories)
      ..writeByte(3)
      ..write(obj.protein)
      ..writeByte(4)
      ..write(obj.carbs)
      ..writeByte(5)
      ..write(obj.fats)
      ..writeByte(6)
      ..write(obj.date);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FoodItemDatabaseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
