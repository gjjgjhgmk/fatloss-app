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

    // 冷启动先从云端拉取今日/最新数据，保证多端一致
    print('[初始化] 拉取云端数据...');
    await SyncService().pullTodayDataFromCloud();
    print('[初始化] 云端数据拉取完成');

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

  // 注册所有 adapter
  _registerAdapters();

  // 直接使用 HiveHelper 的 initialize，它会正确地打开所有 typed boxes
  try {
    await HiveHelper.instance.initialize();
    print('[Hive] HiveHelper 初始化成功');
  } catch (error) {
    print('[Hive] HiveHelper 初始化失败: $error');
    print('[Hive] 关闭所有 box 并重试...');

    try {
      // 先关闭所有已打开的 box
      await Hive.close();
      print('[Hive] 所有 box 已关闭');

      // 重新初始化
      await Hive.initFlutter();
      _registerAdapters();
      await HiveHelper.instance.initialize();
      print('[Hive] 重试初始化成功');
    } catch (retryError) {
      print('[Hive] 重试也失败: $retryError');
      rethrow;
    }
  }
}

void _registerAdapters() {
  // 所有 adapter 必须先注册才能打开 box
  final helper = HiveHelper.instance;
  helper.ensureAdapterRegistered();
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
                    style: TextStyle(color: Colors.red.shade300, fontSize: 12, fontFamily: 'monospace'),
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
          '/': (context) => const HomePage(requireAuth: true),
          // 围观页保持公开访问，不做密码拦截
          '/public': (context) => const PublicViewPage(),
        },
      ),
    );
  }
}
