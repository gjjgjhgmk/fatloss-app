// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'waist_record.dart';

class WaistRecordAdapter extends TypeAdapter<WaistRecord> {
  @override
  final int typeId = 10;

  @override
  WaistRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WaistRecord(
      id: fields[0] as String,
      recordDate: fields[1] as String,
      waist: fields[2] as double,
      recordTime: fields[3] as String?,
      notes: fields[4] as String?,
      createdAt: fields[5] as DateTime?,
      updatedAt: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, WaistRecord obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.recordDate)
      ..writeByte(2)
      ..write(obj.waist)
      ..writeByte(3)
      ..write(obj.recordTime)
      ..writeByte(4)
      ..write(obj.notes)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WaistRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
