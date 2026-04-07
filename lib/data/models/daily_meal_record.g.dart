// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_meal_record.dart';

class DailyMealRecordAdapter extends TypeAdapter<DailyMealRecord> {
  @override
  final int typeId = 3;

  @override
  DailyMealRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyMealRecord(
      id: fields[0] as String,
      recordDate: fields[1] as String,
      dayType: fields[2] as String,
      mealOrder: fields[3] as int,
      mealTime: fields[4] as String,
      plannedCarb: fields[5] as double,
      plannedProtein: fields[6] as double,
      plannedFat: fields[7] as double,
      actualCarb: fields[8] as double,
      actualProtein: fields[9] as double,
      actualFat: fields[10] as double,
      mealStatus: fields[11] as String,
      notes: fields[12] as String?,
      isPreWorkout: fields[13] as bool,
      isPostWorkout: fields[14] as bool,
      createdAt: fields[15] as DateTime?,
      updatedAt: fields[16] as DateTime?,
      items: (fields[17] as List?)?.cast<MealItemRecord>() ?? [],
      photoUrl: fields[18] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DailyMealRecord obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.recordDate)
      ..writeByte(2)
      ..write(obj.dayType)
      ..writeByte(3)
      ..write(obj.mealOrder)
      ..writeByte(4)
      ..write(obj.mealTime)
      ..writeByte(5)
      ..write(obj.plannedCarb)
      ..writeByte(6)
      ..write(obj.plannedProtein)
      ..writeByte(7)
      ..write(obj.plannedFat)
      ..writeByte(8)
      ..write(obj.actualCarb)
      ..writeByte(9)
      ..write(obj.actualProtein)
      ..writeByte(10)
      ..write(obj.actualFat)
      ..writeByte(11)
      ..write(obj.mealStatus)
      ..writeByte(12)
      ..write(obj.notes)
      ..writeByte(13)
      ..write(obj.isPreWorkout)
      ..writeByte(14)
      ..write(obj.isPostWorkout)
      ..writeByte(15)
      ..write(obj.createdAt)
      ..writeByte(16)
      ..write(obj.updatedAt)
      ..writeByte(17)
      ..write(obj.items)
      ..writeByte(18)
      ..write(obj.photoUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyMealRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
