/**
 * Export.ets
 * 数据导出页面
 * 支持按范围筛选账单数据，导出为 JSON 或 CSV 格式
 * 导出前显示预览（账单数量），导出后显示结果提示和导出历史
 */

import { router } from '@kit.ArkUI'
import { promptAction } from '@kit.ArkUI'
import { Bill } from '../model/Bill'
import { DatabaseHelper } from '../utils/DatabaseHelper'
import { FileUtils } from '../utils/FileUtils'
import { getMonthStart, getMonthEnd, formatDate } from '../utils/DateUtils'
import { ThemeColors } from '../utils/ThemeColors'

/**
 * 导出范围枚举
 * MONTH: 本月账单
 * YEAR: 本年账单
 * ALL: 全部账单
 * CUSTOM: 自定义日期范围
 */
enum ExportRange {
  MONTH = 0,
  YEAR = 1,
  ALL = 2,
  CUSTOM = 3
}

/**
 * 导出格式枚举
 * JSON: JSON 格式
 * CSV: CSV 格式
 */
enum ExportFormat {
  JSON = 0,
  CSV = 1
}

/**
 * 导出历史记录接口
 * 记录每次导出的时间、格式、数量和文件路径
 */
interface ExportHistoryItem {
  /** 导出时间 */
  time: string
  /** 导出格式 */
  format: string
  /** 导出账单数量 */
  count: number
  /** 文件路径 */
  filePath: string
}

@Entry
@Component
struct Export {
  // ==================== 导出范围状态 ====================

  /** 当前选中的导出范围 */
  @State selectedRange: ExportRange = ExportRange.MONTH

  /** 自定义开始日期（YYYY-MM-DD 格式） */
  @State customStartDate: string = ''

  /** 自定义结束日期（YYYY-MM-DD 格式） */
  @State customEndDate: string = ''

  /** 自定义开始日期选择器临时值 */
  @State startDatePickerYear: number = new Date().getFullYear()
  @State startDatePickerMonth: number = new Date().getMonth() + 1
  @State startDatePickerDay: number = 1

  /** 自定义结束日期选择器临时值 */
  @State endDatePickerYear: number = new Date().getFullYear()
  @State endDatePickerMonth: number = new Date().getMonth() + 1
  @State endDatePickerDay: number = new Date().getDate()

  /** 开始日期选择弹窗是否显示 */
  @State showStartDatePicker: boolean = false

  /** 结束日期选择弹窗是否显示 */
  @State showEndDatePicker: boolean = false

  // ==================== 导出格式状态 ====================

  /** 当前选中的导出格式 */
  @State selectedFormat: ExportFormat = ExportFormat.JSON

  // ==================== 预览和导出状态 ====================

  /** 预览的账单数量 */
  @State previewCount: number = -1

  /** 是否正在加载预览 */
  @State isLoadingPreview: boolean = false

  /** 是否正在导出 */
  @State isExporting: boolean = false

  /** 导出结果：成功时为文件路径，失败时为空 */
  @State exportFilePath: string = ''

  /** 导出结果：文件大小 */
  @State exportFileSize: string = ''

  /** 导出结果：错误信息 */
  @State exportError: string = ''

  /** 是否已显示导出结果 */
  @State hasExportResult: boolean = false

  /** 导出是否成功 */
  @State exportSuccess: boolean = false

  // ==================== 导出历史 ====================

  /** 导出历史记录列表 */
  @State exportHistory: ExportHistoryItem[] = []

  // ==================== 数据库实例 ====================

  /** 数据库操作单例 */
  private db: DatabaseHelper = DatabaseHelper.getInstance()

  // ==================== 生命周期 ====================

  /**
   * 页面即将显示时触发
   * 初始化默认日期并加载预览
   */
  aboutToAppear(): void {
    // 初始化自定义日期范围为本月
    this.customStartDate = getMonthStart()
    this.customEndDate = getMonthEnd()
    this.initStartDatePicker(this.customStartDate)
    this.initEndDatePicker(this.customEndDate)

    // 加载预览
    this.loadPreview()
  }

