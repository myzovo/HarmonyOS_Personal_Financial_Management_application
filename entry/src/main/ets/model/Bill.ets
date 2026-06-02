/**
 * 账单数据模型
 * 定义账单相关的接口、枚举和预设分类常量
 */

/**
 * 账单类型枚举
 * EXPENSE: 支出 (0)
 * INCOME: 收入 (1)
 */
export enum BillType {
  EXPENSE = 0,  // 支出
  INCOME = 1    // 收入
}

/**
 * 账单接口
 * 定义账单数据的完整结构
 */
export interface Bill {
  id: string;           // 账单唯一标识
  amount: number;       // 金额
  type: BillType;       // 账单类型：0-支出，1-收入
  category: string;     // 分类名称
  description: string;  // 描述/备注
  date: string;         // 账单日期 (YYYY-MM-DD 格式)
  createdAt: string;    // 创建时间
  updatedAt: string;    // 更新时间
}

/**
 * 分类模型接口
 * 定义分类的基本信息
 */
export interface CategoryModel {
  name: string;   // 分类名称
  icon: string;   // 分类图标 (资源引用)
  type: BillType; // 分类所属类型：支出或收入
}

/**
 * 预设支出分类列表
 * 包含日常生活中常见的支出类别
 */
export const EXPENSE_CATEGORIES: CategoryModel[] = [
  { name: '餐饮', icon: 'ic_food', type: BillType.EXPENSE },
  { name: '交通', icon: 'ic_transport', type: BillType.EXPENSE },
  { name: '购物', icon: 'ic_shopping', type: BillType.EXPENSE },
  { name: '娱乐', icon: 'ic_entertainment', type: BillType.EXPENSE },
  { name: '医疗', icon: 'ic_medical', type: BillType.EXPENSE },
  { name: '教育', icon: 'ic_education', type: BillType.EXPENSE },
  { name: '居住', icon: 'ic_housing', type: BillType.EXPENSE },
  { name: '通讯', icon: 'ic_communication', type: BillType.EXPENSE },
  { name: '其他', icon: 'ic_other', type: BillType.EXPENSE }
];

/**
 * 预设收入分类列表
 * 包含常见的收入来源类别
 */
export const INCOME_CATEGORIES: CategoryModel[] = [
  { name: '工资', icon: 'ic_salary', type: BillType.INCOME },
  { name: '奖金', icon: 'ic_bonus', type: BillType.INCOME },
  { name: '投资', icon: 'ic_investment', type: BillType.INCOME },
  { name: '兼职', icon: 'ic_parttime', type: BillType.INCOME },
  { name: '其他', icon: 'ic_other', type: BillType.INCOME }
];

/**
 * 根据账单类型获取对应的分类列表
 * @param type 账单类型
 * @returns 对应类型的分类数组
 */
export function getCategoriesByType(type: BillType): CategoryModel[] {
  return type === BillType.EXPENSE ? EXPENSE_CATEGORIES : INCOME_CATEGORIES;
}
