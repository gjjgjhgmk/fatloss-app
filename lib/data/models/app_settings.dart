import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 11)
class AppSettings extends HiveObject {
  @HiveField(0)
  DateTime cycleStartDate;

  @HiveField(1)
  int skippedDays;

  @HiveField(2)
  List<String> cardioDays;

  @HiveField(3)
  List<String> manualRestDays;

  AppSettings({
    required this.cycleStartDate,
    this.skippedDays = 0,
    List<String>? cardioDays,
    List<String>? manualRestDays,
  })  : cardioDays = cardioDays ?? <String>[],
        manualRestDays = manualRestDays ?? <String>[];

  bool isCardioDay(String dateStr) => cardioDays.contains(dateStr);

  void addCardioDay(String dateStr) {
    if (!cardioDays.contains(dateStr)) {
      cardioDays.add(dateStr);
    }
  }

  void removeCardioDay(String dateStr) {
    cardioDays.remove(dateStr);
  }

  bool isManualRestDay(String dateStr) => manualRestDays.contains(dateStr);

  void addManualRestDay(String dateStr) {
    if (!manualRestDays.contains(dateStr)) {
      manualRestDays.add(dateStr);
    }
  }

  void removeManualRestDay(String dateStr) {
    manualRestDays.remove(dateStr);
  }

  AppSettings copyWith({
    DateTime? cycleStartDate,
    int? skippedDays,
    List<String>? cardioDays,
    List<String>? manualRestDays,
  }) {
    return AppSettings(
      cycleStartDate: cycleStartDate ?? this.cycleStartDate,
      skippedDays: skippedDays ?? this.skippedDays,
      cardioDays: cardioDays ?? List<String>.from(this.cardioDays),
      manualRestDays: manualRestDays ?? List<String>.from(this.manualRestDays),
    );
  }
}
