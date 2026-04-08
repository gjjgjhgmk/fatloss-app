import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String _url = 'https://ugzppavvwgmnmfmxacia.supabase.co';
  static const String _anonKey = 'sb_publishable_iHSBrJK2zwQPt-TLC_AaPg_iCXqhMSq';

  static final SupabaseClient client = SupabaseClient(_url, _anonKey);

  /// 初始化 Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(url: _url, anonKey: _anonKey);
  }
}
