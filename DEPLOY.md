# 部署指南：Supabase + Vercel

## 在线访问

- **编辑入口**：`https://fatloss-app.vercel.app/`
- **围观入口**：`https://fatloss-app.vercel.app/#/public`

---

## 第一步：创建 Supabase 项目

1. 访问 [Supabase](https://supabase.com/)
2. 点击 "New Project"
3. 输入项目名称，选择区域
4. 等待项目创建完成

## 第二步：获取 Supabase 配置

1. 进入 **Project Settings** → **API**
2. 复制 `Project URL` 和 `anon public` key

## 第三步：更新应用配置

打开 `lib/core/supabase/supabase_config.dart`，填入你的配置：

```dart
class SupabaseConfig {
  static const String _url = '你的Project URL';
  static const String _anonKey = '你的anon key';
  // ...
}
```

## 第四步：创建数据库表

在 Supabase SQL Editor 中执行以下 SQL：

```sql
-- 每日餐次记录
CREATE TABLE daily_meal_records (
  id TEXT PRIMARY KEY,
  record_date TEXT NOT NULL,
  day_type TEXT NOT NULL,
  meal_order INTEGER NOT NULL,
  meal_time TEXT NOT NULL,
  planned_carb REAL DEFAULT 0,
  planned_protein REAL DEFAULT 0,
  planned_fat REAL DEFAULT 0,
  actual_carb REAL DEFAULT 0,
  actual_protein REAL DEFAULT 0,
  actual_fat REAL DEFAULT 0,
  meal_status TEXT DEFAULT 'pending',
  notes TEXT,
  is_pre_workout INTEGER DEFAULT 0,
  is_post_workout INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  photo_url TEXT
);

-- 餐次食材记录
CREATE TABLE meal_item_records (
  id TEXT PRIMARY KEY,
  daily_meal_record_id TEXT NOT NULL,
  ingredient_id TEXT,
  name TEXT NOT NULL,
  amount REAL NOT NULL,
  carb REAL DEFAULT 0,
  protein REAL DEFAULT 0,
  fat REAL DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);

-- 体重记录
CREATE TABLE weight_records (
  id TEXT PRIMARY KEY,
  record_date TEXT NOT NULL,
  time_of_day TEXT NOT NULL,
  weight REAL NOT NULL,
  record_time TEXT,
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 腰围记录
CREATE TABLE waist_records (
  id TEXT PRIMARY KEY,
  record_date TEXT NOT NULL,
  waist REAL NOT NULL,
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 食材库
CREATE TABLE ingredients (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  carb_per_100g REAL DEFAULT 0,
  protein_per_100g REAL DEFAULT 0,
  fat_per_100g REAL DEFAULT 0,
  is_cooked INTEGER DEFAULT 0,
  is_common INTEGER DEFAULT 0,
  unit TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- 饮食规则
CREATE TABLE diet_rules (
  day_type TEXT PRIMARY KEY,
  total_carb REAL DEFAULT 0,
  total_protein REAL DEFAULT 0,
  total_fat REAL DEFAULT 0,
  meal_count INTEGER DEFAULT 0,
  special_notes TEXT
);

-- 训练记录
CREATE TABLE workout_records (
  id TEXT PRIMARY KEY,
  record_date TEXT NOT NULL,
  day_type TEXT NOT NULL,
  exercises TEXT,
  is_completed INTEGER DEFAULT 0,
  photo_url TEXT,
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 启用 RLS
ALTER TABLE daily_meal_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE meal_item_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE weight_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE waist_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE ingredients ENABLE ROW LEVEL SECURITY;
ALTER TABLE diet_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_records ENABLE ROW LEVEL SECURITY;

-- 允许公开读写
CREATE POLICY "Allow all" ON daily_meal_records FOR ALL USING (true);
CREATE POLICY "Allow all" ON meal_item_records FOR ALL USING (true);
CREATE POLICY "Allow all" ON weight_records FOR ALL USING (true);
CREATE POLICY "Allow all" ON waist_records FOR ALL USING (true);
CREATE POLICY "Allow all" ON ingredients FOR ALL USING (true);
CREATE POLICY "Allow all" ON diet_rules FOR ALL USING (true);
CREATE POLICY "Allow all" ON workout_records FOR ALL USING (true);

-- 创建索引
CREATE INDEX idx_daily_meal_records_date ON daily_meal_records(record_date);
CREATE INDEX idx_meal_item_records_daily_id ON meal_item_records(daily_meal_record_id);
CREATE INDEX idx_weight_records_date ON weight_records(record_date DESC);
CREATE INDEX idx_waist_records_date ON waist_records(record_date DESC);
CREATE INDEX idx_workout_records_date ON workout_records(record_date DESC);
```

## 第五步：推送代码到 GitHub

```bash
cd carbon_cycle_diet
git add .
git commit -m "feat: 碳循环减脂应用"
git branch -M main
git remote add origin https://github.com/gjjgjhgmk/fatloss-app.git
git push -u origin main
```

## 第六步：部署到 Vercel

1. 访问 [vercel.com](https://vercel.com)
2. 使用 GitHub 账号登录
3. 导入仓库 `https://github.com/gjjgjhgmk/fatloss-app`
4. Vercel 自动检测 Flutter 项目
5. 点击 **Deploy**

---

## 数据同步说明

### 同步策略

| 数据类型 | 同步范围 |
|---------|---------|
| 每日餐次 | 只同步今天的数据 |
| 体重/腰围/训练 | 只同步今天的数据 |
| 食材库 | 只同步有变更的记录 |
| 饮食规则 | 仅在云端为空时同步 |

### 冷启动同步

应用启动时自动执行 `SyncService`，将近期数据同步到 Supabase。
同步在后台静默执行，不阻塞 UI。

### 围观功能

公开页面 `/#/public` 从 Supabase 读取数据。
围观用户只能读取，不能修改数据。

---

## 技术栈

- **Flutter** - 跨平台框架
- **Hive** - 本地数据库
- **Supabase** - 云端数据库
- **Vercel** - 部署平台
