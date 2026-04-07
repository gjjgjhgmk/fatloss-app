// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_template.dart';

class MealTemplateAdapter extends TypeAdapter<MealTemplate> {
  @override
  final int typeId = 1;

  @override
  MealTemplate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MealTemplate(
      dayType: fields[0] as String,
      mealOrder: fields[1] as int,
      mealTime: fields[2] as String,
      carb: fields[3] as double,
      protein: fields[4] as double,
      fat: fields[5] as double,
      isPreWorkout: fields[6] as bool,
      isPostWorkout: fields[7] as bool,
      createdAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, MealTemplate obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.dayType)
      ..writeByte(1)
      ..write(obj.mealOrder)
      ..writeByte(2)
      ..write(obj.mealTime)
      ..writeByte(3)
      ..write(obj.carb)
      ..writeByte(4)
      ..write(obj.protein)
      ..writeByte(5)
      ..write(obj.fat)
      ..writeByte(6)
      ..write(obj.isPreWorkout)
      ..writeByte(7)
      ..write(obj.isPostWorkout)
      ..writeByte(8)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealTemplateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
