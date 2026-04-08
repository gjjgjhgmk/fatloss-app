import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/database/hive_helper.dart';
import 'core/supabase/supabase_config.dart';
import 'core/supabase/sync_service.dart';
import 'presentation/providers/diet_provider.dart';
import 'presentation/providers/review_provider.dart';
import 'presentation/providers/workout_provider.dart';
import 'presentation/screens/home_page.dart';
import 'presentation/screens/public_view_page.dart';

void main() async {
  // 所有初始化代码都必须包裹在 try-catch 中
  try {
    WidgetsFlutterBinding.ensureInitialized();

    print('[初始化] 开始初始化...');

    // 初始化 Hive（包含数据迁移容错）
    print('[初始化] 初始化 Hive...');
    await _initializeHiveWithMigration();
    print('[初始化] Hive 初始化完成');

    // 初始化 Supabase
    print('[初始化] 初始化 Supabase...');
    await SupabaseConfig.initialize();
    print('[初始化] Supabase 初始化完成');

    print('[初始化] 启动应用...');
    runApp(const CarbonCycleDietApp());

    // 后台静默同步（Fire and Forget）
    SyncService().syncAllRecentData();

  } catch (error, stackTrace) {
    print('========================================');
    print('[FATAL ERROR] 应用初始化失败: $error');
    print('[FATAL ERROR] 堆栈: $stackTrace');
    print('========================================');

    // 显示错误界面
    runApp(ErrorApp(error: error.toString(), stackTrace: stackTrace.toString()));
  }
}

/// 带数据迁移容错的 Hive 初始化
Future<void> _initializeHiveWithMigration() async {
  await Hive.initFlutter();

  // 尝试注册所有 adapter
  _registerAdapters();

  // 尝试打开 boxes，如果失败则清除旧数据重试
  await _openBoxesWithMigration();

  // Seed initial data if empty
  await HiveHelper.instance.seedDataIfNeeded();
}

void _registerAdapters() {
  // 所有 adapter 必须先注册才能打开 box
  // 注意：如果 adapter 变化导致旧数据无法反序列化，openBox 会抛出异常
  final helper = HiveHelper.instance;
  // 触发 adapter 注册（如果还没注册的话）
  // 这些调用会确保 adapter 被注册
  try {
    helper.ensureAdapterRegistered();
  } catch (e) {
    print('[Hive] Adapter 注册异常: $e');
  }
}

Future<void> _openBoxesWithMigration() async {
  final boxNames = [
    HiveHelper.dietRulesBox,
    HiveHelper.mealTemplatesBox,
    HiveHelper.ingredientsBox,
    HiveHelper.dailyMealRecordsBox,
    HiveHelper.mealItemRecordsBox,
    HiveHelper.dailyReviewsBox,
    HiveHelper.weeklyReviewsBox,
    HiveHelper.weightRecordsBox,
    HiveHelper.waistRecordsBox,
    HiveHelper.workoutRecordsBox,
    HiveHelper.appSettingsBox,
  ];

  for (final boxName in boxNames) {
    try {
      // 尝试直接打开 box
      await Hive.openBox(boxName);
      print('[Hive] Box [$boxName] 打开成功');
    } catch (error) {
      print('[Hive] Box [$boxName] 打开失败: $error');
      print('[Hive] 尝试删除旧数据并重新创建...');

      try {
        // 删除损坏的 box
        await Hive.deleteBoxFromDisk(boxName);
        print('[Hive] Box [$boxName] 已删除');

        // 重新打开
        await Hive.openBox(boxName);
        print('[Hive] Box [$boxName] 重新创建成功');
      } catch (deleteError) {
        print('[Hive] 删除 Box [$boxName] 失败: $deleteError');
        // 继续尝试下一个 box
      }
    }
  }
}

class ErrorApp extends StatelessWidget {
  final String error;
  final String stackTrace;
  const ErrorApp({super.key, required this.error, this.stackTrace = ''});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF1A1F35),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 24),
                const Text(
                  '应用初始化失败',
                  style: TextStyle(color: Colors.red, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: SelectableText(
                    error,
                    style: const TextStyle(color: Colors.red[300], fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
                if (stackTrace.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        stackTrace,
                        style: const TextStyle(color: Colors.grey, fontSize: 10, fontFamily: 'monospace'),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                const Text(
                  '请将以上错误信息发给开发者',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // 清除所有 Hive 数据并重试
                    _resetAndRetry();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: const Text('清除数据并重试'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _resetAndRetry() async {
    try {
      await Hive.deleteFromDisk();
      print('[重置] Hive 数据已清除，正在重启...');
    } catch (e) {
      print('[重置] 清除失败: $e');
    }
  }
}

class CarbonCycleDietApp extends StatelessWidget {
  const CarbonCycleDietApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DietProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
      ],
      child: MaterialApp(
        title: '碳循环减脂',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF00D9FF),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const HomePage(),
          '/public': (context) => const PublicViewPage(),
        },
      ),
    );
  }
}
