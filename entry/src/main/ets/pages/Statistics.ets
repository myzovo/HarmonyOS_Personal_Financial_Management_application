/**
 * Statistics.ets
 * 统计图表页面 - 统计分析与数据可视化
 * 功能：按时间范围查看支出/收入饼图、分类排行榜、收支趋势折线图和柱状图
 * 支持本周/本月/自定义时间范围，以及支出统计/收入统计/趋势分析三个 Tab 切换
 */

import { router } from '@kit.ArkUI'
import { promptAction } from '@kit.ArkUI'
import { PieChart, PieDataItem } from '../components/PieChart'
import { LineChart, LineSeries, LineDataPoint } from '../components/LineChart'
import { BarChart, BarSeries, BarDataItem } from '../components/BarChart'
import { DatabaseHelper, StatisticsResult } from '../utils/DatabaseHelper'
import { Bill, BillType } from '../model/Bill'
import {
  getWeekStart,
  getWeekEnd,
  getMonthStart,
  getMonthEnd,
  getLast7Days,
  getDaysInRange,
  formatDate,
  getToday
} from '../utils/DateUtils'
import { getCategoryIcon } from '../utils/Constants'
import { ThemeColors } from '../utils/ThemeColors'

/**
 * 时间范围类型枚举
 * WEEK: 本周
 * MONTH: 本月
 * CUSTOM: 自定义
 */
enum TimeRange {
  WEEK = 0,
  MONTH = 1,
  CUSTOM = 2
}

/**
 * 趋势图表类型枚举
 * LINE: 折线图
 * BAR: 柱状图
 */
enum ChartType {
  LINE = 0,
  BAR = 1
}

/**
 * 饼图配色方案
 * 为各分类分配不同颜色，确保视觉区分度
 */
const PIE_COLORS: string[] = [
  '#FF6384', '#36A2EB', '#FFCE56', '#4BC0C0',
  '#9966FF', '#FF9F40', '#C9CBCF', '#7BC8A4',
  '#E76F51', '#2A9D8F', '#264653', '#F4A261'
]

@Entry
@Component
struct Statistics {
  // ==================== 筛选状态 ====================

  /** 当前选中的时间范围 */
  @State selectedTimeRange: TimeRange = TimeRange.MONTH

  /** 自定义开始日期（YYYY-MM-DD 格式） */
  @State customStartDate: string = getMonthStart()

  /** 自定义结束日期（YYYY-MM-DD 格式） */
  @State customEndDate: string = getToday()

  /** 当前选中的统计 Tab（0-支出统计，1-收入统计，2-趋势分析） */
  @State currentTab: number = 0

  /** 趋势分析图表类型 */
  @State trendChartType: ChartType = ChartType.LINE

  // ==================== 图表数据 ====================

  /** 支出饼图数据 */
  @State expensePieData: PieDataItem[] = []

  /** 收入饼图数据 */
  @State incomePieData: PieDataItem[] = []

  /** 支出分类排行榜数据 */
  @State expenseRanking: StatisticsResult[] = []

  /** 收入分类排行榜数据 */
  @State incomeRanking: StatisticsResult[] = []

  /** 支出总额 */
  @State totalExpense: number = 0

  /** 收入总额 */
  @State totalIncome: number = 0

  /** 近7天趋势折线图数据 */
  @State trendLineSeries: LineSeries[] = []

  /** 本月每日柱状图数据 */
  @State trendBarData: BarDataItem[] = []

  /** 柱状图系列配置 */
  @State trendBarSeries: BarSeries[] = [
    { name: '支出', color: '#FF6384' },
    { name: '收入', color: '#36A2EB' }
  ]

  // ==================== UI 状态 ====================

  /** 数据加载状态 */
  @State isLoading: boolean = false

  /** 自定义日期选择器是否显示（开始日期） */
  @State showStartDatePicker: boolean = false

  /** 自定义日期选择器是否显示（结束日期） */
  @State showEndDatePicker: boolean = false

  // ==================== 数据库实例 ====================

  /** 数据库操作单例 */
  private db: DatabaseHelper = DatabaseHelper.getInstance()

  // ==================== 生命周期 ====================

  /**
   * 页面即将显示时加载数据
   */
  aboutToAppear(): void {
    this.loadAllData()
  }

