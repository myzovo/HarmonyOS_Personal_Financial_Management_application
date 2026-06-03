# 📒 记账本

> HarmonyOS 个人财务管理应用

基于 HarmonyOS SDK 5.1.0 (API 18) 开发，采用 ArkTS 语言和 Stage 模型架构，提供完整的账单录入、分类管理、统计分析和数据导出功能。

## ✨ 功能特性

### 🏠 首页仪表盘
- 今日/本月总支出、总收入、结余卡片展示
- 最近 5 条账单记录预览
- 底部 TabBar 快速切换页面

### ✏️ 记账功能
- 自定义数字键盘，支持退格删除和小数点输入（限 2 位小数）
- 分类图标网格，支出 15 类、收入 6 类、其他 10 类
- 自动填充当前时间，备注支持弹窗输入
- 再记一笔功能，支持连续记账

### 📋 账单列表
- 按月份/周筛选，日期分组展示
- 支持编辑和长按删除操作

### 📊 统计图表
- **饼图**：分类占比分析，支持触摸高亮和入场动画
- **折线图**：7 天收支趋势，多系列支持
- **柱状图**：月度每日收支，分组展示

### 📤 数据导出
- 支持 JSON/CSV 格式
- 可选月份、年度、全部或自定义日期范围
- 导出前可预览数据

## 🛠️ 技术栈

| 技术 | 说明 |
|------|------|
| HarmonyOS SDK 5.1.0 | API 18 |
| ArkTS | 基于 TypeScript 的声明式 UI 语言 |
| Stage 模型 | UIAbility 应用架构 |
| RDB | 关系型数据库（@ohos.data.relationalStore） |
| Canvas API | 自定义图表绘制 |
| CoreFileKit | 文件导出功能 |

## 📁 项目结构

```
entry/src/main/ets/
├── entryability/       # 应用入口（EntryAbility UIAbility 生命周期）
├── model/              # 数据模型
│   └── Bill.ets        # Bill 接口、BillType 枚举、分类常量
├── pages/              # 5 个页面组件
│   ├── Index.ets       # 首页仪表盘
│   ├── AddBill.ets     # 记账页面
│   ├── BillList.ets    # 账单列表
│   ├── Statistics.ets  # 统计图表
│   └── Export.ets      # 数据导出
├── components/         # 11 个可复用 UI 组件
│   ├── TabBar.ets      # 底部导航栏
│   ├── BillItem.ets    # 账单条目
│   ├── CategoryPicker.ets # 分类选择器
│   ├── PieChart.ets    # 饼图
│   ├── LineChart.ets   # 折线图
│   └── BarChart.ets    # 柱状图
└── utils/              # 工具类
    ├── DatabaseHelper.ets # 数据库操作（单例模式）
    ├── DateUtils.ets   # 日期工具
    ├── FileUtils.ets   # 文件导出
    ├── Constants.ets   # 常量定义
    └── ThemeColors.ets # 主题配色
```

## 🗄️ 数据库设计

使用 HarmonyOS RDB 关系型数据库，数据库名：`ledger.db`

### bills 表结构

| 字段 | 类型 | 说明 |
|------|------|------|
| id | TEXT PRIMARY KEY | 唯一标识（时间戳+随机数） |
| type | INTEGER NOT NULL | 类型：0=支出，1=收入 |
| amount | REAL NOT NULL | 金额 |
| category | TEXT NOT NULL | 分类名称 |
| remark | TEXT DEFAULT '' | 备注 |
| date | TEXT NOT NULL | 日期（YYYY-MM-DD），已建索引 |
| createTime | TEXT NOT NULL | 创建时间 |
| updateTime | TEXT NOT NULL | 更新时间 |

## 🏗️ 架构设计

```
┌─────────────────────────────────────────────────────────────┐
│                       页面层 Pages                          │
│  Index    AddBill    BillList    Statistics    Export        │
└─────────────────────────────────────────────────────────────┘
                              ↕
┌─────────────────────────────────────────────────────────────┐
│                     组件层 Components                        │
│  TabBar  BillItem  CategoryPicker  PieChart  LineChart ...  │
└─────────────────────────────────────────────────────────────┘
                              ↕
┌─────────────────────────────────────────────────────────────┐
│                       工具层 Utils                           │
│  DatabaseHelper  DateUtils  FileUtils  Constants  ThemeColors│
└─────────────────────────────────────────────────────────────┘
                              ↕
┌─────────────────────────────────────────────────────────────┐
│                       数据层 Data                            │
│              RDB relationalStore    CoreFileKit              │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 快速开始

### 环境要求

- DevEco Studio
- HarmonyOS SDK 5.1.0 (API 18)
- OHPM 包管理器

### 安装依赖

```bash
ohpm install
```

### 构建 HAP 包

```bash
hvigor assembleHap
```

### 运行测试

```bash
hvigor assembleHap --target ohosTest
```

### 部署运行

通过 DevEco Studio 部署到设备或模拟器。

## 📝 开发记录

### 遇到的问题及解决方案

| 问题 | 解决方案 |
|------|---------|
| getRdbStore() API 签名错误 | 移除第三个参数 DB_VERSION，使用非空断言 |
| ValueBucket 拼写错误 | 修正为 ValuesBucket |
| DatePickerResult 属性可能为 undefined | 使用空值合并运算符 ?? 提供默认值 |
| 组件属性名不匹配 | 统一属性命名（billId、chartSize 等） |
| TabBar 切换后返回键无效 | 改用 router.pushUrl() 保留页面栈 |
| Row 组件不支持 flexWrap | 改用 Flex({ wrap: FlexWrap.Wrap }) |
| @Builder 中 ForEach 解析异常 | 替换为显式组件实例或提取到独立方法 |

## 📄 License

本项目仅供学习参考。

---

**📒 记账本** - HarmonyOS 个人财务管理应用
