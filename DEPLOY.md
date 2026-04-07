# 部署指南：Firebase + Vercel

## 第一步：创建 Firebase 项目

1. 访问 [Firebase Console](https://console.firebase.google.com/)
2. 点击 "Add project" → 输入项目名称 → 继续
3. 项目创建完成后，进入 **Build → Firestore Database**
4. 点击 "Create database"
   - 选择 **Start in test mode**（开发阶段）
   - 选择靠近的服务器位置
5. 创建完成后，记下 **Project Settings** 中的配置信息

## 第二步：获取 Firebase 配置

1. 进入 **Project Settings**（齿轮图标）
2. 滚动到 **Your apps** 部分
3. 点击 **</> (Web)** 图标注册应用
4. 输入应用昵称（随意）
5. 复制生成的配置代码：

```javascript
const firebaseConfig = {
  apiKey: "xxx",
  authDomain: "xxx.firebaseapp.com",
  projectId: "xxx",
  storageBucket: "xxx.appspot.com",
  messagingSenderId: "xxx",
  appId: "xxx"
};
```

## 第三步：更新应用配置

打开 `lib/core/firebase/firebase_config.dart`，将上述配置值填入：

```dart
class FirebaseConfig {
  static const String apiKey = '填入你的apiKey';
  static const String authDomain = '填入你的authDomain';
  static const String projectId = '填入你的projectId';
  static const String storageBucket = '填入你的storageBucket';
  static const String messagingSenderId = '填入你的messagingSenderId';
  static const String appId = '填入你的appId';
  // ...
}
```

## 第四步：设置 Firestore 安全规则

1. 在 Firebase Console 中进入 **Firestore Database**
2. 点击 **Rules** 标签
3. 将 `firestore.rules` 文件内容复制粘贴进去
4. 点击 **Publish**

规则说明：
- 所有数据**公开可读**（供粉丝围观）
- 所有数据**禁止写入**（需要在代码中单独实现写入逻辑，或添加认证）

## 第五步：推送代码到 GitHub

```bash
cd carbon_cycle_diet
git init
git add .
git commit -m "碳循环饮食管理 + Firebase 同步"
git branch -M main
git remote add origin https://github.com/你的用户名/carbon-cycle-diet.git
git push -u origin main
```

## 第六步：部署到 Vercel

1. 访问 [vercel.com](https://vercel.com)
2. 使用 GitHub 账号登录
3. 点击 **New Project**
4. 导入刚才推送的仓库
5. Vercel 会自动检测 Flutter 项目
6. 点击 **Deploy**

## 第七步：访问你的应用

- **编辑入口**（你自己用）：`https://你的vercel项目.vercel.app/`
- **围观入口**（粉丝用）：`https://你的vercel项目.vercel.app/#/public`

## 注意事项

### 数据同步
- 编辑端（HomePage）仍然使用 **本地 Hive 存储**
- 公开页（PublicViewPage）从 **Firebase 读取**
- **需要手动同步**：每次记录饮食后，数据会同步到 Firebase
- 围观页面**自动刷新**显示最新数据

### 围观功能实现原理
围观页面直接从 Firebase 读取数据，任何人都可以查看。但 Firebase 安全规则设置为只读，所以粉丝只能看，无法修改。

### 进一步完善（可选）
如果需要粉丝也能看到历史数据，需要：
1. 在 DietProvider 中添加 Firebase 同步逻辑
2. 每次记录保存时，同时写入 Firebase
3. 可添加匿名认证，让粉丝能订阅你的动态
