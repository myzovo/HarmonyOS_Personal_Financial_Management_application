/**
 * 文件导出工具类
 * 使用 @kit.CoreFileKit 的文件访问 API
 * 提供账单数据导出为 JSON 和 CSV 格式的能力
 */

import { fileIo } from '@kit.CoreFileKit'
import { Bill, BillType } from '../model/Bill'
import { common } from '@kit.AbilityKit'

/**
 * 获取当前时间戳字符串
 * 格式: YYYYMMDD_HHmmss
 * @returns 格式化的时间戳字符串
 */
function getTimestamp(): string {
  const now = new Date()
  const year = now.getFullYear()
  const month = String(now.getMonth() + 1).padStart(2, '0')
  const day = String(now.getDate()).padStart(2, '0')
  const hours = String(now.getHours()).padStart(2, '0')
  const minutes = String(now.getMinutes()).padStart(2, '0')
  const seconds = String(now.getSeconds()).padStart(2, '0')
  return `${year}${month}${day}_${hours}${minutes}${seconds}`
}

/**
 * 获取账单类型的中文名称
 * @param type 账单类型枚举值
 * @returns 对应的中文名称
 */
function getBillTypeName(type: BillType): string {
  return type === BillType.EXPENSE ? '支出' : '收入'
}

/**
 * 转义 CSV 字段中的特殊字符
 * 如果字段包含逗号、引号或换行符，则用双引号包裹
 * @param field 原始字段值
 * @returns 转义后的字段值
 */
function escapeCSVField(field: string): string {
  if (!field) {
    return ''
  }

  // 检查是否需要转义
  if (field.includes(',') || field.includes('"') || field.includes('\n')) {
    // 将双引号替换为两个双引号
    const escapedField = field.replace(/"/g, '""')
    return `"${escapedField}"`
  }

  return field
}

/**
 * 文件导出工具类
 * 提供将账单数据导出为 JSON 和 CSV 文件的功能
 */
export class FileUtils {
  /**
   * 将账单数据导出为 JSON 文件
   * @param bills 账单数据数组
   * @returns Promise<string> 导出文件的完整路径
   * @throws Error 导出失败时抛出异常
   */
  static async exportToJSON(bills: Bill[]): Promise<string> {
    try {
      // 生成文件名
      const timestamp = getTimestamp()
      const fileName = `ledger_export_${timestamp}.json`

      // 构建完整的文件保存路径（公共下载目录）
      const downloadDir = '/data/storage/el2/base/downloads'
      const filePath = `${downloadDir}/${fileName}`

      // 将账单数据转换为格式化的 JSON 字符串
      const jsonData = JSON.stringify(bills, null, 2)

      // 使用 fileIo 写入文件
      const file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY)
      fileIo.writeSync(file.fd, jsonData)
      fileIo.closeSync(file)

      console.info('FileUtils', `JSON 文件导出成功: ${filePath}`)
      return filePath
    } catch (err) {
      console.error('FileUtils', `导出 JSON 文件失败: ${err}`)
      throw new Error(`导出 JSON 文件失败: ${err}`)
    }
  }

  /**
   * 将账单数据导出为 CSV 文件
   * CSV 格式包含表头：ID,金额,类型,分类,描述,日期
   * @param bills 账单数据数组
   * @returns Promise<string> 导出文件的完整路径
   * @throws Error 导出失败时抛出异常
   */
  static async exportToCSV(bills: Bill[]): Promise<string> {
    try {
      // 生成文件名
      const timestamp = getTimestamp()
      const fileName = `ledger_export_${timestamp}.csv`

      // 构建完整的文件保存路径（公共下载目录）
      const downloadDir = '/data/storage/el2/base/downloads'
      const filePath = `${downloadDir}/${fileName}`

      // 构建 CSV 内容
      // 添加 BOM 头以确保 Excel 正确识别中文编码
      const BOM = '﻿'

      // CSV 表头
      const header = 'ID,金额,类型,分类,描述,日期'

      // 将账单数据转换为 CSV 行
      const rows = bills.map(bill => {
        // 处理字段中的特殊字符（逗号、引号、换行符）
        const id = escapeCSVField(bill.id)
        const amount = bill.amount.toFixed(2)
        const type = getBillTypeName(bill.type)
        const category = escapeCSVField(bill.category)
        const description = escapeCSVField(bill.description)
        const date = bill.date

        return `${id},${amount},${type},${category},${description},${date}`
      })

      // 组合完整的 CSV 内容
      const csvContent = BOM + header + '\n' + rows.join('\n')

      // 使用 fileIo 写入文件
      const file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY)
      fileIo.writeSync(file.fd, csvContent)
      fileIo.closeSync(file)

      console.info('FileUtils', `CSV 文件导出成功: ${filePath}`)
      return filePath
    } catch (err) {
      console.error('FileUtils', `导出 CSV 文件失败: ${err}`)
      throw new Error(`导出 CSV 文件失败: ${err}`)
    }
  }
}
