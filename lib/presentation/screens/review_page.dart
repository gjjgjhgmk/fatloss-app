import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/utils/nutrition_calculator.dart';
import '../../domain/usecases/diet_review_generator.dart';
import '../providers/review_provider.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ReviewProvider>();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      provider.loadDailyReview(today);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('饮食复盘'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '今日复盘'),
            Tab(text: '周复盘'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDailyReview(),
          _buildWeeklyReview(),
        ],
      ),
    );
  }

  Widget _buildDailyReview() {
    return Consumer<ReviewProvider>(
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
                  onPressed: () {
                    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
                    provider.loadDailyReview(today);
                  },
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }

        final review = provider.dailyReview;
        if (review == null) {
          return const Center(child: Text('暂无复盘数据'));
        }

        // 更新备注控制器
        _notesController.text = review.userNotes ?? '';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDailySummary(review),
              const SizedBox(height: 24),
              _buildComplianceStatus(review),
              const SizedBox(height: 24),
              if (review.warnings.isNotEmpty) ...[
                _buildWarnings(review.warnings),
                const SizedBox(height: 24),
              ],
              _buildMealDetails(review),
              const SizedBox(height: 24),
              _buildNotesSection(review),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDailySummary(review) {
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
            review.recordDate,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                '碳水',
                review.totalActual.carb.toStringAsFixed(0),
                review.totalPlanned.carb.toStringAsFixed(0),
                'g',
              ),
              _buildSummaryItem(
                '蛋白质',
                review.totalActual.protein.toStringAsFixed(0),
                review.totalPlanned.protein.toStringAsFixed(0),
                'g',
              ),
              _buildSummaryItem(
                '脂肪',
                review.totalActual.fat.toStringAsFixed(0),
                review.totalPlanned.fat.toStringAsFixed(0),
                'g',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String actual, String planned, String unit) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          '$actual/$planned$unit',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildComplianceStatus(review) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '达标情况',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildComplianceCard(
                '碳水',
                review.complianceStatus['carb']!,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildComplianceCard(
                '蛋白质',
                review.complianceStatus['protein']!,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildComplianceCard(
                '脂肪',
                review.complianceStatus['fat']!,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComplianceCard(String label, ComplianceStatus status) {
    final color = NutritionCalculator.getComplianceColor(status);
    final text = NutritionCalculator.getComplianceText(status);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(color).withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(color)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            text,
            style: TextStyle(
              color: Color(color),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarnings(List<String> warnings) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text(
                '注意事项',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...warnings.map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $w'),
              )),
        ],
      ),
    );
  }

  Widget _buildMealDetails(review) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '餐次详情',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...review.mealSummaries.map<Widget>((meal) => _buildMealDetailCard(meal)),
      ],
    );
  }

  Widget _buildMealDetailCard(MealSummary meal) {
    IconData icon;
    Color color;

    if (meal.status == 'skipped') {
      icon = Icons.remove_circle_outline;
      color = Colors.grey;
    } else if (meal.status == 'completed') {
      icon = Icons.check_circle;
      color = Colors.green;
    } else {
      icon = Icons.pending;
      color = Colors.grey;
    }

    String mealLabel = '第${meal.mealOrder}餐 ${meal.mealTime}';
    if (meal.isPostWorkout) mealLabel = '练后餐 ${meal.mealTime}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(mealLabel),
        subtitle: Text(
          '碳水: ${meal.actual.carb.toStringAsFixed(0)}/${meal.planned.carb.toStringAsFixed(0)}g  '
          '蛋白: ${meal.actual.protein.toStringAsFixed(0)}/${meal.planned.protein.toStringAsFixed(0)}g  '
          '脂肪: ${meal.actual.fat.toStringAsFixed(0)}/${meal.planned.fat.toStringAsFixed(0)}g',
        ),
        trailing: meal.isPostWorkout
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('练后', style: TextStyle(fontSize: 12)),
              )
            : null,
      ),
    );
  }

  Widget _buildNotesSection(review) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '复盘备注',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _notesController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: '添加复盘备注...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: () {
              final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
              context.read<ReviewProvider>().saveReviewNotes(
                    today,
                    _notesController.text,
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('备注已保存')),
              );
            },
            child: const Text('保存备注'),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyReview() {
    return Consumer<ReviewProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final weekly = provider.weeklyReview;
        if (weekly == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('暂无周复盘数据'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final weekStart = DateTime.now().subtract(const Duration(days: 6));
                    provider.loadWeeklyReview(weekStart);
                  },
                  child: const Text('加载本周复盘'),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '${weekly['weekStart']} ~ ${weekly['weekEnd']}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildWeeklyItem(
                          '平均碳水',
                          '${(weekly['avgCarb'] as double).toStringAsFixed(0)}g',
                        ),
                        _buildWeeklyItem(
                          '平均蛋白',
                          '${(weekly['avgProtein'] as double).toStringAsFixed(0)}g',
                        ),
                        _buildWeeklyItem(
                          '平均脂肪',
                          '${(weekly['avgFat'] as double).toStringAsFixed(0)}g',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard(
                    '完成餐次',
                    '${weekly['completedMeals']}/${weekly['totalMeals']}',
                    Icons.restaurant,
                  ),
                  _buildStatCard(
                    '完成率',
                    '${(weekly['complianceRate'] as double).toStringAsFixed(0)}%',
                    Icons.check_circle,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeeklyItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