  /**
   * 页面重新显示时刷新数据
   */
  onShow(): void {
    this.loadAllData()
  }

  // ==================== 数据加载 ====================

  /**
   * 加载所有统计数据
   * 根据当前筛选条件并行加载支出统计、收入统计和趋势数据
   */
  async loadAllData(): Promise<void> {
    this.isLoading = true
    try {
      // 获取当前时间范围的起止日期
      const dateRange: string[] = this.getDateRange()
      const startDate: string = dateRange[0]
      const endDate: string = dateRange[1]

      // 并行加载支出统计和收入统计
      const statsResults = await Promise.all([
        this.db.queryStatistics(BillType.EXPENSE, startDate, endDate),
        this.db.queryStatistics(BillType.INCOME, startDate, endDate)
      ])
      const expenseStats: StatisticsResult[] = statsResults[0]
      const incomeStats: StatisticsResult[] = statsResults[1]

      // 处理支出数据
      this.expenseRanking = expenseStats
      this.expensePieData = this.convertToPieData(expenseStats)
      this.totalExpense = this.calcTotal(expenseStats)

      // 处理收入数据
      this.incomeRanking = incomeStats
      this.incomePieData = this.convertToPieData(incomeStats)
      this.totalIncome = this.calcTotal(incomeStats)

      // 加载趋势数据
      await this.loadTrendData()

      console.info('Statistics', '统计数据加载完成')
    } catch (err) {
      console.error('Statistics', `加载统计数据失败: ${err}`)
      promptAction.showToast({ message: '加载数据失败', duration: 2000 })
    }
    this.isLoading = false
  }

  /**
   * 加载趋势分析数据
   * 根据趋势图表类型加载不同维度的趋势数据
   */
  async loadTrendData(): Promise<void> {
    try {
      if (this.trendChartType === ChartType.LINE) {
        // 折线图：加载近7天收支趋势
        await this.loadLast7DaysTrend()
      } else {
        // 柱状图：加载本月每日收支
        await this.loadMonthDailyTrend()
      }
    } catch (err) {
      console.error('Statistics', `加载趋势数据失败: ${err}`)
    }
  }

  /**
   * 加载近7天收支趋势数据
   * 查询每天的支出和收入总额，生成折线图数据
   */
  async loadLast7DaysTrend(): Promise<void> {
    const days: string[] = getLast7Days()
    const expenseData: LineDataPoint[] = []
    const incomeData: LineDataPoint[] = []

    // 逐天查询收支数据
    for (const day of days) {
      const bills: Bill[] = await this.db.queryBillsByDateRange(day, day)

      let dayExpense: number = 0
      let dayIncome: number = 0

      for (const bill of bills) {
        if (bill.type === BillType.EXPENSE) {
          dayExpense += bill.amount
        } else {
          dayIncome += bill.amount
        }
      }

      expenseData.push({ x: day, y: dayExpense })
      incomeData.push({ x: day, y: dayIncome })
    }

    this.trendLineSeries = [
      { name: '支出', color: '#FF6384', data: expenseData },
      { name: '收入', color: '#36A2EB', data: incomeData }
    ]
  }

  /**
   * 加载本月每日收支数据
   * 查询本月每一天的支出和收入总额，生成柱状图数据
   */
  async loadMonthDailyTrend(): Promise<void> {
    const monthStart: string = getMonthStart()
    const monthEnd: string = getToday()
    const days: string[] = getDaysInRange(monthStart, monthEnd)

    const expenseData: LineDataPoint[] = []
    const incomeData: LineDataPoint[] = []

    // 逐天查询收支数据
    for (const day of days) {
      const bills: Bill[] = await this.db.queryBillsByDateRange(day, day)

      let dayExpense: number = 0
      let dayIncome: number = 0

      for (const bill of bills) {
        if (bill.type === BillType.EXPENSE) {
          dayExpense += bill.amount
        } else {
          dayIncome += bill.amount
        }
      }

      // 格式化日期显示（取 MM-DD 部分）
      const dayLabel: string = day.substring(5)
      expenseData.push({ x: dayLabel, y: dayExpense })
      incomeData.push({ x: dayLabel, y: dayIncome })
    }

    // 设置柱状图数据
    const barItems: BarDataItem[] = []
    for (let i: number = 0; i < expenseData.length; i++) {
      const barItem: BarDataItem = { name: expenseData[i].x, value: expenseData[i].y, color: '#FF6384' }
      barItems.push(barItem)
    }
    this.trendBarData = barItems

    // 设置折线图系列数据
    this.trendLineSeries = [
      { name: '支出', color: '#FF6384', data: expenseData },
      { name: '收入', color: '#36A2EB', data: incomeData }
    ]
  }

