// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_item_record.dart';

class MealItemRecordAdapter extends TypeAdapter<MealItemRecord> {
  @override
  final int typeId = 4;

  @override
  MealItemRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MealItemRecord(
      id: fields[0] as String,
      dailyMealRecordId: fields[1] as String,
      ingredientId: fields[2] as String?,
      ingredientName: fields[3] as String,
      amount: fields[4] as double,
      carb: fields[5] as double,
      protein: fields[6] as double,
      fat: fields[7] as double,
      isManualInput: fields[8] as bool,
      createdAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, MealItemRecord obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.dailyMealRecordId)
      ..writeByte(2)
      ..write(obj.ingredientId)
      ..writeByte(3)
      ..write(obj.ingredientName)
      ..writeByte(4)
      ..write(obj.amount)
      ..writeByte(5)
      ..write(obj.carb)
      ..writeByte(6)
      ..write(obj.protein)
      ..writeByte(7)
      ..write(obj.fat)
      ..writeByte(8)
      ..write(obj.isManualInput)
      ..writeByte(9)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealItemRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
