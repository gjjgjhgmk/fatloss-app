import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/database/hive_helper.dart';
import 'core/supabase/supabase_config.dart';
import 'core/supabase/sync_service.dart';
import 'presentation/providers/diet_provider.dart';
import 'presentation/providers/review_provider.dart';
import 'presentation/providers/workout_provider.dart';
import 'presentation/screens/home_page.dart';
import 'presentation/screens/public_view_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Hive
  await HiveHelper.instance.initialize();

  // 初始化 Supabase
  await SupabaseConfig.initialize();

  runApp(const CarbonCycleDietApp());

  // 后台静默同步（Fire and Forget）
  SyncService().syncAllRecentData();
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
        // 编辑入口：默认打开应用
        initialRoute: '/',
        routes: {
          '/': (context) => const HomePage(),
          '/public': (context) => const PublicViewPage(),
        },
      ),
    );
  }
}
