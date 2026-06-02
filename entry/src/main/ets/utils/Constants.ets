/**
 * 常量定义文件
 * 定义数据库、表名、列名、分类图标和默认分类等常量
 */

// ==================== 数据库常量 ====================

/** 数据库名称 */
export const DB_NAME: string = 'ledger.db'

/** 数据库版本 */
export const DB_VERSION: number = 1

// ==================== 表名常量 ====================

/** 账单表名 */
export const TABLE_BILLS: string = 'bills'

// ==================== 列名常量 ====================

/** 账单ID列 */
export const COL_ID: string = 'id'

/** 账单类型列（收入/支出） */
export const COL_TYPE: string = 'type'

/** 金额列 */
export const COL_AMOUNT: string = 'amount'

/** 分类列 */
export const COL_CATEGORY: string = 'category'

/** 备注列 */
export const COL_REMARK: string = 'remark'

/** 日期列 */
export const COL_DATE: string = 'date'

/** 创建时间列 */
export const COL_CREATE_TIME: string = 'createTime'

// ==================== 账单类型常量 ====================

/** 支出类型 */
export const TYPE_EXPENSE: number = 0

/** 收入类型 */
export const TYPE_INCOME: number = 1

// ==================== 分类图标映射 ====================

/**
 * 分类图标映射（使用 emoji）
 * key: 分类名称
 * value: 对应的 emoji 图标
 */
export const CATEGORY_ICONS: Record<string, string> = {
  '餐饮': '🍜',
  '交通': '🚌',
  '购物': '🛒',
  '住房': '🏠',
  '娱乐': '🎮',
  '医疗': '💊',
  '教育': '📚',
  '通讯': '📱',
  '服饰': '👔',
  '美容': '💄',
  '运动': '⚽',
  '旅行': '✈️',
  '宠物': '🐱',
  '礼物': '🎁',
  '工资': '💰',
  '奖金': '🏆',
  '理财': '📈',
  '兼职': '💼',
  '红包': '🧧',
  '其他': '📋'
}

// ==================== 默认分类列表 ====================

/** 支出分类列表 */
export const EXPENSE_CATEGORIES: string[] = [
  '餐饮',
  '交通',
  '购物',
  '住房',
  '娱乐',
  '医疗',
  '教育',
  '通讯',
  '服饰',
  '美容',
  '运动',
  '旅行',
  '宠物',
  '礼物',
  '其他'
]

/** 收入分类列表 */
export const INCOME_CATEGORIES: string[] = [
  '工资',
  '奖金',
  '理财',
  '兼职',
  '红包',
  '其他'
]

/**
 * 根据分类名称获取图标
 * @param category 分类名称
 * @returns 对应的 emoji 图标，未找到时返回默认图标
 */
export function getCategoryIcon(category: string): string {
  if (CATEGORY_ICONS[category]) {
    return CATEGORY_ICONS[category]
  }
  return '📋'
}

/**
 * 根据账单类型获取分类列表
 * @param type 账单类型（0-支出，1-收入）
 * @returns 对应的分类列表
 */
export function getCategoriesByType(type: number): string[] {
  if (type === TYPE_EXPENSE) {
    return EXPENSE_CATEGORIES
  }
  return INCOME_CATEGORIES
}

// ==================== 备注建议 ====================

/**
 * 各分类的常用备注建议
 * 选择分类后显示对应的快捷备注标签，点击即可填入
 */
export const RemarkSuggestions: Record<string, string[]> = {
  '餐饮': ['早餐', '午餐', '晚餐', '外卖', '下午茶', '水果', '零食', '聚餐'],
  '交通': ['地铁', '公交', '打车', '加油', '停车', '共享单车', '高铁', '机票'],
  '购物': ['日用品', '衣服', '鞋子', '数码产品', '家居', '超市采购', '网购'],
  '住房': ['房租', '水电费', '物业费', '燃气费', '维修', '装修'],
  '娱乐': ['电影', '游戏', 'KTV', '演唱会', '桌游', '密室逃脱'],
  '医疗': ['挂号', '药品', '体检', '牙科', '眼科', '保健品'],
  '教育': ['课程', '书籍', '培训', '考试报名', '文具'],
  '通讯': ['话费', '宽带', '流量包', '会员订阅'],
  '服饰': ['上衣', '裤子', '外套', '鞋子', '配饰', '包包'],
  '美容': ['护肤品', '化妆品', '理发', '美甲', 'SPA'],
  '运动': ['健身房', '球类', '游泳', '瑜伽', '运动装备'],
  '旅行': ['酒店', '门票', '交通费', '纪念品', '餐饮'],
  '宠物': ['猫粮', '狗粮', '宠物医院', '宠物用品', '美容'],
  '礼物': ['生日礼物', '节日礼物', '人情往来', '红包'],
  '工资': ['月薪', '周薪', '提成', '补贴'],
  '奖金': ['年终奖', '绩效奖', '项目奖金', '全勤奖'],
  '理财': ['基金收益', '股票分红', '利息', '租金收入'],
  '兼职': ['兼职收入', '外包项目', '咨询费', '稿费'],
  '红包': ['节日红包', '生日红包', '转账'],
  '其他': ['其他收入', '其他支出', '报销', '退款']
}

/**
 * 常用快捷金额列表
 */
export const QUICK_AMOUNTS: number[] = [10, 20, 50, 100, 200, 500]
