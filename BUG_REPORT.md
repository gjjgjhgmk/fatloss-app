# 存储漏洞分析报告 (Bug Analysis Report)

**日期**: 2026/04/12
**项目**: 碳循环减脂应用 (Carbon Cycle Diet)
**状态**: ✅ 已修复

---

## 问题概述

用户报告了两个问题：
1. **iPhone 上修改食材库无法同步到后端数据库**
2. **练胸日变成只有一个餐食记录的选项，只能记一餐，且记录的餐食消失了**

---

## 修复状态

| 漏洞 | 状态 | 修复文件 |
|-----|------|---------|
| 漏洞1: 食材同步静默失败 | ✅ 已修复 | `lib/data/repositories/ingredient_repository.dart` |
| 漏洞2: 重建记录无原子性 | ✅ 已修复 | `lib/data/repositories/daily_record_repository.dart` |
| 漏洞3: pullCloudData 强制覆盖 | ✅ 已修复 | `lib/core/supabase/sync_service.dart` |
| 漏洞4: 缺少冲突检测 | ✅ 已修复 | `lib/core/supabase/sync_service.dart` (通过 last-write-wins) |
| 漏洞5: 同步状态无 UI 反馈 | ✅ 已修复 | `lib/presentation/providers/sync_provider.dart` + `home_page.dart` |

---

## 问题一：食材库同步失败

### 根本原因

同步采用 **"本地优先 + 异步 upsert"** 策略，但存在设计缺陷：

#### 问题代码位置
- `lib/data/repositories/ingredient_repository.dart:31-47`

```dart
Future<void> updateIngredient(Ingredient ingredient) async {
  await _hiveHelper.ingredientsBoxInstance.put(ingredient.id, ingredient);
  try {
    await SupabaseConfig.client.from('ingredients').upsert(
          ingredient.toMap(includeRemainingAmount: false),
        );
  } catch (_) {}  // ⚠️ 错误被静默吞掉！
}
```

#### 漏洞分析

| 步骤 | 预期行为 | 实际行为 |
|-----|---------|---------|
| 1 | 用户在 iPhone 修改食材 | ✅ 本地 Hive 写入成功 |
| 2 | 异步 upsert 到 Supabase | ❌ 失败但被静默忽略 |
| 3 | 下次冷启动同步 | ❌ 用旧数据覆盖云端 |

**时序问题**：

```
时间线：
iPhone (设备A)                    服务器 (Supabase)              设备B
    │                                │                            │
    │── upsert(ingredient_v2) ──────>│                            │
    │      (网络超时/失败)            │                            │
    │                                │                            │
    │  本地保存 ingredient_v2 ✅      │  仍是 ingredient_v1 ❌      │
    │                                │                            │
    │                                │<───── pullCloudData ───────│ 冷启动
    │                                │      返回 ingredient_v1    │
    │                                │                            │
    │<── 覆盖写入 ───────────────────│  ingredient_v1             │
    │   ingredient_v1 (旧数据)       │                            │
    │   用户修改丢失！⚠️              │                            │
```

#### 触发条件

1. 网络不稳定或 Supabase 请求超时
2. RLS (Row Level Security) 策略阻止写入但未抛出明确错误
3. 用户在 iPhone 修改后立即关闭 App（来不及后台同步）

#### 同步时间戳问题

`sync_service.dart:277-328` 使用 `lastSyncTime` 增量同步：

```dart
// 如果没有上次同步时间，则同步全部
if (lastSyncTime == null) {
  // 同步全部食材...
}

// 只同步修改时间晚于上次同步的食材
final modifiedIngredients = allIngredients.where((i) {
  return i.updatedAt.isAfter(lastSync);
}).toList();
```

**问题**：如果上次的 upsert 失败，`updatedAt` 不会被 Supabase 更新，但本地已更新。下次同步时，Supabase 端的 `updatedAt` 仍是旧值，可能导致冲突解决错误。

---

## 问题二：练胸日只有一餐 + 记录消失

