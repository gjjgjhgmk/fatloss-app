import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/workout_constants.dart';
import '../../core/utils/nutrition_calculator.dart';
import '../../core/utils/date_type_resolver.dart';
import '../../data/models/workout_record.dart';
import '../../data/repositories/workout_record_repository.dart';
import '../../domain/usecases/daily_diet_manager.dart';
import '../providers/diet_provider.dart';
import '../providers/workout_provider.dart';
import 'meal_record_page.dart';
import 'review_page.dart';
import 'weight_record_page.dart';
import 'waist_record_page.dart';
import 'ingredient_page.dart';
import 'workout_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final WorkoutRecordRepository _workoutRepo = WorkoutRecordRepository();
  final Map<String, WorkoutRecord?> _workoutCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DietProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117), // 深色背景
      body: Consumer<DietProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00D9FF)),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadDailyStatus(),
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          final status = provider.dailyStatus;
          if (status == null) {
            return const Center(child: Text('暂无数据'));
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadDailyStatus(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildAppBar(context, provider)),
                SliverToBoxAdapter(child: _buildMonthlyGoal(context, provider)),
                SliverToBoxAdapter(child: _buildDayTypeSelector(context, provider)),
                SliverToBoxAdapter(child: _buildNutritionProgress(status)),
                SliverToBoxAdapter(child: _buildMealList(context, provider, status)),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, DietProvider provider) {
    final dateFormat = DateFormat('M月d日 E');
    final status = provider.dailyStatus;
    final dayColor = Color(WorkoutConstants.DAY_TYPE_COLORS[status?.dayType ?? 'rest'] ?? 0xFF9E9E9E);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            dayColor.withOpacity(0.3),
            const Color(0xFF0D1117),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '碳循环减脂',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: dayColor,
                      shadows: [
                        Shadow(
                          color: dayColor.withOpacity(0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateFormat.format(provider.selectedDate),
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.restaurant_menu, color: Colors.white70),
                    onPressed: () => _navigateToIngredients(context),
                    tooltip: '食材库',
                  ),
                  IconButton(
                    icon: const Icon(Icons.bar_chart, color: Colors.white70),
                    onPressed: () => _navigateToReview(context),
                    tooltip: '复盘',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDayTypeChips(context, provider, status),
        ],
      ),
    );
  }

  Widget _buildDayTypeChips(BuildContext context, DietProvider provider, DailyDietStatus? status) {
    final currentDayType = status?.dayType ?? 'rest';
    final isCardio = DateTypeResolver.isCardioDay(provider.selectedDate);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildDayTypeChip(
          context,
          '休息日',
          'rest',
          currentDayType == 'rest',
          Colors.grey,
          () => _navigateToWorkout(context, provider.selectedDate, 'rest'),
        ),
        _buildDayTypeChip(
          context,
          '练背日',
          'back',
          currentDayType == 'back',
          const Color(0xFF1E88E5),
          () => _navigateToWorkout(context, provider.selectedDate, 'back'),
        ),
        _buildDayTypeChip(
          context,
          '练胸日',
          'chest',
          currentDayType == 'chest',
          const Color(0xFFE53935),
          () => _navigateToWorkout(context, provider.selectedDate, 'chest'),
        ),
        _buildDayTypeChip(
          context,
          '练腿日',
          'leg',
          currentDayType == 'leg',
          const Color(0xFF43A047),
          () => _navigateToWorkout(context, provider.selectedDate, 'leg'),
        ),
        _buildDayTypeChip(
          context,
          '练肩日',
          'shoulder',
          currentDayType == 'shoulder',
          const Color(0xFFFF9800),
          () => _navigateToWorkout(context, provider.selectedDate, 'shoulder'),
        ),
        _buildDayTypeChip(
          context,
          '空腹有氧',
          'cardio',
          isCardio,
          const Color(0xFFE91E63),
          () => _navigateToWorkout(context, provider.selectedDate, 'cardio'),
        ),
      ],
    );
  }

  Widget _buildDayTypeChip(
    BuildContext context,
    String label,
    String dayType,
    bool isSelected,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyGoal(BuildContext context, DietProvider provider) {
    // 获取最新体重
    final latestWeight = _getLatestWeight();
    final startWeight = WorkoutConstants.APRIL_START_WEIGHT;
    final goalWeight = WorkoutConstants.APRIL_GOAL_WEIGHT;

    double weightLoss = startWeight - latestWeight;
    double totalGoal = startWeight - goalWeight;
    double progress = totalGoal > 0 ? (weightLoss / totalGoal).clamp(0.0, 1.0) : 0.0;
    double remaining = goalWeight - latestWeight;

    Color progressColor;
    if (progress < 0.5) {
      progressColor = Colors.red;
    } else if (progress < 0.8) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.green;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1F35),
            const Color(0xFF0D1117),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: progressColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: progressColor.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '四月目标',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: progressColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  remaining > 0 ? '还剩 ${remaining.toStringAsFixed(1)}kg' : '已达成!',
                  style: TextStyle(color: progressColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '${latestWeight.toStringAsFixed(1)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                ' kg',
                style: TextStyle(color: Colors.grey, fontSize: 18),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${startWeight.toStringAsFixed(0)} → ${goalWeight.toStringAsFixed(0)} kg',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    '-${weightLoss.toStringAsFixed(1)} kg',
                    style: TextStyle(color: progressColor, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('0%', style: TextStyle(color: Colors.grey, fontSize: 10)),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(color: progressColor, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const Text('100%', style: TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  double _getLatestWeight() {
    // 尝试从 provider 获取最新体重，如果没有则用起始体重
    // 这里简化处理，实际可以从 WeightRecordRepository 获取
    return WorkoutConstants.APRIL_START_WEIGHT;
  }

  Widget _buildDayTypeSelector(BuildContext context, DietProvider provider) {
    final status = provider.dailyStatus;
    if (status == null) return const SizedBox();

    final dayColor = Color(WorkoutConstants.DAY_TYPE_COLORS[status.dayType] ?? 0xFF9E9E9E);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dayColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: dayColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getDayTypeIcon(status.dayType),
              color: dayColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.dayTypeName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (DateTypeResolver.isCardioDay(provider.selectedDate))
                  const Text(
                    '空腹有氧日',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _navigateToWorkout(context, provider.selectedDate, status.dayType),
            style: TextButton.styleFrom(
              backgroundColor: dayColor.withOpacity(0.2),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fitness_center, color: dayColor, size: 18),
                const SizedBox(width: 4),
                Text(
                  '运动打卡',
                  style: TextStyle(color: dayColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionProgress(DailyDietStatus status) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart, color: Color(0xFF00D9FF), size: 20),
              SizedBox(width: 8),
              Text(
                '营养素进度',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildNutritionBar('碳水', status.totalActual.carb, status.plannedCarb, Colors.orange),
          const SizedBox(height: 12),
          _buildNutritionBar('蛋白质', status.totalActual.protein, status.plannedProtein, Colors.red),
          const SizedBox(height: 12),
          _buildNutritionBar('脂肪', status.totalActual.fat, status.plannedFat, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildNutritionBar(String label, double actual, double planned, Color color) {
    final progress = planned > 0 ? (actual / planned).clamp(0.0, 1.5) : 0.0;
    final percentage = (progress * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70)),
            Text(
              '${actual.toStringAsFixed(0)}/${planned.toStringAsFixed(0)}g  $percentage%',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: Colors.grey[800],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildMealList(BuildContext context, DietProvider provider, DailyDietStatus status) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.restaurant, color: Color(0xFF00D9FF), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '今日餐次 (${status.completedMeals}/${status.totalMeals})',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (status.skippedMeals > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '已跳过${status.skippedMeals}餐',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ...status.meals.map((meal) => _buildMealCard(context, provider, meal)),
        ],
      ),
    );
  }

  Widget _buildMealCard(BuildContext context, DietProvider provider, meal) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (meal.isSkipped) {
      statusColor = Colors.grey;
      statusIcon = Icons.remove_circle_outline;
      statusText = '已跳过';
    } else if (meal.isCompleted) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = '已完成';
    } else {
      statusColor = const Color(0xFF00D9FF);
      statusIcon = Icons.pending;
      statusText = '待记录';
    }

    String mealLabel = '第${meal.mealOrder}餐 ${meal.mealTime}';
    if (meal.isPreWorkout) mealLabel = '练前餐 ${meal.mealTime}';
    if (meal.isPostWorkout) mealLabel = '练后餐 ${meal.mealTime}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: meal.isSkipped ? null : () => _navigateToMealRecord(context, meal.mealOrder),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          mealLabel,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        if (meal.hasPhoto) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.photo_camera, size: 16, color: Colors.green),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildMiniChip('碳水', meal.actualCarb, Colors.orange),
                        const SizedBox(width: 8),
                        _buildMiniChip('蛋白', meal.actualProtein, Colors.red),
                        const SizedBox(width: 8),
                        _buildMiniChip('脂肪', meal.actualFat, Colors.blue),
                      ],
                    ),
                  ],
                ),
              ),
              if (!meal.isSkipped && !meal.isCompleted)
                ElevatedButton(
                  onPressed: () => _navigateToMealRecord(context, meal.mealOrder),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D9FF),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('记录'),
                ),
              if (meal.isCompleted)
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.grey),
                  onPressed: () => _navigateToMealRecord(context, meal.mealOrder),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniChip(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: ${value.toStringAsFixed(0)}g',
        style: TextStyle(fontSize: 11, color: color),
      ),
    );
  }

  void _navigateToWorkout(BuildContext context, DateTime date, String dayType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkoutPage(date: date, dayType: dayType),
      ),
    );
  }

  void _navigateToMealRecord(BuildContext context, int mealOrder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MealRecordPage(mealOrder: mealOrder),
      ),
    );
  }

  void _navigateToReview(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReviewPage(),
      ),
    );
  }

  void _navigateToIngredients(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const IngredientPage(),
      ),
    );
  }

  IconData _getDayTypeIcon(String dayType) {
    switch (dayType) {
      case 'chest':
        return Icons.fitness_center;
      case 'back':
        return Icons.rowing;
      case 'leg':
        return Icons.directions_run;
      case 'shoulder':
        return Icons.accessibility_new;
      case 'cardio':
        return Icons.favorite;
      case 'rest':
        return Icons.hotel;
      default:
        return Icons.fitness_center;
    }
  }
}
