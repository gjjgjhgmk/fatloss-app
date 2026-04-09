import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/supabase/supabase_config.dart';
import '../../core/utils/date_type_resolver.dart';
import '../../core/constants/workout_constants.dart';

class PublicViewPage extends StatefulWidget {
  const PublicViewPage({super.key});

  @override
  State<PublicViewPage> createState() => _PublicViewPageState();
}

class _PublicViewPageState extends State<PublicViewPage> {
  Map<String, dynamic>? _overview;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final today = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(today);
      final fallbackDayType = DateTypeResolver.resolveDayType(today);
      bool isCardio = DateTypeResolver.isCardioDay(today);

      // 并发请求多个表来组装数据
      final results = await Future.wait([
        SupabaseConfig.client
            .from('daily_meal_records')
            .select()
            .eq('record_date', todayStr),
        SupabaseConfig.client
            .from('weight_records')
            .select()
            .order('record_date', ascending: false)
            .limit(1),
        SupabaseConfig.client
            .from('waist_records')
            .select()
            .order('record_date', ascending: false)
            .limit(1),
        SupabaseConfig.client
            .from('workout_records')
            .select()
            .eq('record_date', todayStr)
            .limit(1),
      ]);

      final mealRecords = results[0] as List<dynamic>;
      final weightRecords = results[1] as List<dynamic>;
      final waistRecords = results[2] as List<dynamic>;
      final workoutRecords = results[3] as List<dynamic>;

      String dayType = fallbackDayType;
      if (workoutRecords.isNotEmpty) {
        dayType = workoutRecords.first['day_type'] as String? ?? fallbackDayType;
      } else if (mealRecords.isNotEmpty) {
        dayType = mealRecords.first['day_type'] as String? ?? fallbackDayType;
      }

      // 计算营养素总计
      double totalCarb = 0, totalProtein = 0, totalFat = 0;
      int completedMeals = 0;

      for (final record in mealRecords) {
        totalCarb += (record['actual_carb'] as num?)?.toDouble() ?? 0;
        totalProtein += (record['actual_protein'] as num?)?.toDouble() ?? 0;
        totalFat += (record['actual_fat'] as num?)?.toDouble() ?? 0;
        if (record['meal_status'] == 'completed') completedMeals++;
      }

      // 计算训练完成情况
      int completedExercises = 0;
      int totalExercises = 0;
      bool cardioCompleted = false;

      if (workoutRecords.isNotEmpty) {
        final workout = workoutRecords.first;
        isCardio = workout['has_cardio'] == true || workout['has_cardio'] == 1 || isCardio;
        final exercises = workout['exercises'] as List? ?? [];
        totalExercises = exercises.length;
        for (final ex in exercises) {
          if (ex['isCompleted'] == true) {
            completedExercises++;
            if (ex['name'] == '60min 爬坡') {
              cardioCompleted = true;
            }
          }
        }
      }

      final latestWeight = weightRecords.isNotEmpty
          ? (weightRecords.first['weight'] as num?)?.toDouble()
          : null;
      final latestWaist = waistRecords.isNotEmpty
          ? (waistRecords.first['waist'] as num?)?.toDouble()
          : null;

