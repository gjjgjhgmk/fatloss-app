import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/firebase/firestore_service.dart';
import '../../core/utils/date_type_resolver.dart';
import '../../data/models/daily_meal_record.dart';

class PublicViewPage extends StatefulWidget {
  const PublicViewPage({super.key});

  @override
  State<PublicViewPage> createState() => _PublicViewPageState();
}

class _PublicViewPageState extends State<PublicViewPage> {
  final FirestoreService _firestore = FirestoreService();
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
      await _firestore.initialize();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final data = await _firestore.getPublicTodayOverview(today);
      setState(() {
        _overview = data;
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
            _buildMealList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader() {
    final date = DateTime.parse(_overview!['date'] as String);
    final dateFormat = DateFormat('M月d日 E');
    final dayType = _overview!['records'].isNotEmpty
        ? (_overview!['records'] as List).first['dayType'] as String
        : 'rest';

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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              DateTypeResolver.getDayTypeName(dayType),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
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
    final mealOrder = record['mealOrder'] as int;
    final mealTime = record['mealTime'] as String;
    final actualCarb = (record['actualCarb'] as num).toDouble();
    final actualProtein = (record['actualProtein'] as num).toDouble();
    final actualFat = (record['actualFat'] as num).toDouble();
    final mealStatus = record['mealStatus'] as String;

    String mealLabel = '第${mealOrder}餐 $mealTime';
    if (record['isPreWorkout'] == true) mealLabel = '练前餐 $mealTime';
    if (record['isPostWorkout'] == true) mealLabel = '练后餐 $mealTime';

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
}