  // ==================== 预览加载 ====================

  /**
   * 根据当前选中的范围加载账单预览数量
   * 查询数据库获取符合条件的账单条数
   */
  async loadPreview(): Promise<void> {
    this.isLoadingPreview = true
    this.previewCount = -1

    try {
      let bills: Bill[] = []

      switch (this.selectedRange) {
        case ExportRange.MONTH:
          // 本月账单：使用当前月份查询
          bills = await this.db.queryBills(this.getCurrentMonth())
          break

        case ExportRange.YEAR:
          // 本年账单：使用日期范围查询（1月1日到12月31日）
          bills = await this.db.queryBillsByDateRange(
            this.getYearStart(),
            this.getYearEnd()
          )
          break

        case ExportRange.ALL:
          // 全部账单：不传参数查询全部
          bills = await this.db.queryBills()
          break

        case ExportRange.CUSTOM:
          // 自定义日期范围
          if (this.customStartDate && this.customEndDate) {
            bills = await this.db.queryBillsByDateRange(
              this.customStartDate,
              this.customEndDate
            )
          }
          break
      }

      this.previewCount = bills.length
      console.info('Export', `预览加载完成，共 ${bills.length} 条账单`)
    } catch (err) {
      console.error('Export', `加载预览失败: ${err}`)
      this.previewCount = 0
      promptAction.showToast({ message: '加载预览失败', duration: 2000 })
    } finally {
      this.isLoadingPreview = false
    }
  }

  // ==================== 导出操作 ====================

  /**
   * 执行数据导出
   * 根据选中的范围查询账单数据，调用 FileUtils 导出为指定格式
   */
  async exportData(): Promise<void> {
    // 防止重复导出
    if (this.isExporting) {
      return
    }

    // 重置导出结果
    this.hasExportResult = false
    this.exportFilePath = ''
    this.exportFileSize = ''
    this.exportError = ''
    this.exportSuccess = false

    this.isExporting = true

    try {
      // 查询账单数据
      let bills: Bill[] = []

      switch (this.selectedRange) {
        case ExportRange.MONTH:
          bills = await this.db.queryBills(this.getCurrentMonth())
          break

        case ExportRange.YEAR:
          bills = await this.db.queryBillsByDateRange(
            this.getYearStart(),
            this.getYearEnd()
          )
          break

        case ExportRange.ALL:
          bills = await this.db.queryBills()
          break

        case ExportRange.CUSTOM:
          if (this.customStartDate && this.customEndDate) {
            bills = await this.db.queryBillsByDateRange(
              this.customStartDate,
              this.customEndDate
            )
          }
          break
      }

      // 检查是否有数据可导出
      if (bills.length === 0) {
        promptAction.showToast({ message: '没有可导出的账单数据', duration: 2000 })
        this.isExporting = false
        return
      }

      // 根据格式调用对应的导出方法
      let filePath: string = ''
      if (this.selectedFormat === ExportFormat.JSON) {
        filePath = await FileUtils.exportToJSON(bills)
      } else {
        filePath = await FileUtils.exportToCSV(bills)
      }

      // 导出成功，计算文件大小（通过文件路径估算）
      const fileSize: string = this.estimateFileSize(bills.length, this.selectedFormat)

      // 更新导出结果状态
      this.exportFilePath = filePath
      this.exportFileSize = fileSize
      this.hasExportResult = true
      this.exportSuccess = true

      // 添加到导出历史
      this.addExportHistory(filePath, bills.length)

      promptAction.showToast({ message: '导出成功', duration: 2000 })
      console.info('Export', `导出成功: ${filePath}`)
    } catch (err) {
      // 导出失败
      this.exportError = `导出失败: ${err}`
      this.hasExportResult = true
      this.exportSuccess = false

      promptAction.showToast({ message: '导出失败', duration: 2000 })
      console.error('Export', `导出失败: ${err}`)
    } finally {
      this.isExporting = false
    }
  }

