import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/constants/workout_constants.dart';
import '../../core/supabase/supabase_config.dart';
import '../../core/utils/date_type_resolver.dart';

class PublicViewPage extends StatefulWidget {
  const PublicViewPage({super.key});

  @override
  State<PublicViewPage> createState() => _PublicViewPageState();
}

class _PublicViewPageState extends State<PublicViewPage> {
  bool _loading = true;
  String? _error;

  DateTime _focusedMonth = _monthStart(DateTime.now());
  DateTime _selectedDay = _dateOnly(DateTime.now());

  Set<DateTime> _checkinDays = <DateTime>{};
  List<_WeightPoint> _weightPoints = <_WeightPoint>[];
  List<_MealCardData> _todayMeals = <_MealCardData>[];
  _WorkoutCardData? _todayWorkout;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final today = _dateOnly(DateTime.now());
    final currentMonth = _monthStart(_focusedMonth);

    try {
      final results = await Future.wait<dynamic>([
        _fetchMonthCheckins(currentMonth),
        _fetchWeightTrend(today, days: 14),
        _fetchTodayMeals(today),
        _fetchTodayWorkout(today),
      ]);

      if (!mounted) return;

      setState(() {
        _checkinDays = results[0] as Set<DateTime>;
        _weightPoints = results[1] as List<_WeightPoint>;
        _todayMeals = results[2] as List<_MealCardData>;
        _todayWorkout = results[3] as _WorkoutCardData?;
        _selectedDay = today;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<Set<DateTime>> _fetchMonthCheckins(DateTime month) async {
    final start = _monthStart(month);
    final end = _monthEnd(month);
    final startStr = _formatDate(start);
    final endStr = _formatDate(end);

    final results = await Future.wait<dynamic>([
      SupabaseConfig.client
          .from('daily_meal_records')
          .select('record_date')
          .gte('record_date', startStr)
          .lte('record_date', endStr),
      SupabaseConfig.client
          .from('workout_records')
          .select('record_date')
          .gte('record_date', startStr)
          .lte('record_date', endStr),
    ]);

    final days = <DateTime>{};
    for (final row in _rows(results[0])) {
      final day = _parseDate(row['record_date']);
      if (day != null) days.add(day);
    }
    for (final row in _rows(results[1])) {
      final day = _parseDate(row['record_date']);
      if (day != null) days.add(day);
    }

    return days;
  }

  Future<List<_WeightPoint>> _fetchWeightTrend(DateTime today,
      {int days = 14}) async {
    final start = today.subtract(Duration(days: days - 1));
    final startStr = _formatDate(start);
    final endStr = _formatDate(today);

    final raw = await SupabaseConfig.client
        .from('weight_records')
        .select('record_date, time_of_day, weight, updated_at')
        .gte('record_date', startStr)
        .lte('record_date', endStr)
        .order('record_date', ascending: true)
        .order('updated_at', ascending: true);

    final grouped = <String, Map<String, dynamic>>{};
    for (final row in _rows(raw)) {
      final date = row['record_date'] as String?;
      if (date == null) continue;

      final existing = grouped[date];
      if (existing == null) {
        grouped[date] = row;
        continue;
      }

      final existingTimeOfDay = (existing['time_of_day'] as String?) ?? '';
      final newTimeOfDay = (row['time_of_day'] as String?) ?? '';

      if (existingTimeOfDay != 'evening' && newTimeOfDay == 'evening') {
        grouped[date] = row;
      } else {
        final existingUpdatedAt = existing['updated_at'] as String?;
        final newUpdatedAt = row['updated_at'] as String?;
        if ((newUpdatedAt ?? '').compareTo(existingUpdatedAt ?? '') >= 0) {
          grouped[date] = row;
        }
      }
    }

    final points = grouped.entries
        .map((entry) {
          final day = _parseDate(entry.key);
          final weight = _toDouble(entry.value['weight']);
          if (day == null || weight == null) return null;
          return _WeightPoint(date: day, weight: weight);
        })
        .whereType<_WeightPoint>()
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return points;
  }

  Future<List<_MealCardData>> _fetchTodayMeals(DateTime today) async {
    final todayStr = _formatDate(today);

    final mealRaw = await SupabaseConfig.client
        .from('daily_meal_records')
        .select(
            'id, meal_order, meal_time, meal_status, actual_carb, actual_protein, actual_fat, is_pre_workout, is_post_workout, photo_url, notes')
        .eq('record_date', todayStr)
        .order('meal_order', ascending: true);

    final meals = _rows(mealRaw);
    if (meals.isEmpty) return <_MealCardData>[];

    final mealIds = meals.map((e) => e['id'] as String).toList();

    final itemRaw = await SupabaseConfig.client
        .from('meal_item_records')
        .select('daily_meal_record_id, name, amount, carb, protein, fat')
        .inFilter('daily_meal_record_id', mealIds)
        .order('created_at', ascending: true);

    final itemRows = _rows(itemRaw);
    final itemsByMeal = <String, List<_MealItemData>>{};
    for (final row in itemRows) {
      final mealId = row['daily_meal_record_id'] as String?;
      if (mealId == null) continue;
      itemsByMeal.putIfAbsent(mealId, () => <_MealItemData>[]).add(
            _MealItemData(
              name: (row['name'] as String?) ?? '未命名食材',
              amount: _toDouble(row['amount']) ?? 0,
              carb: _toDouble(row['carb']) ?? 0,
              protein: _toDouble(row['protein']) ?? 0,
              fat: _toDouble(row['fat']) ?? 0,
            ),
          );
    }

    final parsedMeals = meals.map((row) {
      final mealId = row['id'] as String;
      return _MealCardData(
        id: mealId,
        mealOrder: _toInt(row['meal_order']) ?? 0,
        mealTime: (row['meal_time'] as String?) ?? '',
        mealStatus: (row['meal_status'] as String?) ?? 'pending',
        actualCarb: _toDouble(row['actual_carb']) ?? 0,
        actualProtein: _toDouble(row['actual_protein']) ?? 0,
        actualFat: _toDouble(row['actual_fat']) ?? 0,
        isPreWorkout: _toBool(row['is_pre_workout']),
        isPostWorkout: _toBool(row['is_post_workout']),
        photoUrl: row['photo_url'] as String?,
        notes: row['notes'] as String?,
        items: itemsByMeal[mealId] ?? <_MealItemData>[],
      );
    }).toList();

    return parsedMeals;
  }

  Future<_WorkoutCardData?> _fetchTodayWorkout(DateTime today) async {
    final todayStr = _formatDate(today);

    final raw = await SupabaseConfig.client
        .from('workout_records')
        .select(
            'day_type, is_completed, has_cardio, notes, photo_url, exercises')
        .eq('record_date', todayStr)
        .order('updated_at', ascending: false)
        .limit(1);

    final rows = _rows(raw);
    if (rows.isEmpty) return null;

    final row = rows.first;
    return _WorkoutCardData(
      dayType: (row['day_type'] as String?) ?? 'rest',
      isCompleted: _toBool(row['is_completed']),
      hasCardio: _toBool(row['has_cardio']),
      notes: row['notes'] as String?,
      photoUrl: row['photo_url'] as String?,
      exercises: _parseExercises(row['exercises']),
    );
  }

  Future<void> _onMonthChanged(DateTime focusedDay) async {
    final month = _monthStart(focusedDay);
    setState(() {
      _focusedMonth = month;
    });

    try {
      final days = await _fetchMonthCheckins(month);
      if (!mounted) return;
      setState(() {
        _checkinDays = days;
      });
    } catch (_) {
      // 月份切换的拉取失败不打断当前页面
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('100天蜕变专属仪表盘'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadDashboard,
            icon: const Icon(Icons.refresh_rounded),
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('云端数据加载失败'),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadDashboard,
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _buildSectionTitle(
            title: '100天打卡热力图',
            subtitle: '有饮食或训练记录的日期会显示绿色打卡点',
          ),
          const SizedBox(height: 10),
          _buildCalendarCard(),
          const SizedBox(height: 20),
          _buildSectionTitle(
            title: '体重趋势图',
            subtitle: '最近14天趋势（优先取晚间记录）',
          ),
          const SizedBox(height: 10),
          _buildWeightChartCard(),
          const SizedBox(height: 20),
          _buildSectionTitle(
            title: '今日餐食流',
            subtitle: '点击卡片展开食材明细与营养素',
          ),
          const SizedBox(height: 10),
          ..._buildTodayMealCards(),
          const SizedBox(height: 20),
          _buildSectionTitle(
            title: '今日训练打卡',
            subtitle: '展示训练内容与完成状态',
          ),
          const SizedBox(height: 10),
          _buildWorkoutCard(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: TableCalendar<dynamic>(
          firstDay: DateTime.now().subtract(const Duration(days: 365)),
          lastDay: DateTime.now().add(const Duration(days: 30)),
          focusedDay: _focusedMonth,
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const {CalendarFormat.month: '月'},
          selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
          eventLoader: (day) {
            return _checkinDays.contains(_dateOnly(day)) ? const [1] : const [];
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = _dateOnly(selectedDay);
              _focusedMonth = _monthStart(focusedDay);
            });
          },
          onPageChanged: _onMonthChanged,
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          calendarStyle: CalendarStyle(
            outsideTextStyle: TextStyle(color: Colors.grey.shade400),
            markerDecoration: const BoxDecoration(
              color: Color(0xFF22C55E),
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: Color(0xFF2563EB),
              shape: BoxShape.circle,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              if (events.isEmpty) return const SizedBox.shrink();
              return Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWeightChartCard() {
    if (_weightPoints.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('最近14天暂无体重数据'),
        ),
      );
    }

    final spots = <FlSpot>[];
    double minWeight = _weightPoints.first.weight;
    double maxWeight = _weightPoints.first.weight;

    for (int i = 0; i < _weightPoints.length; i++) {
      final weight = _weightPoints[i].weight;
      spots.add(FlSpot(i.toDouble(), weight));
      if (weight < minWeight) minWeight = weight;
      if (weight > maxWeight) maxWeight = weight;
    }

    final yPadding = (maxWeight - minWeight).abs() < 1 ? 0.8 : 0.5;
    final chartMinY = minWeight - yPadding;
    final chartMaxY = maxWeight + yPadding;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          children: [
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: chartMinY,
                  maxY: chartMaxY,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots
                          .map(
                            (spot) => LineTooltipItem(
                              '${spot.y.toStringAsFixed(1)} kg',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        getTitlesWidget: (value, meta) => Text(
                          value.toStringAsFixed(1),
                          style:
                              const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: _weightPoints.length > 1
                            ? ((_weightPoints.length - 1) / 2)
                                .clamp(1, 100)
                                .toDouble()
                            : 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.round();
                          if (index < 0 || index >= _weightPoints.length) {
                            return const SizedBox.shrink();
                          }
                          final date = _weightPoints[index].date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              DateFormat('M/d').format(date),
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.32,
                      barWidth: 3,
                      color: const Color(0xFF10B981),
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF10B981).withOpacity(0.35),
                            const Color(0xFF10B981).withOpacity(0.04),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '最近: ${_weightPoints.last.weight.toStringAsFixed(1)} kg',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '样本: ${_weightPoints.length} 天',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTodayMealCards() {
    if (_todayMeals.isEmpty) {
      return const [
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('今日暂无餐食记录'),
          ),
        ),
      ];
    }

    return _todayMeals.map(_buildMealCard).toList();
  }

  Widget _buildMealCard(_MealCardData meal) {
    final status = _mealStatusText(meal.mealStatus);
    final statusColor = _mealStatusColor(meal.mealStatus);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((meal.photoUrl ?? '').isNotEmpty)
            SizedBox(
              width: double.infinity,
              height: 170,
              child: Image.network(
                meal.photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  alignment: Alignment.center,
                  child: const Text('图片加载失败'),
                ),
              ),
            ),
          ExpansionTile(
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    _mealTitle(meal),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _macroChip('碳水', meal.actualCarb, const Color(0xFFF59E0B)),
                  _macroChip('蛋白', meal.actualProtein, const Color(0xFFEF4444)),
                  _macroChip('脂肪', meal.actualFat, const Color(0xFF3B82F6)),
                ],
              ),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            children: [
              if ((meal.notes ?? '').trim().isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    meal.notes!.trim(),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              if (meal.items.isEmpty)
                Text(
                  '暂无食材明细',
                  style: TextStyle(color: Colors.grey.shade600),
                )
              else
                Column(
                  children: meal.items.map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.amount.toStringAsFixed(0)}g',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${item.carb.toStringAsFixed(0)}C / ${item.protein.toStringAsFixed(0)}P / ${item.fat.toStringAsFixed(0)}F',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macroChip(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label ${value.toStringAsFixed(0)}g',
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildWorkoutCard() {
    final workout = _todayWorkout;
    if (workout == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('今日暂无训练记录'),
        ),
      );
    }

    final dayName = DateTypeResolver.getDayTypeName(workout.dayType);
    final dayColor =
        Color(WorkoutConstants.DAY_TYPE_COLORS[workout.dayType] ?? 0xFF6B7280);
    final completedCount = workout.exercises.where((e) => e.isCompleted).length;
    final totalCount = workout.exercises.length;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: dayColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    dayName,
                    style:
                        TextStyle(color: dayColor, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (workout.isCompleted ? Colors.green : Colors.orange)
                        .withOpacity(0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    workout.isCompleted ? '已完成' : '进行中',
                    style: TextStyle(
                      color: workout.isCompleted ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (workout.hasCardio) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.pink.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      '有氧',
                      style: TextStyle(
                          color: Colors.pink, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '动作完成: $completedCount / $totalCount',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if ((workout.photoUrl ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  workout.photoUrl!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 150,
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Text('训练图片加载失败'),
                  ),
                ),
              ),
            ],
            if (workout.exercises.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...workout.exercises.map(
                (e) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    e.isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked,
                    color: e.isCompleted ? Colors.green : Colors.grey,
                    size: 20,
                  ),
                  title: Text(e.name),
                  subtitle: _exerciseSubTitle(e),
                ),
              ),
            ],
            if ((workout.notes ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                workout.notes!.trim(),
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget? _exerciseSubTitle(_WorkoutExerciseData e) {
    final parts = <String>[];
    if (e.sets != null) parts.add('${e.sets}组');
    if ((e.reps ?? '').trim().isNotEmpty) parts.add('${e.reps}次');
    if (e.weight != null) parts.add('${e.weight!.toStringAsFixed(1)}kg');
    if (e.duration != null) parts.add('${e.duration}min');
    if (parts.isEmpty) return null;
    return Text(parts.join(' · '));
  }

  String _mealTitle(_MealCardData meal) {
    if (meal.isPreWorkout) return '练前餐 ${meal.mealTime}';
    if (meal.isPostWorkout) return '练后餐 ${meal.mealTime}';
    return '第${meal.mealOrder}餐 ${meal.mealTime}';
  }

  String _mealStatusText(String status) {
    switch (status) {
      case 'completed':
        return '已完成';
      case 'skipped':
        return '已跳过';
      default:
        return '待记录';
    }
  }

  Color _mealStatusColor(String status) {
    switch (status) {
      case 'completed':
        return const Color(0xFF16A34A);
      case 'skipped':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  List<Map<String, dynamic>> _rows(dynamic raw) {
    if (raw is! List) return <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  List<_WorkoutExerciseData> _parseExercises(dynamic raw) {
    if (raw == null) return <_WorkoutExerciseData>[];

    List<dynamic> data;
    if (raw is List) {
      data = raw;
    } else if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          data = decoded;
        } else {
          return <_WorkoutExerciseData>[];
        }
      } catch (_) {
        return <_WorkoutExerciseData>[];
      }
    } else {
      return <_WorkoutExerciseData>[];
    }

    return data.whereType<Map>().map((e) {
      final map = Map<String, dynamic>.from(e);
      return _WorkoutExerciseData(
        name: (map['name'] as String?) ?? '未命名动作',
        isCompleted: _toBool(map['isCompleted']),
        sets: _toInt(map['sets']),
        reps: map['reps'] as String?,
        weight: _toDouble(map['weight']),
        duration: _toInt(map['duration']),
      );
    }).toList();
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    try {
      return _dateOnly(DateTime.parse(value));
    } catch (_) {
      return null;
    }
  }

  static DateTime _monthStart(DateTime day) => DateTime(day.year, day.month, 1);

  static DateTime _monthEnd(DateTime day) =>
      DateTime(day.year, day.month + 1, 0);

  static DateTime _dateOnly(DateTime day) =>
      DateTime(day.year, day.month, day.day);

  static String _formatDate(DateTime day) =>
      DateFormat('yyyy-MM-dd').format(day);

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class _WeightPoint {
  final DateTime date;
  final double weight;

  const _WeightPoint({required this.date, required this.weight});
}

class _MealCardData {
  final String id;
  final int mealOrder;
  final String mealTime;
  final String mealStatus;
  final double actualCarb;
  final double actualProtein;
  final double actualFat;
  final bool isPreWorkout;
  final bool isPostWorkout;
  final String? photoUrl;
  final String? notes;
  final List<_MealItemData> items;

  const _MealCardData({
    required this.id,
    required this.mealOrder,
    required this.mealTime,
    required this.mealStatus,
    required this.actualCarb,
    required this.actualProtein,
    required this.actualFat,
    required this.isPreWorkout,
    required this.isPostWorkout,
    required this.photoUrl,
    required this.notes,
    required this.items,
  });
}

class _MealItemData {
  final String name;
  final double amount;
  final double carb;
  final double protein;
  final double fat;

  const _MealItemData({
    required this.name,
    required this.amount,
    required this.carb,
    required this.protein,
    required this.fat,
  });
}

class _WorkoutCardData {
  final String dayType;
  final bool isCompleted;
  final bool hasCardio;
  final String? notes;
  final String? photoUrl;
  final List<_WorkoutExerciseData> exercises;

  const _WorkoutCardData({
    required this.dayType,
    required this.isCompleted,
    required this.hasCardio,
    required this.notes,
    required this.photoUrl,
    required this.exercises,
  });
}

class _WorkoutExerciseData {
  final String name;
  final bool isCompleted;
  final int? sets;
  final String? reps;
  final double? weight;
  final int? duration;

  const _WorkoutExerciseData({
    required this.name,
    required this.isCompleted,
    required this.sets,
    required this.reps,
    required this.weight,
    required this.duration,
  });
}
