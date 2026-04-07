// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ingredient.dart';

class IngredientAdapter extends TypeAdapter<Ingredient> {
  @override
  final int typeId = 2;

  @override
  Ingredient read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Ingredient(
      id: fields[0] as String,
      name: fields[1] as String,
      category: fields[2] as String,
      carbPer100g: fields[3] as double,
      proteinPer100g: fields[4] as double,
      fatPer100g: fields[5] as double,
      isCooked: fields[6] as bool,
      isCommon: fields[7] as bool,
      remainingAmount: fields[8] as double?,
      unit: fields[9] as String,
      createdAt: fields[10] as DateTime?,
      updatedAt: fields[11] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Ingredient obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.carbPer100g)
      ..writeByte(4)
      ..write(obj.proteinPer100g)
      ..writeByte(5)
      ..write(obj.fatPer100g)
      ..writeByte(6)
      ..write(obj.isCooked)
      ..writeByte(7)
      ..write(obj.isCommon)
      ..writeByte(8)
      ..write(obj.remainingAmount)
      ..writeByte(9)
      ..write(obj.unit)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IngredientAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
