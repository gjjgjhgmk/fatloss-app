// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weekly_review.dart';

class WeeklyReviewAdapter extends TypeAdapter<WeeklyReview> {
  @override
  final int typeId = 6;

  @override
  WeeklyReview read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WeeklyReview(
      id: fields[0] as String,
      weekStartDate: fields[1] as String,
      weekEndDate: fields[2] as String,
      avgCarbIntake: fields[3] as double,
      avgProteinIntake: fields[4] as double,
      avgFatIntake: fields[5] as double,
      carbComplianceRate: fields[6] as double,
      proteinComplianceRate: fields[7] as double,
      fatComplianceRate: fields[8] as double,
      totalSkippedMeals: fields[9] as int,
      notes: fields[10] as String?,
      createdAt: fields[11] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, WeeklyReview obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.weekStartDate)
      ..writeByte(2)
      ..write(obj.weekEndDate)
      ..writeByte(3)
      ..write(obj.avgCarbIntake)
      ..writeByte(4)
      ..write(obj.avgProteinIntake)
      ..writeByte(5)
      ..write(obj.avgFatIntake)
      ..writeByte(6)
      ..write(obj.carbComplianceRate)
      ..writeByte(7)
      ..write(obj.proteinComplianceRate)
      ..writeByte(8)
      ..write(obj.fatComplianceRate)
      ..writeByte(9)
      ..write(obj.totalSkippedMeals)
      ..writeByte(10)
      ..write(obj.notes)
      ..writeByte(11)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeeklyReviewAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
