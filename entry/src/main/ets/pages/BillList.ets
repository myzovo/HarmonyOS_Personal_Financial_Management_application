/**
 * BillList.ets
 * 账单列表页面
 * 功能：按月份/周筛选查看账单，按日期分组显示，支持点击编辑、长按删除
 */

import { router } from '@kit.ArkUI'
import { promptAction } from '@kit.ArkUI'
import { Bill, BillType } from '../model/Bill'
import { DatabaseHelper } from '../utils/DatabaseHelper'
import { formatDate, parseDate, getWeekStart, getWeekEnd } from '../utils/DateUtils'
import { getCategoryIcon } from '../utils/Constants'
import { BillItem } from '../components/BillItem'
import { ThemeColors } from '../utils/ThemeColors'

/**
 * 按日期分组的账单数据结构
 * 每个元素代表一天的账单集合
 */
interface DayGroup {
  /** 日期字符串，格式 YYYY-MM-DD */
  date: string
  /** 当日账单列表 */
  bills: Bill[]
  /** 当日支出小计 */
  expenseTotal: number
  /** 当日收入小计 */
  incomeTotal: number
}

@Entry
@Component
struct BillList {
  // ==================== 筛选状态 ====================

  /** 当前选中年份 */
  @State currentYear: number = new Date().getFullYear()

  /** 当前选中月份（1-12） */
  @State currentMonth: number = new Date().getMonth() + 1

  /** 是否按本周筛选 */
  @State isWeekFilter: boolean = false

  // ==================== 列表数据 ====================

  /** 原始账单列表 */
  @State billList: Bill[] = []

  /** 按日期分组后的账单数据 */
  @State groupedData: DayGroup[] = []

  // ==================== UI 状态 ====================

  /** 下拉刷新状态 */
  @State isRefreshing: boolean = false

  /** 长按操作菜单是否显示 */
  @State showActionMenu: boolean = false

  /** 当前长按操作的账单ID */
  @State selectedBillId: string = ''

  // ==================== 数据库实例 ====================

  /** 数据库操作单例 */
  private db: DatabaseHelper = DatabaseHelper.getInstance()

  // ==================== 生命周期 ====================

  /**
   * 页面即将显示时触发
   * 加载账单数据
   */
  aboutToAppear(): void {
    this.loadBillData()
  }

  /**
   * 页面重新显示时刷新数据
   * 从编辑页面返回后自动刷新列表
   */
  onShow(): void {
    this.loadBillData()
  }

  // ==================== 数据加载 ====================

  /**
   * 加载账单数据
   * 根据当前筛选状态（月份/周）查询数据库并按日期分组
   */
  async loadBillData(): Promise<void> {
    try {
      let bills: Bill[] = []

      if (this.isWeekFilter) {
        // 周筛选模式：查询本周日期范围内的账单
        const weekStart: string = getWeekStart()
        const weekEnd: string = getWeekEnd()
        bills = await this.db.queryBillsByDateRange(weekStart, weekEnd)
      } else {
        // 月份筛选模式：查询指定月份的账单
        const monthStr: string = this.getMonthString()
        bills = await this.db.queryBills(monthStr)
      }

      // 更新原始账单列表
      this.billList = bills
      // 按日期分组
      this.groupBillByDate()

      console.info('BillList', `数据加载完成，共 ${bills.length} 条账单`)
    } catch (err) {
      console.error('BillList', `加载账单数据失败: ${err}`)
      promptAction.showToast({ message: '加载数据失败', duration: 2000 })
    }
  }

  /**
   * 将账单列表按日期分组
   * 同时计算每日的支出/收入小计
   */
  groupBillByDate(): void {
    // 使用对象数组代替 Map（ArkTS 对 Map 支持有限）
    const dateKeys: string[] = []
    const dateBills: Bill[][] = []

    // 按日期分组
    for (const bill of this.billList) {
      const dateKey: string = bill.date
      let foundIndex: number = -1
      for (let i: number = 0; i < dateKeys.length; i++) {
        if (dateKeys[i] === dateKey) {
          foundIndex = i
          break
        }
      }
      if (foundIndex >= 0) {
        dateBills[foundIndex].push(bill)
      } else {
        dateKeys.push(dateKey)
        dateBills.push([bill])
      }
    }

    // 转换为 DayGroup 数组并计算小计
    const groups: DayGroup[] = []
    for (let i: number = 0; i < dateKeys.length; i++) {
      let expenseTotal: number = 0
      let incomeTotal: number = 0

      for (const bill of dateBills[i]) {
        if (bill.type === BillType.EXPENSE) {
          expenseTotal += bill.amount
        } else {
          incomeTotal += bill.amount
        }
      }

      groups.push({
        date: dateKeys[i],
        bills: dateBills[i],
        expenseTotal: expenseTotal,
        incomeTotal: incomeTotal
      })
    }

    // 按日期降序排列
    groups.sort((a: DayGroup, b: DayGroup) => {
      return b.date.localeCompare(a.date)
    })

    this.groupedData = groups
  }

  // ==================== 月份切换 ====================

