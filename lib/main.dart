import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/database/hive_helper.dart';
import 'core/firebase/firebase_config.dart';
import 'presentation/providers/diet_provider.dart';
import 'presentation/providers/review_provider.dart';
import 'presentation/screens/home_page.dart';
import 'presentation/screens/public_view_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Hive
  await HiveHelper.instance.initialize();

  // 初始化 Firebase（仅在配置了 Firebase 时）
  if (FirebaseConfig.apiKey != 'YOUR_API_KEY') {
    // Firebase 初始化将在使用时延迟进行
  }

  runApp(const CarbonCycleDietApp());
}

class CarbonCycleDietApp extends StatelessWidget {
  const CarbonCycleDietApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DietProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
      ],
      child: MaterialApp(
        title: '碳循环减脂',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
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
