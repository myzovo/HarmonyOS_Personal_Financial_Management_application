/**
 * 数据库操作封装工具类
 * 使用 @ohos.data.relationalStore 的 rdb 关系型数据库 API
 * 封装账单的增删改查及统计功能，采用单例模式
 */

import relationalStore from '@ohos.data.relationalStore'
import { Bill, BillType } from '../model/Bill'
import {
  DB_NAME,
  DB_VERSION,
  TABLE_BILLS,
  COL_ID,
  COL_TYPE,
  COL_AMOUNT,
  COL_CATEGORY,
  COL_REMARK,
  COL_DATE,
  COL_CREATE_TIME
} from './Constants'
import { common } from '@kit.AbilityKit'

/**
 * 数据库列名常量 - 更新时间
 * Constants 中未定义此列，此处补充定义
 */
const COL_UPDATE_TIME: string = 'updateTime'

/**
 * 统计结果接口
 * 用于按分类分组的统计数据
 */
export interface StatisticsResult {
  category: string    // 分类名称
  total: number       // 该分类的总金额
  count: number       // 该分类的账单数量
}

/**
 * 收支汇总接口
 * 用于今日/本月的收支汇总数据
 */
export interface SummaryResult {
  totalExpense: number  // 支出总额
  totalIncome: number   // 收入总额
  balance: number       // 结余（收入 - 支出）
  expenseCount: number  // 支出笔数
  incomeCount: number   // 收入笔数
}

/**
 * DatabaseHelper 数据库操作帮助类
 * 采用单例模式，提供账单数据的完整 CRUD 操作和统计功能
 */
export class DatabaseHelper {
  /** 单例实例 */
  private static instance: DatabaseHelper | null = null

  /** 数据库实例 */
  private rdbStore: relationalStore.RdbStore | null = null

  /** 应用上下文 */
  private context: common.UIAbilityContext | null = null

  /**
   * 私有构造函数，防止外部直接创建实例
   */
  private constructor() {
  }

  /**
   * 获取 DatabaseHelper 单例实例
   * @returns DatabaseHelper 单例
   */
  static getInstance(): DatabaseHelper {
    if (!DatabaseHelper.instance) {
      DatabaseHelper.instance = new DatabaseHelper()
    }
    return DatabaseHelper.instance
  }

  /**
   * 初始化数据库
   * 创建数据库连接并建立 bills 表
   * @param context 应用上下文（UIAbilityContext）
   */
  async initDatabase(context: common.UIAbilityContext): Promise<void> {
    this.context = context

    // 数据库配置
    const STORE_CONFIG: relationalStore.StoreConfig = {
      name: DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    }

    try {
      // 获取或创建数据库实例
      this.rdbStore = await relationalStore.getRdbStore(context, STORE_CONFIG)

      // 创建账单表
      const createTableSql = `CREATE TABLE IF NOT EXISTS ${TABLE_BILLS} (
        ${COL_ID} TEXT PRIMARY KEY,
        ${COL_TYPE} INTEGER NOT NULL,
        ${COL_AMOUNT} REAL NOT NULL,
        ${COL_CATEGORY} TEXT NOT NULL,
        ${COL_REMARK} TEXT DEFAULT '',
        ${COL_DATE} TEXT NOT NULL,
        ${COL_CREATE_TIME} TEXT NOT NULL,
        ${COL_UPDATE_TIME} TEXT NOT NULL
      )`

      await this.rdbStore!.executeSql(createTableSql)

      // 为日期列创建索引，提高按月/按日期范围查询的性能
      const createIndexSql = `CREATE INDEX IF NOT EXISTS idx_bill_date ON ${TABLE_BILLS}(${COL_DATE})`
      await this.rdbStore!.executeSql(createIndexSql)

      console.info('DatabaseHelper', '数据库初始化成功，bills 表已创建')
    } catch (err) {
      console.error('DatabaseHelper', `数据库初始化失败: ${err}`)
      throw new Error(`数据库初始化失败: ${err}`)
    }
  }