  /**
   * 切换到上一个月
   */
  goToPreviousMonth(): void {
    if (this.currentMonth === 1) {
      this.currentMonth = 12
      this.currentYear -= 1
    } else {
      this.currentMonth -= 1
    }
    // 切换月份后重置周筛选状态并重新加载数据
    this.isWeekFilter = false
    this.loadBillData()
  }

  /**
   * 切换到下一个月
   */
  goToNextMonth(): void {
    if (this.currentMonth === 12) {
      this.currentMonth = 1
      this.currentYear += 1
    } else {
      this.currentMonth += 1
    }
    // 切换月份后重置周筛选状态并重新加载数据
    this.isWeekFilter = false
    this.loadBillData()
  }

  /**
   * 切换周筛选模式
   * 开启时显示本周数据，关闭时显示整月数据
   */
  toggleWeekFilter(): void {
    this.isWeekFilter = !this.isWeekFilter
    this.loadBillData()
  }

  // ==================== 操作事件 ====================

  /**
   * 确认删除账单
   * 弹出确认对话框，确认后执行删除并刷新列表
   * @param id 要删除的账单ID
   */
  onDeleteBill(id: string): void {
    AlertDialog.show({
      title: '确认删除',
      message: '确定要删除这条账单吗？删除后无法恢复。',
      primaryButton: {
        value: '取消',
        action: () => {
          console.info('BillList', '用户取消删除')
        }
      },
      secondaryButton: {
        value: '删除',
        fontColor: '#FF4D4F',
        action: async () => {
          try {
            await this.db.deleteBill(id)
            console.info('BillList', `账单删除成功: ${id}`)
            promptAction.showToast({ message: '删除成功', duration: 1500 })
            // 删除成功后刷新列表
            await this.loadBillData()
          } catch (err) {
            console.error('BillList', `删除账单失败: ${err}`)
            promptAction.showToast({ message: '删除失败', duration: 2000 })
          }
        }
      }
    })
  }

  /**
   * 跳转到编辑页面
   * @param bill 要编辑的账单对象
   */
  onEditBill(bill: Bill): void {
    router.pushUrl({
      url: 'pages/AddBill',
      params: { billId: bill.id, mode: 'edit' }
    })
  }

  /**
   * 根据ID查找账单
   * @param id 账单ID
   * @returns 找到的账单，未找到返回undefined
   */
  findBillById(id: string): Bill | undefined {
    for (const bill of this.billList) {
      if (bill.id === id) {
        return bill
      }
    }
    return undefined
  }

  /**
   * 下拉刷新回调
   * 重新加载当前筛选条件下的账单数据
   */
  async onRefresh(): Promise<void> {
    this.isRefreshing = true
    await this.loadBillData()
    this.isRefreshing = false
  }

  // ==================== 工具方法 ====================

  /**
   * 获取当前选中月份的字符串表示
   * @returns 月份字符串，格式 YYYY-MM
   */
  getMonthString(): string {
    const monthStr: string = this.currentMonth < 10
      ? `0${this.currentMonth}`
      : `${this.currentMonth}`
    return `${this.currentYear}-${monthStr}`
  }

  /**
   * 获取当前筛选范围的显示文本
   * 周筛选显示具体日期范围，月筛选显示年月
   * @returns 筛选范围描述文本
   */
  getFilterRangeText(): string {
    if (this.isWeekFilter) {
      const weekStart: string = getWeekStart()
      const weekEnd: string = getWeekEnd()
      // 提取月/日部分进行简短显示
      const startParts: string[] = weekStart.split('-')
      const endParts: string[] = weekEnd.split('-')
      return `${startParts[1]}/${startParts[2]} - ${endParts[1]}/${endParts[2]}`
    }
    return `${this.currentYear}年${this.currentMonth}月`
  }

  /**
   * 将日期字符串转换为中文星期显示
   * @param dateStr 日期字符串，格式 YYYY-MM-DD
   * @returns 中文星期文本，如 "周一"、"周二"
   */
  getWeekDayText(dateStr: string): string {
    const date: Date = parseDate(dateStr)
    const dayOfWeek: number = date.getDay()
    const weekDays: string[] = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
    return weekDays[dayOfWeek]
  }

  /**
   * 获取账单分类对应的 emoji 图标
   * @param category 分类名称
   * @returns 对应的 emoji 图标
   */
  getBillIcon(category: string): string {
    return getCategoryIcon(category)
  }

  // ==================== UI 构建 ====================