      setState(() {
        _overview = {
          'date': todayStr,
          'dayType': dayType,
          'isCardio': isCardio,
          'totalCarb': totalCarb,
          'totalProtein': totalProtein,
          'totalFat': totalFat,
          'completedMeals': completedMeals,
          'totalMeals': mealRecords.length,
          'latestWeight': latestWeight,
          'latestWaist': latestWaist,
          'records': mealRecords,
          'completedExercises': completedExercises,
          'totalExercises': totalExercises,
          'cardioCompleted': cardioCompleted,
        };
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('碳循环减脂'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: '刷新',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('加载失败', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_overview == null) {
      return const Center(child: Text('暂无数据'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateHeader(),
            const SizedBox(height: 16),
            _buildStatsCards(),
            const SizedBox(height: 16),
            _buildWorkoutSummary(),
            const SizedBox(height: 16),
            _buildMealList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader() {
    final dateStr = _overview!['date'] as String?;
    final dateFormat = DateFormat('M月d日 E');
    DateTime date;
    try {
      date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
    } catch (_) {
      date = DateTime.now();
    }
    final dayType = _overview!['dayType'] as String? ?? 'rest';
    final isCardio = _overview!['isCardio'] as bool? ?? false;
    final dayColor = Color(WorkoutConstants.DAY_TYPE_COLORS[dayType] ?? 0xFF9E9E9E);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateFormat.format(date),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: dayColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  DateTypeResolver.getDayTypeName(dayType),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              if (isCardio) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.pink,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    '空腹有氧',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final totalCarb = _overview!['totalCarb'] as double;
    final totalProtein = _overview!['totalProtein'] as double;
    final totalFat = _overview!['totalFat'] as double;
    final latestWeight = _overview!['latestWeight'] as double?;
    final completedMeals = _overview!['completedMeals'] as int;
    final totalMeals = _overview!['totalMeals'] as int;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('已完成餐次', '$completedMeals/$totalMeals', Icons.restaurant, Colors.green)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('体重', latestWeight != null ? '${latestWeight.toStringAsFixed(1)}kg' : '--', Icons.monitor_weight, Colors.blue)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard('碳水摄入', '${totalCarb.toStringAsFixed(0)}g', Icons.grass, Colors.orange)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('蛋白质摄入', '${totalProtein.toStringAsFixed(0)}g', Icons.fitness_center, Colors.red)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('脂肪摄入', '${totalFat.toStringAsFixed(0)}g', Icons.water_drop, Colors.blue)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildMealList() {
    final records = _overview!['records'] as List;
    if (records.isEmpty) {
      return const Center(child: Text('今日暂无餐次记录'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '今日餐次',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...records.map((record) => _buildMealCard(record)),
      ],
    );
  }

  Widget _buildMealCard(Map<String, dynamic> record) {
    final mealOrder = (record['meal_order'] as num?)?.toInt() ?? 0;
    final mealTime = (record['meal_time'] as String?) ?? '';
    final actualCarb = (record['actual_carb'] as num?)?.toDouble() ?? 0;
    final actualProtein = (record['actual_protein'] as num?)?.toDouble() ?? 0;
    final actualFat = (record['actual_fat'] as num?)?.toDouble() ?? 0;
    final mealStatus = (record['meal_status'] as String?) ?? 'pending';
    final isPreWorkout = record['is_pre_workout'] == true || record['is_pre_workout'] == 1;
    final isPostWorkout = record['is_post_workout'] == true || record['is_post_workout'] == 1;

    String mealLabel = '第${mealOrder}餐 $mealTime';
    if (isPreWorkout) mealLabel = '练前餐 $mealTime';
    if (isPostWorkout) mealLabel = '练后餐 $mealTime';

    Color statusColor;
    IconData statusIcon;
    if (mealStatus == 'completed') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (mealStatus == 'skipped') {
      statusColor = Colors.grey;
      statusIcon = Icons.remove_circle_outline;
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.pending;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 18),
                const SizedBox(width: 8),
                Text(mealLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildMiniChip('碳水', actualCarb, Colors.orange),
                const SizedBox(width: 8),
                _buildMiniChip('蛋白', actualProtein, Colors.red),
                const SizedBox(width: 8),
                _buildMiniChip('脂肪', actualFat, Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniChip(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: ${value.toStringAsFixed(0)}g',
        style: TextStyle(fontSize: 12, color: color),
      ),
    );
  }

  Widget _buildWorkoutSummary() {
    final dayType = _overview!['dayType'] as String? ?? 'rest';
    final isCardio = _overview!['isCardio'] as bool? ?? false;
    final completedExercises = _overview!['completedExercises'] as int? ?? 0;
    final totalExercises = _overview!['totalExercises'] as int? ?? 0;
    final cardioCompleted = _overview!['cardioCompleted'] as bool? ?? false;

    // 如果是休息日且没有空腹有氧，不显示训练总结
    if (dayType == 'rest' && !isCardio) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '训练总结',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        // 力量训练总结
        if (dayType != 'rest') _buildPublicStrengthCard(dayType, completedExercises, totalExercises),
        if (dayType != 'rest' && isCardio) const SizedBox(height: 12),
        // 空腹有氧总结
        if (isCardio) _buildPublicCardioCard(cardioCompleted),
      ],
    );
  }

  Widget _buildPublicStrengthCard(String dayType, int completed, int total) {
    final dayColor = Color(WorkoutConstants.DAY_TYPE_COLORS[dayType] ?? 0xFF9E9E9E);
    final dayName = WorkoutConstants.DAY_TYPE_NAMES[dayType] ?? dayType;
    final progress = total > 0 ? completed / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dayColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dayColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fitness_center, color: dayColor, size: 20),
              const SizedBox(width: 8),
              Text(
                '力量训练 - $dayName',
                style: TextStyle(fontWeight: FontWeight.bold, color: dayColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$completed/$total 动作完成',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.grey[800],
                        valueColor: AlwaysStoppedAnimation<Color>(dayColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: dayColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPublicCardioCard(bool isCompleted) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.pink.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.pink.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.favorite_border,
            color: Colors.pink,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '空腹有氧 - 60min 爬坡',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink),
                ),
                Text(
                  isCompleted ? '已完成' : '未完成',
                  style: TextStyle(
                    fontSize: 12,
                    color: isCompleted ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          if (isCompleted)
            const Icon(Icons.check, color: Colors.green)
          else
            const Icon(Icons.close, color: Colors.grey),
        ],
      ),
    );
  }
}