  // ==================== 数据转换 ====================

  /**
   * 将 StatisticsResult 数组转换为饼图数据
   * 为每个分类分配颜色
   * @param stats 统计结果数组
   * @returns PieDataItem 数组
   */
  convertToPieData(stats: StatisticsResult[]): PieDataItem[] {
    const result: PieDataItem[] = []
    for (let i: number = 0; i < stats.length; i++) {
      result.push({
        name: stats[i].category,
        value: stats[i].total,
        color: PIE_COLORS[i % PIE_COLORS.length]
      })
    }
    return result
  }

  /**
   * 计算统计结果总额
   * @param stats 统计结果数组
   * @returns 所有分类的金额总和
   */
  calcTotal(stats: StatisticsResult[]): number {
    let total: number = 0
    for (const item of stats) {
      total += item.total
    }
    return total
  }

  // ==================== 时间范围 ====================

  /**
   * 根据当前选中的时间范围类型，返回起止日期
   * @returns [startDate, endDate] 日期字符串数组
   */
  getDateRange(): string[] {
    switch (this.selectedTimeRange) {
      case TimeRange.WEEK:
        return [getWeekStart(), getWeekEnd()]
      case TimeRange.MONTH:
        return [getMonthStart(), getMonthEnd()]
      case TimeRange.CUSTOM:
        return [this.customStartDate, this.customEndDate]
      default:
        return [getMonthStart(), getMonthEnd()]
    }
  }

  /**
   * 切换时间范围
   * @param range 目标时间范围
   */
  switchTimeRange(range: TimeRange): void {
    if (this.selectedTimeRange === range) {
      return
    }
    this.selectedTimeRange = range
    this.loadAllData()
  }

  /**
   * 切换统计 Tab
   * @param tab 目标 Tab 索引
   */
  switchTab(tab: number): void {
    if (this.currentTab === tab) {
      return
    }
    this.currentTab = tab
    // 切换到趋势分析 Tab 时重新加载趋势数据
    if (tab === 2) {
      this.loadTrendData()
    }
  }

  /**
   * 切换趋势图表类型
   * @param type 目标图表类型
   */
  switchChartType(type: ChartType): void {
    if (this.trendChartType === type) {
      return
    }
    this.trendChartType = type
    this.loadTrendData()
  }

  /**
   * 获取时间范围的显示文本
   * @returns 当前筛选范围描述
   */
  getTimeRangeText(): string {
    const range: string[] = this.getDateRange()
    const startParts: string[] = range[0].split('-')
    const endParts: string[] = range[1].split('-')
    return `${startParts[1]}/${startParts[2]} - ${endParts[1]}/${endParts[2]}`
  }

  // ==================== UI 构建 ====================

