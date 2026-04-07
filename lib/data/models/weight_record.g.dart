// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weight_record.dart';

class WeightRecordAdapter extends TypeAdapter<WeightRecord> {
  @override
  final int typeId = 7;

  @override
  WeightRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WeightRecord(
      id: fields[0] as String,
      recordDate: fields[1] as String,
      timeOfDay: fields[2] as String,
      weight: fields[3] as double,
      recordTime: fields[4] as String?,
      notes: fields[5] as String?,
      createdAt: fields[6] as DateTime?,
      updatedAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, WeightRecord obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.recordDate)
      ..writeByte(2)
      ..write(obj.timeOfDay)
      ..writeByte(3)
      ..write(obj.weight)
      ..writeByte(4)
      ..write(obj.recordTime)
      ..writeByte(5)
      ..write(obj.notes)
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
      other is WeightRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
