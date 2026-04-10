import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'core/database/hive_helper.dart';
import 'core/supabase/supabase_config.dart';
import 'core/supabase/sync_service.dart';
import 'presentation/providers/diet_provider.dart';
import 'presentation/providers/review_provider.dart';
import 'presentation/providers/workout_provider.dart';
import 'presentation/screens/home_page.dart';
import 'presentation/screens/public_view_page.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    print('[Init] App bootstrap started');

    print('[Init] Initializing Hive...');
    await _initializeHiveWithMigration();
    print('[Init] Hive initialized');

    print('[Init] Initializing Supabase...');
    await SupabaseConfig.initialize();
    print('[Init] Supabase initialized');

    print('[Init] Pulling latest cloud data...');
    await SyncService().pullCloudDataToLocal();
    print('[Init] Cloud data pull finished');

    runApp(const CarbonCycleDietApp());

    // Fire and forget background sync.
    SyncService().syncAllRecentData();
  } catch (error, stackTrace) {
    print('========================================');
    print('[FATAL ERROR] App initialization failed: $error');
    print('[FATAL ERROR] Stack trace: $stackTrace');
    print('========================================');

    runApp(
      ErrorApp(
        error: error.toString(),
        stackTrace: stackTrace.toString(),
      ),
    );
  }
}

Future<void> _initializeHiveWithMigration() async {
  await Hive.initFlutter();
  _registerAdapters();

  try {
    await HiveHelper.instance.initialize();
    print('[Hive] HiveHelper initialized');
  } catch (error) {
    print('[Hive] HiveHelper init failed: $error');
    print('[Hive] Closing all boxes and retrying...');

    try {
      await Hive.close();
      await Hive.initFlutter();
      _registerAdapters();
      await HiveHelper.instance.initialize();
      print('[Hive] Retry succeeded');
    } catch (retryError) {
      print('[Hive] Retry failed: $retryError');
      rethrow;
    }
  }
}

void _registerAdapters() {
  HiveHelper.instance.ensureAdapterRegistered();
}

class ErrorApp extends StatelessWidget {
  final String error;
  final String stackTrace;

  const ErrorApp({
    super.key,
    required this.error,
    this.stackTrace = '',
  });

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
                  'App initialization failed',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
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
                      fontFamily: 'monospace',
                    ),
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
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                const Text(
                  'Please share this error with the developer',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _resetAndRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text('Clear Hive data'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _resetAndRetry() async {
    try {
      await Hive.deleteFromDisk();
      print('[Reset] Hive data cleared');
    } catch (e) {
      print('[Reset] Failed: $e');
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