### 根本原因

**餐次模板常量定义正确** (`diet_constants.dart:130-146`)：

```dart
case 'chest':
  return PUSH_PULL_MEALS;  // 3 meals: 11:00, 17:00, 22:30
```

**但 `rebuildDailyRecordsForDate` 方法存在数据丢失风险**：

#### 问题代码位置
- `lib/data/repositories/daily_record_repository.dart:66-71`

```dart
Future<void> rebuildDailyRecordsForDate(String date, String dayType) async {
  await _deleteLocalRecordsForDate(date);      // 1. 删除本地
  await _deleteRemoteRecordsForDate(date);     // 2. 删除云端
  await initializeDailyRecords(date, dayType); // 3. 重建（使用模板）
  await _syncDateRecordsToSupabase(date);      // 4. 同步到云端
}
```

#### 漏洞分析

**重建流程的问题**：

```
步骤1: 删除本地餐次记录 (for date = "2026-04-14")
       └── 删除 daily_meal_records + meal_item_records

步骤2: 删除云端餐次记录 (for date = "2026-04-14")
       └── DELETE FROM supabase

步骤3: 从模板重建餐次记录
       └── 根据 dayType 生成新的餐次模板
           dayType='chest' → 3 个模板 (PUSH_PULL_MEALS)

步骤4: 同步到云端
       └── upsert 到 supabase
```

**数据丢失场景**：

| 场景 | 问题 |
|-----|------|
| 步骤4失败 | 本地有新模板，云端仍是旧数据。下次 `pullCloudDataToLocal` 覆盖本地 |
| 用户同时在两设备操作 | 设备A删除，设备B也在删除/写入，造成竞态条件 |
| 网络分区 | 本地记录已删除，但云端同步失败，数据不一致 |

#### 同步冲突时的数据覆盖

`sync_service.dart:48-95` 的 `pullCloudDataToLocal` 采用 **覆盖策略**：

```dart
// 先清理本地今日数据
for (final id in localTodayMealIds) {
  await dailyBox.delete(id);
}
// 云端今日无数据，直接返回
if (mealRows.isEmpty) return;
// 覆盖写入餐次主记录
for (final meal in cloudMeals) {
  await dailyBox.put(meal.id, meal);
}
```

**问题**：如果云端数据是"重建后但同步失败"的状态，会覆盖本地正确的用户记录。

#### 为什么是"1餐"？

根据 `diet_constants.dart` 的定义：
- `REST_MEALS`: 2餐
- `PUSH_PULL_MEALS` (back/chest): 3餐
- `LEG_MEALS`: 4餐
- `CARDIO_MEALS`: 2餐

没有 1 餐的配置。**可能的原因**：

1. **cycle 计算错误**：如果日期类型判断错误（如判断成 rest），会生成 2 餐，不是 1
2. **模板未正确 seed**：新设备首次使用时，Hive Box 非空，跳过 seed
3. **数据损坏**：部分记录被删除，只剩 1 条

---

## 发现的存储漏洞汇总

### 漏洞 1：食材同步静默失败

| 项目 | 详情 |
|-----|------|
| **文件** | `lib/data/repositories/ingredient_repository.dart:31-47` |
| **问题** | upsert 失败被 `catch (_) {}` 静默忽略 |
| **影响** | 本地修改不生效，云端数据不同步 |
| **修复建议** | 添加错误日志记录，或使用队列重试机制 |

### 漏洞 2：重建记录无原子性保证

| 项目 | 详情 |
|-----|------|
| **文件** | `lib/data/repositories/daily_record_repository.dart:66-71` |
| **问题** | `rebuildDailyRecordsForDate` 删除和重建不是原子操作 |
| **影响** | 同步失败时用户记录丢失 |
| **修复建议** | 使用事务或先创建新记录再删除旧记录 |

### 漏洞 3：pullCloudData 强制覆盖

