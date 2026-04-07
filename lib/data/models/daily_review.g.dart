// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_review.dart';

class DailyReviewAdapter extends TypeAdapter<DailyReview> {
  @override
  final int typeId = 5;

  @override
  DailyReview read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyReview(
      recordDate: fields[0] as String,
      totalCarbActual: fields[1] as double,
      totalProteinActual: fields[2] as double,
      totalFatActual: fields[3] as double,
      carbStatus: fields[4] as String?,
      proteinStatus: fields[5] as String?,
      fatStatus: fields[6] as String?,
      reviewNotes: fields[7] as String?,
      createdAt: fields[8] as DateTime?,
      updatedAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, DailyReview obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.recordDate)
      ..writeByte(1)
      ..write(obj.totalCarbActual)
      ..writeByte(2)
      ..write(obj.totalProteinActual)
      ..writeByte(3)
      ..write(obj.totalFatActual)
      ..writeByte(4)
      ..write(obj.carbStatus)
      ..writeByte(5)
      ..write(obj.proteinStatus)
      ..writeByte(6)
      ..write(obj.fatStatus)
      ..writeByte(7)
      ..write(obj.reviewNotes)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyReviewAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