  /**
   * 获取数据库实例（内部使用）
   * 如果未初始化则抛出异常
   * @returns RdbStore 数据库实例
   */
  private getStore(): relationalStore.RdbStore {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化，请先调用 initDatabase() 方法')
    }
    return this.rdbStore
  }

  /**
   * 将 Bill 对象转换为数据库值桶（ValueBucket）
   * 处理 Bill 接口字段名与数据库列名之间的映射
   * @param bill 账单对象
   * @returns 数据库值桶对象
   */
  private billToValueBucket(bill: Bill): relationalStore.ValuesBucket {
    const valueBucket: relationalStore.ValuesBucket = {}
    valueBucket[COL_ID] = bill.id
    valueBucket[COL_TYPE] = bill.type
    valueBucket[COL_AMOUNT] = bill.amount
    valueBucket[COL_CATEGORY] = bill.category
    valueBucket[COL_REMARK] = bill.description  // Bill.description 对应数据库 remark 列
    valueBucket[COL_DATE] = bill.date
    valueBucket[COL_CREATE_TIME] = bill.createdAt
    valueBucket[COL_UPDATE_TIME] = bill.updatedAt
    return valueBucket
  }

  /**
   * 将数据库结果集中的当前行转换为 Bill 对象
   * @param resultSet 数据库结果集
   * @returns Bill 对象
   */
  private resultSetToBill(resultSet: relationalStore.ResultSet): Bill {
    return {
      id: resultSet.getString(resultSet.getColumnIndex(COL_ID)),
      type: resultSet.getLong(resultSet.getColumnIndex(COL_TYPE)) as BillType,
      amount: resultSet.getDouble(resultSet.getColumnIndex(COL_AMOUNT)),
      category: resultSet.getString(resultSet.getColumnIndex(COL_CATEGORY)),
      description: resultSet.getString(resultSet.getColumnIndex(COL_REMARK)),
      date: resultSet.getString(resultSet.getColumnIndex(COL_DATE)),
      createdAt: resultSet.getString(resultSet.getColumnIndex(COL_CREATE_TIME)),
      updatedAt: resultSet.getString(resultSet.getColumnIndex(COL_UPDATE_TIME))
    }
  }

  /**
   * 获取当前时间的字符串表示
   * 格式: YYYY-MM-DD HH:mm:ss
   * @returns 格式化的时间字符串
   */
  private getCurrentTime(): string {
    const now = new Date()
    const year = now.getFullYear()
    const month = String(now.getMonth() + 1).padStart(2, '0')
    const day = String(now.getDate()).padStart(2, '0')
    const hours = String(now.getHours()).padStart(2, '0')
    const minutes = String(now.getMinutes()).padStart(2, '0')
    const seconds = String(now.getSeconds()).padStart(2, '0')
    return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`
  }

  /**
   * 获取今天的日期字符串
   * 格式: YYYY-MM-DD
   * @returns 今天的日期字符串
   */
  private getTodayDate(): string {
    const now = new Date()
    const year = now.getFullYear()
    const month = String(now.getMonth() + 1).padStart(2, '0')
    const day = String(now.getDate()).padStart(2, '0')
    return `${year}-${month}-${day}`
  }

  /**
   * 获取当前月份字符串
   * 格式: YYYY-MM
   * @returns 当前月份字符串
   */
  private getCurrentMonth(): string {
    const now = new Date()
    const year = now.getFullYear()
    const month = String(now.getMonth() + 1).padStart(2, '0')
    return `${year}-${month}`
  }

  // ==================== 增删改查操作 ====================

  /**
   * 插入一条账单记录
   * @param bill 账单对象，id、createdAt、updatedAt 如未提供将自动生成
   * @returns 插入成功后的账单对象（含自动生成的字段）
   */
  async insertBill(bill: Bill): Promise<Bill> {
    const store = this.getStore()

    // 自动生成缺失字段
    const currentTime = this.getCurrentTime()
    const newBill: Bill = {
      id: bill.id || `${Date.now()}_${Math.random().toString(36).substring(2, 9)}`,
      amount: bill.amount,
      type: bill.type,
      category: bill.category,
      description: bill.description,
      date: bill.date,
      createdAt: bill.createdAt || currentTime,
      updatedAt: bill.updatedAt || currentTime
    }

    try {
      const valueBucket = this.billToValueBucket(newBill)
      const rowId: number = await store.insert(TABLE_BILLS, valueBucket)

      if (rowId === -1) {
        throw new Error('插入账单失败，返回的 rowId 为 -1')
      }

      console.info('DatabaseHelper', `账单插入成功，id: ${newBill.id}`)
      return newBill
    } catch (err) {
      console.error('DatabaseHelper', `插入账单失败: ${err}`)
      throw new Error(`插入账单失败: ${err}`)
    }
  }

  /**
   * 更新一条账单记录
   * 根据账单 id 进行更新，自动更新 updatedAt 字段
   * @param bill 账单对象（必须包含 id 字段）
   * @returns 是否更新成功
   */
  async updateBill(bill: Bill): Promise<boolean> {
    const store = this.getStore()

    if (!bill.id) {
      throw new Error('更新账单失败：缺少账单 id')
    }

    try {
      // 自动更新修改时间
      const updateBill: Bill = {
        id: bill.id,
        amount: bill.amount,
        type: bill.type,
        category: bill.category,
        description: bill.description,
        date: bill.date,
        createdAt: bill.createdAt,
        updatedAt: this.getCurrentTime()
      }

      const valueBucket = this.billToValueBucket(updateBill)

      // 创建查询条件：WHERE id = ?
      const predicates = new relationalStore.RdbPredicates(TABLE_BILLS)
      predicates.equalTo(COL_ID, bill.id)

      const changedRows = await store.update(valueBucket, predicates)

      console.info('DatabaseHelper', `账单更新成功，id: ${bill.id}，影响行数: ${changedRows}`)
      return changedRows > 0
    } catch (err) {
      console.error('DatabaseHelper', `更新账单失败: ${err}`)
      throw new Error(`更新账单失败: ${err}`)
    }
  }

  /**
   * 根据 id 删除一条账单记录
   * @param id 账单唯一标识
   * @returns 是否删除成功
   */
  async deleteBill(id: string): Promise<boolean> {
    const store = this.getStore()

    try {
      // 创建删除条件：WHERE id = ?
      const predicates = new relationalStore.RdbPredicates(TABLE_BILLS)
      predicates.equalTo(COL_ID, id)

      const deletedRows = await store.delete(predicates)

      console.info('DatabaseHelper', `账单删除成功，id: ${id}，影响行数: ${deletedRows}`)
      return deletedRows > 0
    } catch (err) {
      console.error('DatabaseHelper', `删除账单失败: ${err}`)
      throw new Error(`删除账单失败: ${err}`)
    }
  }

  // ==================== 查询操作 ====================

  /**
   * 查询账单列表
   * 支持按月份筛选，不传参数则查询全部
   * @param month 可选，月份字符串（格式: YYYY-MM），如 '2024-06'
   * @returns 账单数组，按日期降序排列
   */
  async queryBills(month?: string): Promise<Bill[]> {
    const store = this.getStore()
    const bills: Bill[] = []

    try {
      // 构建查询条件
      const predicates = new relationalStore.RdbPredicates(TABLE_BILLS)

      // 如果指定了月份，使用 LIKE 进行模糊匹配（YYYY-MM%）
      if (month && month.trim() !== '') {
        predicates.like(COL_DATE, `${month}%`)
      }

      // 按日期降序排列
      predicates.orderByDesc(COL_DATE)

      // 执行查询
      const resultSet = await store.query(predicates, [
        COL_ID, COL_TYPE, COL_AMOUNT, COL_CATEGORY,
        COL_REMARK, COL_DATE, COL_CREATE_TIME, COL_UPDATE_TIME
      ])

      // 遍历结果集，转换为 Bill 对象数组
      if (resultSet.rowCount > 0) {
        while (resultSet.goToNextRow()) {
          bills.push(this.resultSetToBill(resultSet))
        }
      }

      // 释放结果集资源
      resultSet.close()

      console.info('DatabaseHelper', `查询账单完成，月份: ${month || '全部'}，数量: ${bills.length}`)
      return bills
    } catch (err) {
      console.error('DatabaseHelper', `查询账单失败: ${err}`)
      throw new Error(`查询账单失败: ${err}`)
    }
  }

  /**
   * 按日期范围查询账单
   * @param startDate 开始日期（格式: YYYY-MM-DD）
   * @param endDate 结束日期（格式: YYYY-MM-DD）
   * @returns 指定日期范围内的账单数组，按日期降序排列
   */
  async queryBillsByDateRange(startDate: string, endDate: string): Promise<Bill[]> {
    const store = this.getStore()
    const bills: Bill[] = []

    try {
      // 构建查询条件：WHERE date BETWEEN startDate AND endDate
      const predicates = new relationalStore.RdbPredicates(TABLE_BILLS)
      predicates.between(COL_DATE, startDate, endDate)
      predicates.orderByDesc(COL_DATE)

      // 执行查询
      const resultSet = await store.query(predicates, [
        COL_ID, COL_TYPE, COL_AMOUNT, COL_CATEGORY,
        COL_REMARK, COL_DATE, COL_CREATE_TIME, COL_UPDATE_TIME
      ])

      // 遍历结果集
      if (resultSet.rowCount > 0) {
        while (resultSet.goToNextRow()) {
          bills.push(this.resultSetToBill(resultSet))
        }
      }

      resultSet.close()

      console.info('DatabaseHelper', `按日期范围查询完成，${startDate} ~ ${endDate}，数量: ${bills.length}`)
      return bills
    } catch (err) {
      console.error('DatabaseHelper', `按日期范围查询失败: ${err}`)
      throw new Error(`按日期范围查询失败: ${err}`)
    }
  }

  /**
   * 查询统计数据
   * 按分类分组统计金额和数量，用于生成统计图表
   * @param type 账单类型（BillType.EXPENSE 或 BillType.INCOME）
   * @param startDate 开始日期（格式: YYYY-MM-DD）
   * @param endDate 结束日期（格式: YYYY-MM-DD）
   * @returns 统计结果数组，按总金额降序排列
   */
  async queryStatistics(type: BillType, startDate: string, endDate: string): Promise<StatisticsResult[]> {
    const store = this.getStore()
    const results: StatisticsResult[] = []

    try {
      // 使用原生 SQL 实现分组统计查询
      // SELECT category, SUM(amount) as total, COUNT(*) as count
      // FROM bills
      // WHERE type = ? AND date BETWEEN ? AND ?
      // GROUP BY category
      // ORDER BY total DESC
      const sql = `SELECT ${COL_CATEGORY},
                          SUM(${COL_AMOUNT}) as total,
                          COUNT(*) as count
                   FROM ${TABLE_BILLS}
                   WHERE ${COL_TYPE} = ? AND ${COL_DATE} BETWEEN ? AND ?
                   GROUP BY ${COL_CATEGORY}
                   ORDER BY total DESC`

      const resultSet = await store.querySql(sql, [type, startDate, endDate])

      // 遍历结果集，构建统计数据
      if (resultSet.rowCount > 0) {
        while (resultSet.goToNextRow()) {
          results.push({
            category: resultSet.getString(resultSet.getColumnIndex(COL_CATEGORY)),
            total: resultSet.getDouble(resultSet.getColumnIndex('total')),
            count: resultSet.getLong(resultSet.getColumnIndex('count'))
          })
        }
      }

      resultSet.close()

      const typeName = type === BillType.EXPENSE ? '支出' : '收入'
      console.info('DatabaseHelper', `查询${typeName}统计完成，${startDate} ~ ${endDate}，分类数: ${results.length}`)
      return results
    } catch (err) {
      console.error('DatabaseHelper', `查询统计数据失败: ${err}`)
      throw new Error(`查询统计数据失败: ${err}`)
    }
  }

  // ==================== 汇总统计 ====================

  /**
   * 获取今日收支汇总
   * 统计今天的收入总额、支出总额和结余
   * @returns 今日收支汇总对象
   */
  async getTodaySummary(): Promise<SummaryResult> {
    const today = this.getTodayDate()
    return this.getSummaryByDate(today, today)
  }

  /**
   * 获取本月收支汇总
   * 统计本月的收入总额、支出总额和结余
   * @returns 本月收支汇总对象
   */
  async getMonthSummary(): Promise<SummaryResult> {
    const store = this.getStore()
    const currentMonth = this.getCurrentMonth()

    try {
      // 使用原生 SQL 按类型分组统计本月数据
      const sql = `SELECT ${COL_TYPE},
                          SUM(${COL_AMOUNT}) as total,
                          COUNT(*) as count
                   FROM ${TABLE_BILLS}
                   WHERE ${COL_DATE} LIKE ?
                   GROUP BY ${COL_TYPE}`

      const resultSet = await store.querySql(sql, [`${currentMonth}%`])

      // 初始化汇总数据
      const summary: SummaryResult = {
        totalExpense: 0,
        totalIncome: 0,
        balance: 0,
        expenseCount: 0,
        incomeCount: 0
      }

      // 遍历结果，分别累加支出和收入
      if (resultSet.rowCount > 0) {
        while (resultSet.goToNextRow()) {
          const type = resultSet.getLong(resultSet.getColumnIndex(COL_TYPE))
          const total = resultSet.getDouble(resultSet.getColumnIndex('total'))
          const count = resultSet.getLong(resultSet.getColumnIndex('count'))

          if (type === BillType.EXPENSE) {
            summary.totalExpense = total
            summary.expenseCount = count
          } else if (type === BillType.INCOME) {
            summary.totalIncome = total
            summary.incomeCount = count
          }
        }
      }

      resultSet.close()

      // 计算结余
      summary.balance = summary.totalIncome - summary.totalExpense

      console.info('DatabaseHelper', `本月汇总查询完成: 收入=${summary.totalIncome}, 支出=${summary.totalExpense}, 结余=${summary.balance}`)
      return summary
    } catch (err) {
      console.error('DatabaseHelper', `获取本月汇总失败: ${err}`)
      throw new Error(`获取本月汇总失败: ${err}`)
    }
  }

  /**
   * 根据日期范围获取收支汇总（内部方法）
   * @param startDate 开始日期
   * @param endDate 结束日期
   * @returns 收支汇总对象
   */
  private async getSummaryByDate(startDate: string, endDate: string): Promise<SummaryResult> {
    const store = this.getStore()

    try {
      // 使用原生 SQL 按类型分组统计指定日期范围的数据
      const sql = `SELECT ${COL_TYPE},
                          SUM(${COL_AMOUNT}) as total,
                          COUNT(*) as count
                   FROM ${TABLE_BILLS}
                   WHERE ${COL_DATE} BETWEEN ? AND ?
                   GROUP BY ${COL_TYPE}`

      const resultSet = await store.querySql(sql, [startDate, endDate])

      // 初始化汇总数据
      const summary: SummaryResult = {
        totalExpense: 0,
        totalIncome: 0,
        balance: 0,
        expenseCount: 0,
        incomeCount: 0
      }

      // 遍历结果，分别累加支出和收入
      if (resultSet.rowCount > 0) {
        while (resultSet.goToNextRow()) {
          const type = resultSet.getLong(resultSet.getColumnIndex(COL_TYPE))
          const total = resultSet.getDouble(resultSet.getColumnIndex('total'))
          const count = resultSet.getLong(resultSet.getColumnIndex('count'))

          if (type === BillType.EXPENSE) {
            summary.totalExpense = total
            summary.expenseCount = count
          } else if (type === BillType.INCOME) {
            summary.totalIncome = total
            summary.incomeCount = count
          }
        }
      }

      resultSet.close()

      // 计算结余
      summary.balance = summary.totalIncome - summary.totalExpense

      return summary
    } catch (err) {
      console.error('DatabaseHelper', `获取日期范围汇总失败: ${err}`)
      throw new Error(`获取日期范围汇总失败: ${err}`)
    }
  }
}