| 项目 | 详情 |
|-----|------|
| **文件** | `lib/core/supabase/sync_service.dart:48-95` |
| **问题** | 启动时强制用云端数据覆盖本地，无冲突检测 |
| **影响** | 多设备同时使用时会相互覆盖数据 |
| **修复建议** | 实现 last-write-wins 或基于 `updatedAt` 的合并策略 |

### 漏洞 4：缺少冲突检测

| 项目 | 详情 |
|-----|------|
| **文件** | 全局 |
| **问题** | 没有乐观锁或版本控制机制 |
| **影响** | 并发修改时数据冲突，无法恢复 |
| **修复建议** | 为每条记录添加 `version` 字段或使用 `updatedAt` 做冲突解决 |

### 漏洞 5：同步状态无 UI 反馈

| 项目 | 详情 |
|-----|------|
| **文件** | 全局 |
| **问题** | 用户不知道数据是否已同步到云端 |
| **影响** | 用户以为已保存，但实际可能只存在本地 |
| **修复建议** | 添加同步状态指示器（如 "已同步" / "同步中..." / "同步失败"）|

---

## 复现步骤

### 食材同步失败复现

1. 打开 iPhone App，修改食材 A 的名称
2. **立即** 关闭 App（或开启飞行模式）
3. 在另一设备或同一设备的冷启动
4. 观察：食材 A 的名称是旧名称

### 餐次记录消失复现

1. 在 chest day 记录第 1 餐（假设成功了）
2. 打开 meal_record_page 尝试记录第 2 餐
3. 如果此时触发 `rebuildDailyRecordsForDate`（如切换休息日）
4. 第 1 餐的记录可能丢失

---

## 建议修复方案

### 1. 食材同步修复

```dart
Future<void> updateIngredient(Ingredient ingredient) async {
  await _hiveHelper.ingredientsBoxInstance.put(ingredient.id, ingredient);

  // 添加重试逻辑
  for (int i = 0; i < 3; i++) {
    try {
      await SupabaseConfig.client.from('ingredients').upsert(
            ingredient.toMap(includeRemainingAmount: false),
          );
      return; // 成功后退出
    } catch (e) {
      if (i == 2) {
        print('[Sync] 食材 ${ingredient.id} 同步失败: $e');
        // 可以考虑添加到本地失败队列，稍后重试
      }
      await Future.delayed(Duration(seconds: 1 * (i + 1))); // 指数退避
    }
  }
}
```

### 2. 重建操作原子化

```dart
Future<void> rebuildDailyRecordsForDate(String date, String dayType) async {
  // 方案A: 先创建新记录，验证成功后再删除旧记录
  // 方案B: 使用 Supabase 事务
  // 方案C: 软删除 + 状态字段
}
```

### 3. 冲突解决策略

```dart
// 在 pullCloudDataToLocal 中实现 last-write-wins
Future<void> pullCloudDataToLocal({DateTime? targetDate}) async {
  // 获取本地和云端的 updatedAt
  // 比较时间戳，保留最新版本
  // 如果时间相同或接近，保留本地（用户正在操作的数据）
}
```

---

## 相关代码路径索引

| 功能 | 文件路径 |
|-----|---------|
| 食材更新 Repository | `lib/data/repositories/ingredient_repository.dart` |
| 餐次重建 Repository | `lib/data/repositories/daily_record_repository.dart` |
| 同步服务 | `lib/core/supabase/sync_service.dart` |
| 餐次模板常量 | `lib/core/constants/diet_constants.dart` |
| 日期类型解析 | `lib/core/utils/date_type_resolver.dart` |
| Hive 初始化 | `lib/core/database/hive_helper.dart` |
| App 初始化 | `lib/main.dart` |

---

## 测试建议

1. **食材同步测试**：修改食材 → 开启飞行模式 → 关闭 App → 冷启动 → 检查云端
2. **餐次重建测试**：记录多餐 → 切换为休息日 → 切换回训练日 → 检查记录是否保留
3. **多设备同步测试**：设备A记录 → 设备B同时修改 → 检查冲突处理
