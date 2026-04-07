import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/database/hive_helper.dart';
import 'presentation/providers/diet_provider.dart';
import 'presentation/providers/review_provider.dart';
import 'presentation/screens/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Hive
  await HiveHelper.instance.initialize();

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
        home: const HomePage(),
      ),
    );
  }
}