  // ==================== 导出历史 ====================

  /**
   * 添加一条导出历史记录
   * @param filePath 导出文件路径
   * @param count 导出账单数量
   */
  addExportHistory(filePath: string, count: number): void {
    const now: Date = new Date()
    const timeStr: string = formatDate(now, 'YYYY-MM-DD HH:mm:ss')
    const formatStr: string = this.selectedFormat === ExportFormat.JSON ? 'JSON' : 'CSV'

    const item: ExportHistoryItem = {
      time: timeStr,
      format: formatStr,
      count: count,
      filePath: filePath
    }

    // 新记录插入到列表头部
    this.exportHistory = [item, ...this.exportHistory]

    // 最多保留 10 条历史记录
    if (this.exportHistory.length > 10) {
      this.exportHistory = this.exportHistory.slice(0, 10)
    }
  }

  // ==================== 日期相关工具方法 ====================

  /**
   * 获取当前月份字符串
   * @returns 格式 YYYY-MM
   */
  private getCurrentMonth(): string {
    const now: Date = new Date()
    const year: number = now.getFullYear()
    const month: string = (now.getMonth() + 1) < 10
      ? `0${now.getMonth() + 1}`
      : `${now.getMonth() + 1}`
    return `${year}-${month}`
  }

  /**
   * 获取本年开始日期
   * @returns 格式 YYYY-MM-DD
   */
  private getYearStart(): string {
    const year: number = new Date().getFullYear()
    return `${year}-01-01`
  }

  /**
   * 获取本年结束日期
   * @returns 格式 YYYY-MM-DD
   */
  private getYearEnd(): string {
    const year: number = new Date().getFullYear()
    return `${year}-12-31`
  }

  /**
   * 获取当前选中范围的描述文本
   * @returns 范围描述字符串
   */
  private getRangeText(): string {
    switch (this.selectedRange) {
      case ExportRange.MONTH:
        return '本月账单'
      case ExportRange.YEAR:
        return '本年账单'
      case ExportRange.ALL:
        return '全部账单'
      case ExportRange.CUSTOM:
        return `${this.customStartDate} 至 ${this.customEndDate}`
      default:
        return ''
    }
  }

  /**
   * 估算导出文件大小
   * @param count 账单数量
   * @param format 导出格式
   * @returns 估算的文件大小字符串
   */
  private estimateFileSize(count: number, format: ExportFormat): string {
    // 每条账单 JSON 约 200 字节，CSV 约 100 字节
    const bytesPerBill: number = format === ExportFormat.JSON ? 200 : 100
    const totalBytes: number = count * bytesPerBill

    if (totalBytes < 1024) {
      return `${totalBytes} B`
    } else if (totalBytes < 1024 * 1024) {
      return `${(totalBytes / 1024).toFixed(1)} KB`
    } else {
      return `${(totalBytes / (1024 * 1024)).toFixed(1)} MB`
    }
  }

  /**
   * 补零为两位字符串
   * @param num 数字
   * @returns 补零后的字符串
   */
  private padZero(num: number): string {
    return num < 10 ? `0${num}` : `${num}`
  }

  /**
   * 从日期字符串初始化开始日期选择器
   * @param dateStr 日期字符串
   */
  private initStartDatePicker(dateStr: string): void {
    if (dateStr && dateStr.length >= 10) {
      const parts: string[] = dateStr.split('-')
      if (parts.length >= 3) {
        this.startDatePickerYear = parseInt(parts[0], 10)
        this.startDatePickerMonth = parseInt(parts[1], 10)
        this.startDatePickerDay = parseInt(parts[2], 10)
      }
    }
  }

