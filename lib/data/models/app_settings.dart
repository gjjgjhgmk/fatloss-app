import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 11)
class AppSettings extends HiveObject {
  @HiveField(0)
  DateTime cycleStartDate;

  @HiveField(1)
  int skippedDays;

  @HiveField(2)
  List<String> cardioDays; // 格式: "YYYY-MM-DD"

  AppSettings({
    required this.cycleStartDate,
    this.skippedDays = 0,
    List<String>? cardioDays,
  }) : cardioDays = cardioDays ?? [];

  bool isCardioDay(String dateStr) => cardioDays.contains(dateStr);

  void addCardioDay(String dateStr) {
    if (!cardioDays.contains(dateStr)) {
      cardioDays.add(dateStr);
    }
  }

  void removeCardioDay(String dateStr) {
    cardioDays.remove(dateStr);
  }

  AppSettings copyWith({
    DateTime? cycleStartDate,
    int? skippedDays,
    List<String>? cardioDays,
  }) {
    return AppSettings(
      cycleStartDate: cycleStartDate ?? this.cycleStartDate,
      skippedDays: skippedDays ?? this.skippedDays,
      cardioDays: cardioDays ?? List<String>.from(this.cardioDays),
    );
  }
}
