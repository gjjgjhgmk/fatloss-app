import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
  // 鎵€鏈夊垵濮嬪寲浠ｇ爜閮藉繀椤诲寘瑁瑰湪 try-catch 涓?  try {
    WidgetsFlutterBinding.ensureInitialized();

    print('[鍒濆鍖朷 寮€濮嬪垵濮嬪寲...');

    // 鍒濆鍖?Hive锛堝寘鍚暟鎹縼绉诲閿欙級
    print('[鍒濆鍖朷 鍒濆鍖?Hive...');
    await _initializeHiveWithMigration();
    print('[鍒濆鍖朷 Hive 鍒濆鍖栧畬鎴?);

    // 鍒濆鍖?Supabase
    print('[鍒濆鍖朷 鍒濆鍖?Supabase...');
    await SupabaseConfig.initialize();
    print('[鍒濆鍖朷 Supabase 鍒濆鍖栧畬鎴?);

    // 鍐峰惎鍔ㄥ厛浠庝簯绔媺鍙栦粖鏃?鏈€鏂版暟鎹紝淇濊瘉澶氱涓€鑷?    print('[鍒濆鍖朷 鎷夊彇浜戠鏁版嵁...');
    await SyncService().pullCloudDataToLocal();
    print('[鍒濆鍖朷 浜戠鏁版嵁鎷夊彇瀹屾垚');

    print('[鍒濆鍖朷 鍚姩搴旂敤...');
    runApp(const CarbonCycleDietApp());

    // 鍚庡彴闈欓粯鍚屾锛團ire and Forget锛?    SyncService().syncAllRecentData();
  } catch (error, stackTrace) {
    print('========================================');
    print('[FATAL ERROR] 搴旂敤鍒濆鍖栧け璐? $error');
    print('[FATAL ERROR] 鍫嗘爤: $stackTrace');
    print('========================================');

    // 鏄剧ず閿欒鐣岄潰
    runApp(
        ErrorApp(error: error.toString(), stackTrace: stackTrace.toString()));
  }
}

/// 甯︽暟鎹縼绉诲閿欑殑 Hive 鍒濆鍖?Future<void> _initializeHiveWithMigration() async {
  await Hive.initFlutter();

  // 娉ㄥ唽鎵€鏈?adapter
  _registerAdapters();

  // 鐩存帴浣跨敤 HiveHelper 鐨?initialize锛屽畠浼氭纭湴鎵撳紑鎵€鏈?typed boxes
  try {
    await HiveHelper.instance.initialize();
    print('[Hive] HiveHelper 鍒濆鍖栨垚鍔?);
  } catch (error) {
    print('[Hive] HiveHelper 鍒濆鍖栧け璐? $error');
    print('[Hive] 鍏抽棴鎵€鏈?box 骞堕噸璇?..');

    try {
      // 鍏堝叧闂墍鏈夊凡鎵撳紑鐨?box
      await Hive.close();
      print('[Hive] 鎵€鏈?box 宸插叧闂?);

      // 閲嶆柊鍒濆鍖?      await Hive.initFlutter();
      _registerAdapters();
      await HiveHelper.instance.initialize();
      print('[Hive] 閲嶈瘯鍒濆鍖栨垚鍔?);
    } catch (retryError) {
      print('[Hive] 閲嶈瘯涔熷け璐? $retryError');
      rethrow;
    }
  }
}

void _registerAdapters() {
  // 鎵€鏈?adapter 蹇呴』鍏堟敞鍐屾墠鑳芥墦寮€ box
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
                  '搴旂敤鍒濆鍖栧け璐?,
                  style: TextStyle(
                      color: Colors.red,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
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
                    style: TextStyle(
                        color: Colors.red.shade300,
                        fontSize: 12,
                        fontFamily: 'monospace'),
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
                        style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                            fontFamily: 'monospace'),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                const Text(
                  '璇峰皢浠ヤ笂閿欒淇℃伅鍙戠粰寮€鍙戣€?,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // 娓呴櫎鎵€鏈?Hive 鏁版嵁骞堕噸璇?                    _resetAndRetry();
                  },
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: const Text('娓呴櫎鏁版嵁骞堕噸璇?),
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
      print('[閲嶇疆] Hive 鏁版嵁宸叉竻闄わ紝姝ｅ湪閲嶅惎...');
    } catch (e) {
      print('[閲嶇疆] 娓呴櫎澶辫触: $e');
    }
  }
}

class CarbonCycleDietApp extends StatelessWidget {
  const CarbonCycleDietApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0EA5A6),
        brightness: Brightness.light,
      ),
    );
    final textTheme = GoogleFonts.poppinsTextTheme(baseTheme.textTheme).apply(
      bodyColor: const Color(0xFF111827),
      displayColor: const Color(0xFF111827),
    );
    final cardTheme = baseTheme.cardTheme.copyWith(
      color: Colors.white,
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: EdgeInsets.zero,
    );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const PublicViewPage(),
        ),
        GoRoute(
          path: '/muxi',
          builder: (context, state) => const HomePage(requireAuth: true),
        ),
      ],
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DietProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
      ],
      child: MaterialApp.router(
        title: '碳循环减脂',
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        theme: baseTheme.copyWith(
          scaffoldBackgroundColor: Colors.grey.shade50,
          textTheme: textTheme,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.grey.shade50,
            foregroundColor: const Color(0xFF111827),
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            titleTextStyle: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          cardTheme: cardTheme,
          dividerColor: Colors.grey.shade200,
        ),
      ),
    );
  }
}
