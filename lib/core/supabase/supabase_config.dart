import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String _url = 'https://ugzppavvwgmnmfmxacia.supabase.co';
  static const String _anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVnenBwYXZ2d2dtbm1mbXhhY2lhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU2MjU0NzIsImV4cCI6MjA5MTIwMTQ3Mn0.2Cof_mYQ7IaDvk_o2S69FYKrq_4SZC68JCFh1Yz-2bY';

  /// 初始化 Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(url: _url, anonKey: _anonKey);
  }

  /// 获取 Supabase 客户端
  static SupabaseClient get client => Supabase.instance.client;
}