  build() {
    Column() {
      // ===== 顶部导航栏 =====
      this.TopNavBar()

      // ===== 时间范围选择 =====
      this.TimeRangeSelector()

      // ===== 内容区域（可滚动） =====
      Scroll() {
        Column() {
          // 支出统计 Tab 内容
          if (this.currentTab === 0) {
            this.ExpenseStatisticsSection()
          }

          // 收入统计 Tab 内容
          if (this.currentTab === 1) {
            this.IncomeStatisticsSection()
          }

          // 趋势分析 Tab 内容
          if (this.currentTab === 2) {
            this.TrendAnalysisSection()
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 24 })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeColors.BG_PAGE)
  }

  // ==================== 子组件构建方法 ====================

  /**
   * 顶部导航栏
   * 包含返回按钮、标题和时间范围显示
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
      Text('统计分析')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeColors.TEXT_PRIMARY)
        .margin({ left: 12 })

      Blank()

      // 当前时间范围显示
      Text(this.getTimeRangeText())
        .fontSize(13)
        .fontColor(ThemeColors.TEXT_PLACEHOLDER)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(ThemeColors.BG_CARD)
    .shadow(ThemeColors.SHADOW_NAV)
  }

  /**
   * 时间范围选择器
   * 提供本周/本月/自定义三种时间范围选择
   */
  @Builder
  TimeRangeSelector() {
    Column() {
      // Tab 切换：支出统计/收入统计/趋势分析
      Row() {
        ForEach(['支出统计', '收入统计', '趋势分析'], (title: string, index: number) => {
          Column() {
            Text(title)
              .fontSize(14)
              .fontWeight(index === this.currentTab ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(index === this.currentTab ? ThemeColors.PRIMARY : ThemeColors.TEXT_SECONDARY)
          }
          .layoutWeight(1)
          .height(40)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .borderRadius(20)
          .backgroundColor(index === this.currentTab ? ThemeColors.PRIMARY_LIGHT : ThemeColors.BG_CARD)
          .onClick(() => {
            this.switchTab(index)
          })
        })
      }
      .width('100%')
      .padding(4)
      .backgroundColor(ThemeColors.BG_SECTION)
      .borderRadius(24)
      .margin({ bottom: 12 })

      // 时间范围按钮行
      Row() {
        // 本周按钮
        Text('本周')
          .fontSize(13)
          .fontColor(this.selectedTimeRange === TimeRange.WEEK ? '#FFFFFF' : ThemeColors.TEXT_SECONDARY)
          .fontWeight(FontWeight.Medium)
          .height(30)
          .padding({ left: 16, right: 16 })
          .borderRadius(15)
          .backgroundColor(this.selectedTimeRange === TimeRange.WEEK ? ThemeColors.PRIMARY : ThemeColors.BG_SECTION)
          .onClick(() => {
            this.switchTimeRange(TimeRange.WEEK)
          })

        // 本月按钮
        Text('本月')
          .fontSize(13)
          .fontColor(this.selectedTimeRange === TimeRange.MONTH ? '#FFFFFF' : ThemeColors.TEXT_SECONDARY)
          .fontWeight(FontWeight.Medium)
          .height(30)
          .padding({ left: 16, right: 16 })
          .borderRadius(15)
          .backgroundColor(this.selectedTimeRange === TimeRange.MONTH ? ThemeColors.PRIMARY : ThemeColors.BG_SECTION)
          .margin({ left: 10 })
          .onClick(() => {
            this.switchTimeRange(TimeRange.MONTH)
          })

        // 自定义按钮
        Text('自定义')
          .fontSize(13)
          .fontColor(this.selectedTimeRange === TimeRange.CUSTOM ? '#FFFFFF' : ThemeColors.TEXT_SECONDARY)
          .fontWeight(FontWeight.Medium)
          .height(30)
          .padding({ left: 16, right: 16 })
          .borderRadius(15)
          .backgroundColor(this.selectedTimeRange === TimeRange.CUSTOM ? ThemeColors.PRIMARY : ThemeColors.BG_SECTION)
          .margin({ left: 10 })
          .onClick(() => {
            this.switchTimeRange(TimeRange.CUSTOM)
          })

        Blank()
      }
      .width('100%')

      // 自定义日期范围选择器（仅在自定义模式下显示）
      if (this.selectedTimeRange === TimeRange.CUSTOM) {
        Row() {
          // 开始日期
          Text(this.customStartDate)
            .fontSize(13)
            .fontColor(ThemeColors.TEXT_NORMAL)
            .height(28)
            .padding({ left: 10, right: 10 })
            .borderRadius(4)
            .border({ width: 0.5, color: ThemeColors.BORDER_INPUT })
            .onClick(() => {
              this.showStartDatePicker = true
            })

          Text(' 至 ')
            .fontSize(13)
            .fontColor(ThemeColors.TEXT_PLACEHOLDER)

          // 结束日期
          Text(this.customEndDate)
            .fontSize(13)
            .fontColor(ThemeColors.TEXT_NORMAL)
            .height(28)
            .padding({ left: 10, right: 10 })
            .borderRadius(4)
            .border({ width: 0.5, color: ThemeColors.BORDER_INPUT })
            .onClick(() => {
              this.showEndDatePicker = true
            })

          Blank()

          // 查询按钮
          Text('查询')
            .fontSize(13)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Medium)
            .height(28)
            .padding({ left: 16, right: 16 })
            .borderRadius(4)
            .backgroundColor(ThemeColors.PRIMARY)
            .onClick(() => {
              this.loadAllData()
            })
        }
        .width('100%')
        .margin({ top: 10 })
        .alignItems(VerticalAlign.Center)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(ThemeColors.BG_CARD)
    .margin({ bottom: 8 })
  }

  /**
   * 支出统计区域
   * 包含总额卡片、饼图和分类排行榜
   */
  @Builder
  ExpenseStatisticsSection() {
    Column() {
      // ---------- 支出总额卡片 ----------
      this.TotalCard('总支出', this.totalExpense, '#FF6384', '💸')

      // ---------- 饼图区域 ----------
      this.SectionTitle('支出分类占比')

      if (this.expensePieData.length > 0) {
        PieChart({
          data: this.expensePieData,
          chartSize: 220,
          title: `¥${this.totalExpense.toFixed(0)}`
        })
        .margin({ bottom: 8 })
      } else {
        this.EmptyChartState()
      }

      // ---------- 分类排行榜 ----------
      this.SectionTitle('分类排行榜')
      this.CategoryRankingList(this.expenseRanking, this.totalExpense)
    }
  }

  /**
   * 收入统计区域
   * 包含总额卡片、饼图和分类排行榜
   */
  @Builder
  IncomeStatisticsSection() {
    Column() {
      // ---------- 收入总额卡片 ----------
      this.TotalCard('总收入', this.totalIncome, '#36A2EB', '💰')

      // ---------- 饼图区域 ----------
      this.SectionTitle('收入分类占比')

      if (this.incomePieData.length > 0) {
        PieChart({
          data: this.incomePieData,
          chartSize: 220,
          title: `¥${this.totalIncome.toFixed(0)}`
        })
        .margin({ bottom: 8 })
      } else {
        this.EmptyChartState()
      }

      // ---------- 分类排行榜 ----------
      this.SectionTitle('分类排行榜')
      this.CategoryRankingList(this.incomeRanking, this.totalIncome)
    }
  }

  /**
   * 趋势分析区域
   * 包含图表类型切换和折线图/柱状图
   */
  @Builder
  TrendAnalysisSection() {
    Column() {
      // ---------- 图表类型切换 ----------
      Row() {
        Text('近7天趋势')
          .fontSize(13)
          .fontColor(this.trendChartType === ChartType.LINE ? '#FFFFFF' : '#666666')
          .fontWeight(FontWeight.Medium)
          .height(28)
          .padding({ left: 14, right: 14 })
          .borderRadius(14)
          .backgroundColor(this.trendChartType === ChartType.LINE ? '#4A90D9' : '#F0F0F0')
          .onClick(() => {
            this.switchChartType(ChartType.LINE)
          })

        Text('本月每日')
          .fontSize(13)
          .fontColor(this.trendChartType === ChartType.BAR ? '#FFFFFF' : '#666666')
          .fontWeight(FontWeight.Medium)
          .height(28)
          .padding({ left: 14, right: 14 })
          .borderRadius(14)
          .backgroundColor(this.trendChartType === ChartType.BAR ? '#4A90D9' : '#F0F0F0')
          .margin({ left: 10 })
          .onClick(() => {
            this.switchChartType(ChartType.BAR)
          })

        Blank()
      }
      .width('100%')
      .margin({ bottom: 16 })

      // ---------- 折线图 ----------
      if (this.trendChartType === ChartType.LINE) {
        this.SectionTitle('近7天收支趋势')

        if (this.trendLineSeries.length > 0) {
          LineChart({
            series: this.trendLineSeries,
            canvasWidth: 340,
            canvasHeight: 220,
            showLegend: true
          })
        } else {
          this.EmptyChartState()
        }
      }

      // ---------- 柱状图 ----------
      if (this.trendChartType === ChartType.BAR) {
        this.SectionTitle('本月每日收支')

        if (this.trendBarData.length > 0) {
          BarChart({
            data: this.trendBarData,
            series: this.trendBarSeries,
            chartWidth: 340,
            chartHeight: 220,
            showLegend: true
          })
        } else {
          this.EmptyChartState()
        }
      }
    }
  }

  /**
   * 总额卡片
   * @param title 卡片标题
   * @param amount 金额数值
   * @param color 主题色
   * @param icon 图标
   */
  @Builder
  TotalCard(title: string, amount: number, color: string, icon: string) {
    Row() {
      // 左侧信息
      Column() {
        Text(title)
          .fontSize(14)
          .fontColor(ThemeColors.TEXT_PLACEHOLDER)
          .margin({ bottom: 8 })

        Text(`¥ ${amount.toFixed(2)}`)
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(color)
      }
      .alignItems(HorizontalAlign.Start)

      Blank()

      // 右侧图标
      Text(icon)
        .fontSize(40)
    }
    .width('100%')
    .padding(20)
    .borderRadius(12)
    .backgroundColor(ThemeColors.BG_CARD)
    .shadow(ThemeColors.SHADOW_CARD)
    .margin({ bottom: 16 })
  }

  /**
   * 区域标题
   * @param title 标题文字
   */
  @Builder
  SectionTitle(title: string) {
    Text(title)
      .fontSize(15)
      .fontWeight(FontWeight.Medium)
      .fontColor(ThemeColors.TEXT_NORMAL)
      .width('100%')
      .margin({ bottom: 12, top: 8 })
  }

  /**
   * 空图表状态提示
   * 无数据时显示占位提示
   */
  @Builder
  EmptyChartState() {
    Column() {
      Text('📊')
        .fontSize(36)
        .margin({ bottom: 8 })

      Text('暂无数据')
        .fontSize(14)
        .fontColor(ThemeColors.TEXT_DISABLED)

      Text('换个时间范围试试吧')
        .fontSize(12)
        .fontColor(ThemeColors.TEXT_DISABLED)
        .margin({ top: 4 })
    }
    .width('100%')
    .height(160)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .borderRadius(8)
    .backgroundColor(ThemeColors.BG_CARD)
  }

  /**
   * 分类排行榜列表
   * 按金额降序排列，显示分类图标、名称、金额和占比
   * @param ranking 排行榜数据
   * @param total 总金额（用于计算百分比）
   */
  @Builder
  CategoryRankingList(ranking: StatisticsResult[], total: number) {
    if (ranking.length === 0) {
      Column() {
        Text('暂无分类数据')
          .fontSize(14)
          .fontColor(ThemeColors.TEXT_DISABLED)
      }
      .width('100%')
      .height(80)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .borderRadius(8)
      .backgroundColor(ThemeColors.BG_CARD)
    } else {
      Column() {
        ForEach(ranking, (item: StatisticsResult, index: number) => {
          Row() {
            // 排名序号
            Text(`${index + 1}`)
              .fontSize(13)
              .fontColor(index < 3 ? ThemeColors.EXPENSE : ThemeColors.TEXT_PLACEHOLDER)
              .fontWeight(index < 3 ? FontWeight.Bold : FontWeight.Normal)
              .width(24)
              .textAlign(TextAlign.Center)

            // 分类图标
            Text(getCategoryIcon(item.category))
              .fontSize(18)
              .margin({ left: 8 })

            // 分类名称
            Text(item.category)
              .fontSize(14)
              .fontColor(ThemeColors.TEXT_NORMAL)
              .margin({ left: 8 })
              .constraintSize({ maxWidth: 80 })

            Blank()

            // 金额
            Text(`¥${item.total.toFixed(2)}`)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(ThemeColors.TEXT_NORMAL)
              .margin({ right: 10 })

            // 百分比
            Text(total > 0
              ? `${((item.total / total) * 100).toFixed(1)}%`
              : '0%')
              .fontSize(12)
              .fontColor(ThemeColors.TEXT_PLACEHOLDER)
              .width(48)
              .textAlign(TextAlign.End)
          }
          .width('100%')
          .height(48)
          .padding({ left: 12, right: 12 })
          .borderRadius(8)
          .backgroundColor(index % 2 === 0 ? ThemeColors.BG_SECTION : ThemeColors.BG_CARD)
          .margin({ bottom: 2 })
        })
      }
      .width('100%')
      .borderRadius(8)
      .backgroundColor(ThemeColors.BG_CARD)
      .padding({ top: 4, bottom: 4 })
    }
  }
}