  /**
   * 从日期字符串初始化结束日期选择器
   * @param dateStr 日期字符串
   */
  private initEndDatePicker(dateStr: string): void {
    if (dateStr && dateStr.length >= 10) {
      const parts: string[] = dateStr.split('-')
      if (parts.length >= 3) {
        this.endDatePickerYear = parseInt(parts[0], 10)
        this.endDatePickerMonth = parseInt(parts[1], 10)
        this.endDatePickerDay = parseInt(parts[2], 10)
      }
    }
  }

  // ==================== UI 构建 ====================

  build() {
    Stack() {
      Column() {
        // ===== 顶部导航栏 =====
        this.TopNavBar()

        // ===== 可滚动内容区域 =====
        Scroll() {
          Column() {
            // 导出范围选择
            this.RangeSection()

            // 分割线
            Divider().color('#EEEEEE').margin({ left: 16, right: 16, top: 16, bottom: 16 })

            // 导出格式选择
            this.FormatSection()

            // 分割线
            Divider().color('#EEEEEE').margin({ left: 16, right: 16, top: 16, bottom: 16 })

            // 导出预览
            this.PreviewSection()

            // 导出按钮
            this.ExportButton()

            // 导出结果提示
            if (this.hasExportResult) {
              this.ResultSection()
            }

            // 导出历史记录
            if (this.exportHistory.length > 0) {
              this.HistorySection()
            }
          }
          .width('100%')
          .padding({ bottom: 40 })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(ThemeColors.BG_PAGE)

      // ===== 开始日期选择弹窗 =====
      if (this.showStartDatePicker) {
        this.StartDatePickerDialog()
      }

      // ===== 结束日期选择弹窗 =====
      if (this.showEndDatePicker) {
        this.EndDatePickerDialog()
      }
    }
    .width('100%')
    .height('100%')
  }

  // ==================== 子组件构建方法 ====================

  /**
   * 顶部导航栏
   * 包含返回按钮和页面标题
   */
  @Builder
  TopNavBar() {
    Row() {
      // 返回按钮
      Row() {
        Text('←')
          .fontSize(20)
          .fontColor(ThemeColors.TEXT_NORMAL)
          .fontWeight(FontWeight.Bold)
      }
      .width(44)
      .height(44)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .borderRadius(22)
      .backgroundColor(ThemeColors.BG_SECTION)
      .onClick(() => {
        router.back()
      })

      // 页面标题
      Text('数据导出')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeColors.TEXT_PRIMARY)
        .margin({ left: 12 })

      Blank()
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(ThemeColors.BG_CARD)
    .shadow(ThemeColors.SHADOW_NAV)
  }

  /**
   * 导出范围选择区域
   * 支持本月、本年、全部和自定义日期范围四种选项
   */
  @Builder
  RangeSection() {
    Column() {
      // 区域标题
      Text('导出范围')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(ThemeColors.TEXT_NORMAL)
        .margin({ bottom: 16 })
        .alignSelf(ItemAlign.Start)

      // 本月账单选项
      this.RangeOption(ExportRange.MONTH, '本月账单', this.getRangeDescription(ExportRange.MONTH))

      // 本年账单选项
      this.RangeOption(ExportRange.YEAR, '本年账单', this.getRangeDescription(ExportRange.YEAR))

      // 全部账单选项
      this.RangeOption(ExportRange.ALL, '全部账单', this.getRangeDescription(ExportRange.ALL))

      // 自定义日期范围选项
      this.RangeOption(ExportRange.CUSTOM, '自定义日期范围', '')

      // 自定义日期范围选择器（仅在选中自定义时显示）
      if (this.selectedRange === ExportRange.CUSTOM) {
        this.CustomDateRangePicker()
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 20 })
    .backgroundColor(ThemeColors.BG_CARD)
  }

  /**
   * 范围选项构建器
   * @param range 范围枚举值
   * @param title 选项标题
   * @param desc 选项描述
   */
  @Builder
  RangeOption(range: ExportRange, title: string, desc: string) {
    Row() {
      // 左侧：选中指示器和文本
      Row() {
        // 选中指示器（圆形单选框）
        Column() {
          if (this.selectedRange === range) {
            Column()
              .width(10)
              .height(10)
              .borderRadius(5)
              .backgroundColor(ThemeColors.PRIMARY)
          }
        }
        .width(20)
        .height(20)
        .borderRadius(10)
        .borderWidth(2)
        .borderColor(this.selectedRange === range ? ThemeColors.PRIMARY : ThemeColors.TEXT_DISABLED)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        // 标题文本
        Column() {
          Text(title)
            .fontSize(15)
            .fontColor(ThemeColors.TEXT_NORMAL)

          // 描述文本（如果有）
          if (desc.length > 0) {
            Text(desc)
              .fontSize(12)
              .fontColor(ThemeColors.TEXT_PLACEHOLDER)
              .margin({ top: 2 })
          }
        }
        .margin({ left: 12 })
        .alignItems(HorizontalAlign.Start)
      }
      .alignItems(VerticalAlign.Center)

      Blank()
    }
    .width('100%')
    .height(desc.length > 0 ? 56 : 48)
    .onClick(() => {
      this.selectedRange = range
      // 切换范围后重新加载预览
      this.loadPreview()
    })
  }

  /**
   * 自定义日期范围选择器
   * 包含开始日期和结束日期的选择
   */
  @Builder
  CustomDateRangePicker() {
    Column() {
      // 开始日期
      Row() {
        Text('开始日期')
          .fontSize(14)
          .fontColor(ThemeColors.TEXT_SECONDARY)

        Blank()

        Text(this.customStartDate.length > 0 ? this.customStartDate : '请选择')
          .fontSize(14)
          .fontColor(this.customStartDate.length > 0 ? ThemeColors.TEXT_NORMAL : ThemeColors.TEXT_DISABLED)
      }
      .width('100%')
      .height(44)
      .onClick(() => {
        if (this.customStartDate.length > 0) {
          this.initStartDatePicker(this.customStartDate)
        }
        this.showStartDatePicker = true
      })

      // 分割线
      Divider().color(ThemeColors.BORDER)

      // 结束日期
      Row() {
        Text('结束日期')
          .fontSize(14)
          .fontColor(ThemeColors.TEXT_SECONDARY)

        Blank()

        Text(this.customEndDate.length > 0 ? this.customEndDate : '请选择')
          .fontSize(14)
          .fontColor(this.customEndDate.length > 0 ? ThemeColors.TEXT_NORMAL : ThemeColors.TEXT_DISABLED)
      }
      .width('100%')
      .height(44)
      .onClick(() => {
        if (this.customEndDate.length > 0) {
          this.initEndDatePicker(this.customEndDate)
        }
        this.showEndDatePicker = true
      })
    }
    .width('100%')
    .padding({ left: 32, right: 0, top: 8, bottom: 8 })
    .backgroundColor(ThemeColors.BG_SECTION)
    .borderRadius(8)
    .margin({ top: 8 })
  }

  /**
   * 导出格式选择区域
   * 支持 JSON 和 CSV 两种格式
   */
  @Builder
  FormatSection() {
    Column() {
      // 区域标题
      Text('导出格式')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(ThemeColors.TEXT_NORMAL)
        .margin({ bottom: 16 })
        .alignSelf(ItemAlign.Start)

      // 格式选项行
      Row() {
        // JSON 格式选项
        this.FormatOption(ExportFormat.JSON, 'JSON', '结构化数据，便于程序处理')

        // 间距
        Column().width(12)

        // CSV 格式选项
        this.FormatOption(ExportFormat.CSV, 'CSV', '表格数据，可用 Excel 打开')
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 20 })
    .backgroundColor(ThemeColors.BG_CARD)
  }

  /**
   * 格式选项构建器
   * @param format 格式枚举值
   * @param title 格式标题
   * @param desc 格式描述
   */
  @Builder
  FormatOption(format: ExportFormat, title: string, desc: string) {
    Column() {
      // 格式标题
      Text(title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.selectedFormat === format ? ThemeColors.PRIMARY : ThemeColors.TEXT_NORMAL)

      // 格式描述
      Text(desc)
        .fontSize(12)
        .fontColor(ThemeColors.TEXT_PLACEHOLDER)
        .margin({ top: 4 })
        .textAlign(TextAlign.Center)
    }
    .layoutWeight(1)
    .height(70)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .borderRadius(12)
        .borderWidth(2)
        .borderColor(this.selectedFormat === format ? ThemeColors.PRIMARY : ThemeColors.BORDER)
        .backgroundColor(this.selectedFormat === format ? ThemeColors.PRIMARY_LIGHT : ThemeColors.BG_CARD)
        .onClick(() => {
          this.selectedFormat = format
        })
  }

  /**
   * 导出预览区域
   * 显示当前选中范围的账单数量
   */
  @Builder
  PreviewSection() {
    Column() {
      // 区域标题
      Text('导出预览')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(ThemeColors.TEXT_NORMAL)
        .margin({ bottom: 12 })
        .alignSelf(ItemAlign.Start)

      // 预览内容
      Row() {
        // 范围信息
        Column() {
          Text(this.getRangeText())
            .fontSize(14)
            .fontColor(ThemeColors.TEXT_SECONDARY)

          if (this.isLoadingPreview) {
            Text('加载中...')
              .fontSize(13)
              .fontColor(ThemeColors.TEXT_PLACEHOLDER)
              .margin({ top: 4 })
          } else if (this.previewCount >= 0) {
            Text(`共 ${this.previewCount} 条账单`)
              .fontSize(13)
              .fontColor(ThemeColors.PRIMARY)
              .margin({ top: 4 })
          }
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        // 刷新按钮
        Text('刷新')
          .fontSize(13)
          .fontColor(ThemeColors.PRIMARY)
          .onClick(() => {
            this.loadPreview()
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 20 })
    .backgroundColor(ThemeColors.BG_CARD)
  }

  /**
   * 导出按钮
   * 点击执行数据导出操作
   */
  @Builder
  ExportButton() {
    Button(this.isExporting ? '导出中...' : '导出数据')
      .width('90%')
      .height(50)
      .fontSize(17)
      .fontWeight(FontWeight.Bold)
      .fontColor('#FFFFFF')
      .backgroundColor(this.isExporting ? '#B0C4DE' : ThemeColors.PRIMARY)
      .borderRadius(25)
      .margin({ top: 24 })
      .enabled(!this.isExporting && this.previewCount > 0)
      .shadow(ThemeColors.SHADOW_BUTTON)
      .onClick(() => {
        this.exportData()
      })
  }

  /**
   * 导出结果提示区域
   * 成功时显示文件路径和大小，失败时显示错误信息
   */
  @Builder
  ResultSection() {
    Column() {
      // 区域标题
      Text('导出结果')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(ThemeColors.TEXT_NORMAL)
        .margin({ bottom: 12 })
        .alignSelf(ItemAlign.Start)

      if (this.exportSuccess) {
        // 导出成功提示
        Column() {
          // 成功图标和文字
          Row() {
            Text('导出成功')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(ThemeColors.SUCCESS)
          }
          .width('100%')
          .margin({ bottom: 12 })

          // 文件路径
          Column() {
            Text('文件路径')
              .fontSize(12)
              .fontColor(ThemeColors.TEXT_PLACEHOLDER)
              .margin({ bottom: 4 })

            Text(this.exportFilePath)
              .fontSize(13)
              .fontColor(ThemeColors.TEXT_NORMAL)
              .copyOption(CopyOptions.LocalDevice)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .margin({ bottom: 8 })

          // 文件大小
          Column() {
            Text('文件大小')
              .fontSize(12)
              .fontColor(ThemeColors.TEXT_PLACEHOLDER)
              .margin({ bottom: 4 })

            Text(this.exportFileSize)
              .fontSize(13)
              .fontColor(ThemeColors.TEXT_NORMAL)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .padding(16)
        .backgroundColor(ThemeColors.INCOME_LIGHT)
        .borderRadius(8)
        .borderWidth(1)
        .borderColor('#B7EB8F')
      } else {
        // 导出失败提示
        Column() {
          // 失败图标和文字
          Row() {
            Text('导出失败')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(ThemeColors.ERROR)
          }
          .width('100%')
          .margin({ bottom: 8 })

          // 错误信息
          Text(this.exportError)
            .fontSize(13)
            .fontColor(ThemeColors.TEXT_SECONDARY)
        }
        .width('100%')
        .padding(16)
        .backgroundColor(ThemeColors.EXPENSE_LIGHT)
        .borderRadius(8)
        .borderWidth(1)
        .borderColor('#FFCCC7')
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 20 })
    .backgroundColor(ThemeColors.BG_CARD)
  }

  /**
   * 导出历史记录区域
   * 显示最近的导出记录列表
   */
  @Builder
  HistorySection() {
    Column() {
      // 区域标题
      Row() {
        Text('导出历史')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor(ThemeColors.TEXT_NORMAL)

        Blank()

        Text('最多保留10条')
          .fontSize(12)
          .fontColor(ThemeColors.TEXT_PLACEHOLDER)
      }
      .width('100%')
      .margin({ bottom: 12 })

      // 历史记录列表
      ForEach(this.exportHistory, (item: ExportHistoryItem, index: number) => {
        Column() {
          // 记录头部：时间和格式
          Row() {
            Text(item.time)
              .fontSize(13)
              .fontColor(ThemeColors.TEXT_SECONDARY)

            Blank()

            Text(item.format)
              .fontSize(12)
              .fontColor(ThemeColors.PRIMARY)
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              .backgroundColor(ThemeColors.PRIMARY_LIGHT)
              .borderRadius(4)
          }
          .width('100%')

          // 记录详情：数量和路径
          Row() {
            Text(`${item.count} 条账单`)
              .fontSize(12)
              .fontColor(ThemeColors.TEXT_PLACEHOLDER)

            Blank()

            Text(this.getShortPath(item.filePath))
              .fontSize(12)
              .fontColor(ThemeColors.TEXT_PLACEHOLDER)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
              .textAlign(TextAlign.End)
          }
          .width('100%')
          .margin({ top: 4 })
        }
        .width('100%')
        .padding({ top: 12, bottom: 12 })
        .borderRadius(0)

        // 分割线（最后一条不显示）
        if (index < this.exportHistory.length - 1) {
          Divider().color(ThemeColors.BORDER)
        }
      })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 20 })
    .backgroundColor(ThemeColors.BG_CARD)
  }

  /**
   * 开始日期选择弹窗
   * 点击确认后更新自定义开始日期并重新加载预览
   */
  @Builder
  StartDatePickerDialog() {
    Column() {
      // 弹窗遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(ThemeColors.BG_OVERLAY)
        .position({ x: 0, y: 0 })
        .onClick(() => {
          this.showStartDatePicker = false
        })

      // 日期选择面板
      Column() {
        // 弹窗标题栏
        Row() {
          Text('取消')
            .fontSize(16)
            .fontColor(ThemeColors.TEXT_PLACEHOLDER)
            .onClick(() => {
              this.showStartDatePicker = false
            })

          Blank()

          Text('选择开始日期')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeColors.TEXT_NORMAL)

          Blank()

          Text('确定')
            .fontSize(16)
            .fontColor(ThemeColors.PRIMARY)
            .fontWeight(FontWeight.Bold)
            .onClick(() => {
              const monthStr: string = this.padZero(this.startDatePickerMonth)
              const dayStr: string = this.padZero(this.startDatePickerDay)
              this.customStartDate = `${this.startDatePickerYear}-${monthStr}-${dayStr}`
              this.showStartDatePicker = false
              // 日期变更后重新加载预览
              this.loadPreview()
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 12 })

        // 日期选择器
        DatePicker({
          start: new Date(2020, 0, 1),
          end: new Date(2030, 11, 31),
          selected: new Date(this.startDatePickerYear, this.startDatePickerMonth - 1, this.startDatePickerDay)
        })
          .width('100%')
          .height(260)
          .onChange((value: DatePickerResult) => {
            this.startDatePickerYear = value.year ?? 0
            this.startDatePickerMonth = (value.month ?? 0) + 1
            this.startDatePickerDay = value.day ?? 0
          })
      }
      .width('100%')
      .borderRadius({ topLeft: 16, topRight: 16 })
      .backgroundColor(ThemeColors.BG_CARD)
      .position({ x: 0, y: '100%' })
      .translate({ y: '-100%' })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
  }

  /**
   * 结束日期选择弹窗
   * 点击确认后更新自定义结束日期并重新加载预览
   */
  @Builder
  EndDatePickerDialog() {
    Column() {
      // 弹窗遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(ThemeColors.BG_OVERLAY)
        .position({ x: 0, y: 0 })
        .onClick(() => {
          this.showEndDatePicker = false
        })

      // 日期选择面板
      Column() {
        // 弹窗标题栏
        Row() {
          Text('取消')
            .fontSize(16)
            .fontColor(ThemeColors.TEXT_PLACEHOLDER)
            .onClick(() => {
              this.showEndDatePicker = false
            })

          Blank()

          Text('选择结束日期')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeColors.TEXT_NORMAL)

          Blank()

          Text('确定')
            .fontSize(16)
            .fontColor(ThemeColors.PRIMARY)
            .fontWeight(FontWeight.Bold)
            .onClick(() => {
              const monthStr: string = this.padZero(this.endDatePickerMonth)
              const dayStr: string = this.padZero(this.endDatePickerDay)
              this.customEndDate = `${this.endDatePickerYear}-${monthStr}-${dayStr}`
              this.showEndDatePicker = false
              // 日期变更后重新加载预览
              this.loadPreview()
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 12 })

        // 日期选择器
        DatePicker({
          start: new Date(2020, 0, 1),
          end: new Date(2030, 11, 31),
          selected: new Date(this.endDatePickerYear, this.endDatePickerMonth - 1, this.endDatePickerDay)
        })
          .width('100%')
          .height(260)
          .onChange((value: DatePickerResult) => {
            this.endDatePickerYear = value.year ?? 0
            this.endDatePickerMonth = (value.month ?? 0) + 1
            this.endDatePickerDay = value.day ?? 0
          })
      }
      .width('100%')
      .borderRadius({ topLeft: 16, topRight: 16 })
      .backgroundColor(ThemeColors.BG_CARD)
      .position({ x: 0, y: '100%' })
      .translate({ y: '-100%' })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
  }

  // ==================== 辅助方法 ====================

  /**
   * 获取范围描述文本
   * @param range 范围枚举值
   * @returns 描述文本
   */
  private getRangeDescription(range: ExportRange): string {
    switch (range) {
      case ExportRange.MONTH:
        return this.getCurrentMonth().replace('-', '年') + '月'
      case ExportRange.YEAR:
        return `${new Date().getFullYear()}年全年`
      case ExportRange.ALL:
        return '所有历史账单'
      case ExportRange.CUSTOM:
        return ''
      default:
        return ''
    }
  }

  /**
   * 获取文件路径的简短显示
   * @param fullPath 完整文件路径
   * @returns 简短的文件名
   */
  private getShortPath(fullPath: string): string {
    if (!fullPath) {
      return ''
    }
    const parts: string[] = fullPath.split('/')
    return parts.length > 0 ? parts[parts.length - 1] : fullPath
  }
}
