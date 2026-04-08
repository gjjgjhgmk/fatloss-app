# 碳循环减脂应用 (Carbon Cycle Diet)

一个结合碳循环饮食管理与运动训练的减脂辅助应用，支持饮食记录、体重追踪、训练打卡和数据同步。

---

## 功能概览

### 饮食管理
- **碳循环饮食**：根据训练日类型自动调整碳水摄入（练背/练胸 240g、练腿日 280g、休息日 160g）
- **餐次记录**：支持练前餐、练后餐的特殊配置
- **营养素追踪**：实时显示碳水/蛋白质/脂肪摄入进度
- **食材库**：常用食材营养素数据，支持自定义添加

### 运动训练
- **训练日类型**：练背日、练胸日、练腿日、练肩日、空腹有氧
- **训练计划**：每个训练日配置专属动作列表
- **打卡功能**：勾选完成动作，记录训练状态
- **进度可视化**：圆形进度条显示完成度

### 身体数据
- **体重记录**：早晚体重记录，趋势图表
- **腰围记录**：腰围变化追踪
- **月度目标**：设置减重目标，追踪进度

### 数据同步
- **本地存储**：Hive 数据库，离线可用
- **云端同步**：Supabase，云端备份 + 围观页面
- **冷启动同步**：应用启动时自动将近期数据同步到云端
- **围观模式**：粉丝可通过公开页面查看饮食和训练记录

---

## 技术架构

### 框架 & 工具
- **Flutter 3.x** - 跨平台应用框架
- **Provider** - 状态管理
- **Hive** - 本地数据库
- **Supabase** - 云端数据库（PostgreSQL）
- **Vercel** - 部署平台

### 项目结构

```
lib/
├── core/
│   ├── constants/         # 常量配置
│   │   ├── diet_constants.dart      # 饮食常量（营养素、餐次配置）
│   │   └── workout_constants.dart   # 训练常量（动作计划）
│   ├── database/
│   │   └── hive_helper.dart        # Hive 数据库初始化
│   ├── supabase/
│   │   ├── supabase_config.dart    # Supabase 配置
│   │   └── sync_service.dart       # 冷启动静默同步服务
│   └── utils/
│       ├── date_type_resolver.dart   # 日期类型解析
│       └── nutrition_calculator.dart  # 营养素计算
├── data/
│   ├── models/            # 数据模型
│   │   ├── daily_meal_record.dart   # 每日餐次记录
│   │   ├── meal_item_record.dart    # 餐次食材记录
│   │   ├── ingredient.dart          # 食材
│   │   ├── weight_record.dart       # 体重记录
│   │   ├── waist_record.dart        # 腰围记录
│   │   └── workout_record.dart      # 训练记录
│   └── repositories/     # 数据仓库
│       ├── daily_record_repository.dart
│       ├── ingredient_repository.dart
│       ├── weight_record_repository.dart
│       └── workout_record_repository.dart
├── domain/
│   └── usecases/
│       ├── daily_diet_manager.dart     # 饮食管理
│       └── diet_review_generator.dart  # 饮食复盘生成
└── presentation/
    ├── providers/         # 状态管理
    │   ├── diet_provider.dart
    │   ├── review_provider.dart
    │   └── workout_provider.dart
    └── screens/          # 页面
        ├── home_page.dart           # 首页
        ├── workout_page.dart       # 训练打卡页
        ├── meal_record_page.dart   # 餐次记录页
        ├── weight_record_page.dart # 体重记录页
        ├── waist_record_page.dart  # 腰围记录页
        ├── ingredient_page.dart     # 食材库页
        ├── review_page.dart        # 复盘页
        └── public_view_page.dart   # 公开围观页
```

---

## 训练计划

### 训练循环
背 → 胸 → 腿 → 背 → 胸 → 肩 → 休息（7天循环）

### 各训练日动作

| 训练日 | 动作列表 |
|--------|---------|
| **练胸日** | 上斜杠铃卧推、杠铃卧推、器械飞鸟、双杠臂屈伸（辅助） |
| **练背日** | 引体向上（辅助）、宽距下拉、坐姿单手划船、坐姿划船、哑铃弯举 |
| **练腿日** | 深蹲、杠铃臀冲、卷腹、站姿器械提踵、器械倒蹬、硬拉、坐姿髋内收 |
| **练肩日** | 哑铃推肩、蝴蝶机反向飞鸟、侧平举 |
| **有氧日** | 空腹有氧、跑步、骑行 |

---

## 营养素配置

### 每日营养素目标
- **蛋白质**：120g（固定）
- **脂肪**：56g（固定）
- **碳水**：根据训练日浮动

### 碳水配置
| 日期类型 | 碳水摄入 |
|---------|---------|
| 休息日 | 160g |
| 练背/练胸日 | 240g |
| 练腿日 | 280g |
| 练肩日 | 200g |
| 空腹有氧日 | 160g |

---

## 部署指南

### 在线访问
- **编辑入口**：https://fatloss-app.vercel.app/
- **围观入口**：https://fatloss-app.vercel.app/#/public

### 部署到 Vercel

1. 推送代码到 GitHub
2. Vercel 自动检测 Flutter 项目并部署
3. 访问 https://vercel.com/dashboard 查看部署状态

### Supabase 配置

应用已配置好 Supabase 连接。表结构见 `DEPLOY.md`。

---

## 数据说明

### 本地存储（Hive）
- 饮食记录（每日餐次、食材明细）
- 训练记录
- 体重/腰围数据
- 食材库

### 云端同步（Supabase）
- **冷启动同步**：应用启动时自动同步今日数据到云端
- **增量同步**：食材库只同步有变更的记录
- **公开页面**：从 Supabase 读取，围观用户只能读取

### 同步策略
| 数据类型 | 同步范围 |
|---------|---------|
| 每日餐次 | 只同步今天的数据 |
| 体重/腰围/训练 | 只同步今天的数据 |
| 食材库 | 只同步有变更的记录 |
| 饮食规则 | 仅在云端为空时同步 |

---

## 未来优化方向

- [ ] 照片打卡功能
- [ ] 历史数据图表展示
- [ ] 训练重量记录
- [ ] 饮食提醒功能
- [ ] 进度分享图片生成

---

## 关于作者

这是一个 personal project，用于记录减脂过程中的饮食和训练数据，希望能成为一份珍贵的个人回忆录。

---

## 许可证

MIT License
