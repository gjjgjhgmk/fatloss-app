import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/utils/nutrition_calculator.dart';
import '../../core/utils/date_type_resolver.dart';
import '../../domain/usecases/daily_diet_manager.dart';
import '../providers/diet_provider.dart';
import 'meal_record_page.dart';
import 'review_page.dart';
import 'weight_record_page.dart';
import 'waist_record_page.dart';
import 'ingredient_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
      appBar: AppBar(
        title: const Text('碳循环减脂'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.restaurant_menu),
            onPressed: () => _navigateToIngredients(context),
            tooltip: '食材库',
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => _navigateToReview(context),
            tooltip: '复盘',
          ),
        ],
      ),
      body: Consumer<DietProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
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
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateHeader(context, provider, status),
                  const SizedBox(height: 16),
                  _buildQuickActions(context),
                  const SizedBox(height: 16),
                  _buildNutritionProgress(status),
                  const SizedBox(height: 16),
                  _buildMealList(context, provider, status),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateHeader(BuildContext context, DietProvider provider, DailyDietStatus status) {
    final dateFormat = DateFormat('M月d日 E');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateFormat.format(provider.selectedDate),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => _selectDate(context, provider),
                    child: const Text('选择日期'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_calendar),
                    onPressed: () => _showDayTypeSettings(context, provider),
                    tooltip: '设置训练日/有氧',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  status.dayTypeName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              if (DateTypeResolver.isCardioDay(provider.selectedDate)) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    '空腹有氧',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildQuickActionButton(
          context,
          Icons.monitor_weight,
          '体重打卡',
          Colors.blue,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WeightRecordPage()),
          ),
        ),
        _buildQuickActionButton(
          context,
          Icons.straighten,
          '腰围记录',
          Colors.purple,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WaistRecordPage()),
          ),
        ),
        _buildQuickActionButton(
          context,
          Icons.restaurant,
          '食材库',
          Colors.green,
          () => _navigateToIngredients(context),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionProgress(DailyDietStatus status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '营养素进度',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildProgressRow(
          '碳水',
          status.totalActual.carb,
          status.plannedCarb,
          status.carbProgress,
          NutritionCalculator.getComplianceColor(status.complianceStatus['carb']!),
        ),
        const SizedBox(height: 12),
        _buildProgressRow(
          '蛋白质',
          status.totalActual.protein,
          status.plannedProtein,
          status.proteinProgress,
          NutritionCalculator.getComplianceColor(status.complianceStatus['protein']!),
        ),
        const SizedBox(height: 12),
        _buildProgressRow(
          '脂肪',
          status.totalActual.fat,
          status.plannedFat,
          status.fatProgress,
          NutritionCalculator.getComplianceColor(status.complianceStatus['fat']!),
        ),
      ],
    );
  }

  Widget _buildProgressRow(String label, double actual, double planned, double progress, int color) {
    final percentage = (progress * 100).clamp(0, 200).toInt();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16)),
            Text(
              '${actual.toStringAsFixed(0)}/${planned.toStringAsFixed(0)}g  $percentage%',
              style: TextStyle(fontSize: 14, color: Color(color)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Color(color)),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildMealList(BuildContext context, DietProvider provider, DailyDietStatus status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '今日餐次 (${status.completedMeals}/${status.totalMeals})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (status.skippedMeals > 0)
              Text(
                '已跳过${status.skippedMeals}餐',
                style: const TextStyle(color: Colors.orange),
              ),
          ],
        ),
        const SizedBox(height: 16),
        ...status.meals.map((meal) => _buildMealCard(context, provider, meal)),
      ],
    );
  }

  Widget _buildMealCard(BuildContext context, DietProvider provider, meal) {
    IconData statusIcon;
    Color statusColor;
    String statusText;

    if (meal.isSkipped) {
      statusIcon = Icons.remove_circle_outline;
      statusColor = Colors.grey;
      statusText = '已跳过';
    } else if (meal.isCompleted) {
      statusIcon = Icons.check_circle;
      statusColor = Colors.green;
      statusText = '已完成';
    } else {
      statusIcon = Icons.pending;
      statusColor = Colors.grey;
      statusText = '待记录';
    }

    String mealLabel = '第${meal.mealOrder}餐 ${meal.mealTime}';
    if (meal.isPreWorkout) mealLabel = '练前餐 ${meal.mealTime}';
    if (meal.isPostWorkout) mealLabel = '练后餐 ${meal.mealTime}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: meal.isSkipped ? null : () => _navigateToMealRecord(context, meal.mealOrder),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        mealLabel,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (meal.hasPhoto) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.photo_camera, size: 16, color: Colors.green),
                      ],
                    ],
                  ),
                  Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildNutrientChip('碳水', meal.actualCarb, meal.plannedCarb),
                  const SizedBox(width: 8),
                  _buildNutrientChip('蛋白', meal.actualProtein, meal.plannedProtein),
                  const SizedBox(width: 8),
                  _buildNutrientChip('脂肪', meal.actualFat, meal.plannedFat),
                ],
              ),
              if (!meal.isSkipped && !meal.isCompleted) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _showSkipDialog(context, provider, meal.mealOrder),
                      child: const Text('跳过'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _navigateToMealRecord(context, meal.mealOrder),
                      child: const Text('记录'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutrientChip(String label, double actual, double planned) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: ${actual.toStringAsFixed(0)}/${planned.toStringAsFixed(0)}g',
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, DietProvider provider) async {
    final date = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      await provider.selectDate(date);
    }
  }

  void _showDayTypeSettings(BuildContext context, DietProvider provider) {
    final selectedDate = provider.selectedDate;
    final isCardio = DateTypeResolver.isCardioDay(selectedDate);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置训练日'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('空腹有氧'),
              subtitle: const Text('标记今天为空腹有氧日'),
              value: isCardio,
              onChanged: (value) {
                DateTypeResolver.setCardioDay(selectedDate, value);
                provider.loadDailyStatus();
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
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

  void _showSkipDialog(BuildContext context, DietProvider provider, int mealOrder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('跳过餐次'),
        content: const Text('确定要跳过这一餐吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.skipMeal(mealOrder);
              Navigator.pop(context);
            },
            child: const Text('确定跳过'),
          ),
        ],
      ),
    );
  }
}
