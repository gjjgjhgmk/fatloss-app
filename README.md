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

## 前后端同步机制（核心架构）

本应用采用 **"本地优先 + 云端异步同步"** 策略，兼顾离线可用性与多设备数据一致性。

### 同步策略

| 操作 | 策略 | 说明 |
|-----|------|-----|
| **读取** | 云端优先 | 启动时从 Supabase 拉取数据，**覆盖**本地 |
| **写入** | 本地优先 | 数据先写入 Hive，异步同步到 Supabase |
| **失败处理** | 静默忽略 | 同步失败不阻塞本地使用 |

### 初始化流程

```
main()
  │
  ├─ Hive.initFlutter()
  │   └─ HiveHelper.instance.initialize()
  │       → 打开所有本地 Box
  │       → 注册 Hive TypeAdapter
  │       → 种子初始数据（如食材库为空）
  │
  ├─ SupabaseConfig.initialize()
  │   → 初始化云端客户端
  │
  ├─ SyncService().pullCloudDataToLocal()  ← 云端优先
  │   → 清空本地当日数据
  │   → 从 Supabase 拉取当日数据
  │   → 覆盖写入本地 Hive
  │
  ├─ runApp()
  │
  └─ SyncService().syncAllRecentData()  ← Fire-and-forget 后台同步
      → 本地数据 upsert 到 Supabase
```

### 同步服务详解

#### 1. `pullCloudDataToLocal()` — 启动时拉取

位置：`lib/core/supabase/sync_service.dart:26-41`

从云端拉取当日数据并覆盖本地，实现多设备数据同步：

```dart
await _pullTodayMealRecords(today);    // 餐次 + 餐次明细
await _pullTodayWorkoutRecords(today); // 训练记录
await _pullTodayWeightRecords(today);  // 体重记录
await _pullTodayWaistRecords(today);   // 腰围记录
```

**拉取流程**（以餐次记录为例）：
1. 清空本地当日 `daily_meal_records` 和关联的 `meal_item_records`
2. 从 Supabase 查询当日记录
3. 覆盖写入本地 Hive Box

#### 2. `syncAllRecentData()` — 后台同步

位置：`lib/core/supabase/sync_service.dart:160-193`

冷启动时 Fire-and-forget 触发，将本地数据同步到云端：

```dart
1. 同步今日餐次记录   → Supabase (upsert)
2. 同步今日体重记录   → Supabase (upsert)
3. 同步今日腰围记录   → Supabase (upsert)
4. 同步今日训练记录   → Supabase (upsert)
5. 同步变更的食材库   → Supabase (按 updatedAt 增量)
6. 同步饮食规则      → Supabase (仅在云端为空时)
```

### 各数据类型同步方式

#### 每日餐次记录 (DailyMealRecord)

```dart
// 写入：lib/data/repositories/daily_record_repository.dart:73-77
1. box.put(record.id, record)          // 写入本地 Hive
2. _syncToSupabase(record, items)      // 异步 upsert 到云端

// 读取：lib/core/supabase/sync_service.dart:48-95
1. 清空本地当日数据
2. 从 Supabase 拉取当日数据
3. 覆盖写入本地 Hive
```

#### 食材 (Ingredient)

```dart
// 写入：lib/data/repositories/ingredient_repository.dart:31-37
1. box.put(ingredient.id, ingredient)   // 写入本地 Hive
2. client.from('ingredients').upsert()  // 异步同步到云端

// 增量同步：lib/core/supabase/sync_service.dart:277-328
- 使用 lastSyncTime 时间戳
- 只同步 updatedAt > lastSyncTime 的记录
```

#### 体重 / 腰围 / 训练记录

- 写入：本地优先，异步 upsert 到 Supabase
- 读取：启动时云端覆盖本地

### 数据模型 ↔ Supabase 表映射

| Hive Model | Supabase Table | Box Name |
|-----------|---------------|----------|
| DailyMealRecord | daily_meal_records | daily_meal_records |
| MealItemRecord | meal_item_records | meal_item_records |
| Ingredient | ingredients | ingredients |
| WeightRecord | weight_records | weight_records |
| WaistRecord | waist_records | waist_records |
| WorkoutRecord | workout_records | workout_records |
| DietRule | diet_rules | diet_rules |

### 关键代码路径

| 功能 | 文件路径 |
|-----|---------|
| Hive 初始化 | `lib/core/database/hive_helper.dart` |
| Supabase 配置 | `lib/core/supabase/supabase_config.dart` |
| **同步服务（核心）** | `lib/core/supabase/sync_service.dart` |
| 餐次 Repository | `lib/data/repositories/daily_record_repository.dart` |
| Provider 状态管理 | `lib/presentation/providers/diet_provider.dart` |
| 业务逻辑编排 | `lib/domain/usecases/daily_diet_manager.dart` |

### 项目结构

```text
lib/
├─ main.dart                              # 应用入口，初始化流程
├─ core/
│   ├─ database/
│   │   └─ hive_helper.dart              # Hive 初始化、Box 管理、种子数据
│   ├─ supabase/
│   │   ├─ supabase_config.dart          # Supabase 客户端配置
│   │   └─ sync_service.dart             # 云端同步服务（核心）
│   ├─ constants/
│   │   ├─ diet_constants.dart          # 饮食常量（餐次模板）
│   │   └─ workout_constants.dart        # 训练常量
│   └─ utils/
│       ├─ date_type_resolver.dart       # 日期 → 日期类型解析
│       └─ nutrition_calculator.dart     # 营养计算
├─ data/
│   ├─ models/                           # 数据模型（Hive TypeAdapter）
│   │   ├─ daily_meal_record.dart       # 每日餐次记录
│   │   ├─ meal_item_record.dart        # 餐次明细项
│   │   ├─ ingredient.dart              # 食材
│   │   ├─ diet_rule.dart              # 饮食规则
│   │   ├─ weight_record.dart           # 体重记录
│   │   ├─ waist_record.dart           # 腰围记录
│   │   ├─ workout_record.dart          # 训练记录
│   │   └─ app_settings.dart           # 应用设置
│   └─ repositories/                     # 数据访问层
│       ├─ daily_record_repository.dart
│       ├─ ingredient_repository.dart
│       ├─ weight_record_repository.dart
│       └─ ...
├─ domain/usecases/
│   └─ daily_diet_manager.dart          # 业务逻辑编排
└─ presentation/
    ├─ providers/                        # Provider 状态管理
    │   ├─ diet_provider.dart
    │   ├─ review_provider.dart
    │   └─ workout_provider.dart
    └─ screens/                          # UI 页面
```

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

## 许可证

MIT License