  build() {
    Column() {
      // ===== 顶部导航栏 =====
      this.TopNavBar()

      // ===== 筛选区域 =====
      this.FilterSection()

      // ===== 账单列表区域 =====
      Refresh({ refreshing: $$this.isRefreshing }) {
        if (this.groupedData.length === 0) {
          // 空状态提示
          this.EmptyState()
        } else {
          // 按日期分组的账单列表
          List() {
            ForEach(this.groupedData, (group: DayGroup) => {
              // 日期分组标题
              ListItem() {
                this.DayGroupHeader(group)
              }

              // 该日期下的每条账单
              ForEach(group.bills, (bill: Bill) => {
                ListItem() {
                  BillItem({
                    billId: bill.id,
                    category: bill.category,
                    icon: this.getBillIcon(bill.category),
                    amount: bill.amount,
                    type: bill.type,
                    date: bill.date,
                    description: bill.description,
                    onDelete: (id: string) => {
                      this.onDeleteBill(id)
                    },
                    onEdit: (editBill: Bill) => {
                      this.onEditBill(editBill)
                    }
                  })
                  .onClick(() => {
                    // 点击跳转编辑页面
                    this.onEditBill(bill)
                  })
                  .gesture(
                    LongPressGesture()
                      .onAction(() => {
                        // 长按删除
                        this.onDeleteBill(bill.id)
                      })
                  )
                }
              })
            })
          }
          .width('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
          .onReachEnd(() => {
            // 上拉加载更多（当前为全量加载，预留扩展点）
            console.info('BillList', '已到达列表底部')
          })
        }
      }
      .onRefreshing(() => {
        this.onRefresh()
      })
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeColors.BG_PAGE)
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
      Text('账单明细')
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
   * 筛选区域
   * 包含月份选择器、周筛选按钮和当前筛选范围显示
   */
  @Builder
  FilterSection() {
    Column() {
      // 月份选择器行：左箭头 + 年月显示 + 右箭头
      Row() {
        // 左箭头 - 上一月
        Text('<')
          .fontSize(18)
          .fontColor(ThemeColors.TEXT_SECONDARY)
          .fontWeight(FontWeight.Bold)
          .width(40)
          .height(40)
          .textAlign(TextAlign.Center)
          .borderRadius(20)
          .backgroundColor(ThemeColors.BG_SECTION)
          .onClick(() => {
            this.goToPreviousMonth()
          })

        // 当前年月显示
        Text(`${this.currentYear}年${this.currentMonth}月`)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor(ThemeColors.TEXT_NORMAL)
          .margin({ left: 20, right: 20 })

        // 右箭头 - 下一月
        Text('>')
          .fontSize(18)
          .fontColor(ThemeColors.TEXT_SECONDARY)
          .fontWeight(FontWeight.Bold)
          .width(40)
          .height(40)
          .textAlign(TextAlign.Center)
          .borderRadius(20)
          .backgroundColor(ThemeColors.BG_SECTION)
          .onClick(() => {
            this.goToNextMonth()
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .margin({ top: 12, bottom: 12 })

      // 周筛选按钮和当前筛选范围
      Row() {
        // 周筛选按钮
        Button(this.isWeekFilter ? '取消周筛选' : '本周')
          .fontSize(13)
          .fontColor(this.isWeekFilter ? ThemeColors.TEXT_PLACEHOLDER : '#FFFFFF')
          .backgroundColor(this.isWeekFilter ? ThemeColors.BG_SECTION : ThemeColors.PRIMARY)
          .borderRadius(16)
          .height(32)
          .padding({ left: 14, right: 14 })
          .onClick(() => {
            this.toggleWeekFilter()
          })

        Blank()

        // 当前筛选范围显示
        Text(this.getFilterRangeText())
          .fontSize(13)
          .fontColor(ThemeColors.TEXT_PLACEHOLDER)
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
      .margin({ bottom: 12 })
    }
    .width('100%')
    .backgroundColor(ThemeColors.BG_CARD)
    .margin({ bottom: 8 })
  }

  /**
   * 日期分组标题
   * 显示日期、星期和当日收支小计
   * @param group 日期分组数据
   */
  @Builder
  DayGroupHeader(group: DayGroup) {
    Row() {
      // 日期和星期
      Row() {
        Text(group.date)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(ThemeColors.TEXT_NORMAL)

        Text(this.getWeekDayText(group.date))
          .fontSize(12)
          .fontColor(ThemeColors.TEXT_PLACEHOLDER)
          .margin({ left: 8 })
      }
      .alignItems(VerticalAlign.Center)

      Blank()

      // 当日收支小计
      Row() {
        // 支出小计（仅在有支出时显示）
        if (group.expenseTotal > 0) {
          Text(`出 ¥${group.expenseTotal.toFixed(2)}`)
            .fontSize(12)
            .fontColor(ThemeColors.ERROR)
            .margin({ right: 10 })
        }

        // 收入小计（仅在有收入时显示）
        if (group.incomeTotal > 0) {
          Text(`入 ¥${group.incomeTotal.toFixed(2)}`)
            .fontSize(12)
            .fontColor(ThemeColors.SUCCESS)
        }
      }
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height(44)
    .padding({ left: 16, right: 16 })
    .backgroundColor(ThemeColors.BG_SECTION)
    .alignItems(VerticalAlign.Center)
  }

  /**
   * 空状态提示
   * 无账单数据时显示图标和提示文字
   */
  @Builder
  EmptyState() {
    Column() {
      Text('📝')
        .fontSize(48)
        .margin({ bottom: 12 })

      Text('暂无账单记录')
        .fontSize(16)
        .fontColor(ThemeColors.TEXT_DISABLED)

      Text('换个筛选条件试试吧')
        .fontSize(13)
        .fontColor(ThemeColors.TEXT_DISABLED)
        .margin({ top: 8 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
