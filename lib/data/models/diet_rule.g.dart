// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diet_rule.dart';

class DietRuleAdapter extends TypeAdapter<DietRule> {
  @override
  final int typeId = 0;

  @override
  DietRule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DietRule(
      dayType: fields[0] as String,
      totalCarb: fields[1] as double,
      totalProtein: fields[2] as double,
      totalFat: fields[3] as double,
      mealCount: fields[4] as int,
      specialNotes: fields[5] as String?,
      createdAt: fields[6] as DateTime?,
      updatedAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, DietRule obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.dayType)
      ..writeByte(1)
      ..write(obj.totalCarb)
      ..writeByte(2)
      ..write(obj.totalProtein)
      ..writeByte(3)
      ..write(obj.totalFat)
      ..writeByte(4)
      ..write(obj.mealCount)
      ..writeByte(5)
      ..write(obj.specialNotes)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DietRuleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
