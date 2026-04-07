import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  // ============================================
  // Firebase 配置（请替换为你自己的配置）
  // 步骤：
  // 1. 访问 https://console.firebase.google.com
  // 2. 创建新项目
  // 3. 添加 Web 应用，获取配置信息
  // 4. 复制下面的配置值
  // ============================================

  static const apiKey = "AIzaSyDXgdQ5KhVHkJmYjUK5AXmV4R6rQllFMVk";
  static const authDomain = "fatloss-7001c.firebaseapp.com";
  static const projectId = "fatloss-7001c";
  static const storageBucket = "fatloss-7001c.firebasestorage.app";
  static const messagingSenderId = "475138093961";
  static const appId = "1:475138093961:web:64c8c21e02d7ec208c6758";
  static FirebaseOptions get options => const FirebaseOptions(
        apiKey: apiKey,
        authDomain: authDomain,
        projectId: projectId,
        storageBucket: storageBucket,
        messagingSenderId: messagingSenderId,
        appId: appId,
      );
}
