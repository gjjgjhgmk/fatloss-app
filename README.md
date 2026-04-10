# 碳循环减脂应用 (Carbon Cycle Diet)

一个基于 Flutter Web 的减脂记录应用，围绕「碳循环饮食 + 训练打卡 + 体重腰围追踪 + 云端同步」展开。

## 当前功能

### 饮食管理
- 按训练日类型自动生成当日餐次模板
- 支持练前餐 / 练后餐配置
- 食材库检索、分类筛选、营养素实时计算
- 餐次支持完成 / 跳过 / 备注 / 照片字段

### 训练管理
- 训练循环：背 → 胸 → 腿 → 背 → 胸 → 肩 → 休息
- 动作清单打卡，自动统计完成度
- 支持空腹有氧标记（含 `60min 爬坡`）

### 身体数据
- 体重：早晚记录 + 历史查看
- 腰围：日记录 + 历史查看
- 首页月目标卡片按最新体重计算进度

### 数据同步
- 本地存储：Hive（离线可用）
- 云端存储：Supabase
- 冷启动后台同步今日数据
- 公开围观页：`/#/public`

## 技术栈

- Flutter 3.x
- Provider
- Hive / hive_flutter
- Supabase Flutter
- SharedPreferences

## 快速开始

```bash
flutter pub get
flutter run -d chrome
```

打包 Web：

```bash
flutter build web --release
```

## 路由

- `/`：主页面（饮食 + 训练 + 目标）
- `/public`：公开围观页

## Supabase 表结构对齐（重要）

当前代码已按以下约束实现映射，数据库字段请保持一致：

1. `daily_meal_records`
- `is_pre_workout`：`integer`（0/1）
- `is_post_workout`：`integer`（0/1）

2. `ingredients`
- `is_cooked`：`integer`（0/1）
- `is_common`：`integer`（0/1）
- 代码同步时**不会写入** `updated_at`（该表可不建此列）

3. `workout_records`
- `is_completed`：`integer`（0/1）
- `has_cardio`：`integer`（0/1）

## 部署

### Vercel
项目内已提供：
- `vercel.json`
- `vercel_build.sh`

直接连接 GitHub 仓库即可自动构建 `build/web`。

### 香港/海外节点（免备案方案）
可将 `build/web` 部署到 Nginx 静态站，`try_files` 回退到 `index.html` 以支持 Flutter 路由。

## 项目结构

```text
lib/
├─ core/                 # 常量、工具、数据库初始化、同步服务
├─ data/                 # models + repositories
├─ domain/usecases/      # 业务用例
└─ presentation/         # providers + screens
```

## 许可证

MIT License
