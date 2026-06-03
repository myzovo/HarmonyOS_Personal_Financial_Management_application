/**
 * Index.ets
 * 首页仪表盘 - 记账本应用主页面
 * 功能：展示今日/本月收支概览、最近账单列表、快速记账入口
 * 底部 TabBar 支持切换：首页、账单、统计、导出
 */

import { router } from '@kit.ArkUI'
import { DashboardCard } from '../components/DashboardCard'
import { BillItem } from '../components/BillItem'
import { TabBar } from '../components/TabBar'
import { DatabaseHelper, SummaryResult } from '../utils/DatabaseHelper'
import { Bill, BillType } from '../model/Bill'
import { getToday } from '../utils/DateUtils'
import { getCategoryIcon } from '../utils/Constants'
import { ThemeColors } from '../utils/ThemeColors'

@Entry
@Component
struct Index {
  // ==================== 页面状态 ====================

  /** 当前底部导航栏选中索引（通过 @Link 与 TabBar 双向绑定） */
  @State @Watch('onTabIndexChange') currentTabIndex: number = 0

  /** 今日收支汇总 */
  @State todaySummary: SummaryResult = {
    totalExpense: 0,
    totalIncome: 0,
    balance: 0,
    expenseCount: 0,
    incomeCount: 0
  }

  /** 本月收支汇总 */
  @State monthSummary: SummaryResult = {
    totalExpense: 0,
    totalIncome: 0,
    balance: 0,
    expenseCount: 0,
    incomeCount: 0
  }

  /** 最近账单列表（最多5条） */
  @State recentBills: Bill[] = []

  /** 下拉刷新状态 */
  @State isRefreshing: boolean = false

  /** 数据库操作实例 */
  private db: DatabaseHelper = DatabaseHelper.getInstance()

  // ==================== 生命周期 ====================

  /**
   * 页面首次创建时加载数据
   */
  aboutToAppear(): void {
    this.loadData()
  }

  /**
   * 页面每次显示时刷新数据
   * 从其他页面返回时也会触发，确保数据实时更新
   */
  onPageShow(): void {
    this.loadData()
  }

  // ==================== 数据加载 ====================

  /**
   * 加载首页全部数据
   * 包括今日汇总、本月汇总和最近账单
   */
  async loadData(): Promise<void> {
    try {
      // 并行加载今日汇总、本月汇总和最近账单列表
      const results = await Promise.all([
        this.db.getTodaySummary(),
        this.db.getMonthSummary(),
        this.db.queryBills()
      ])
      const today = results[0]
      const month = results[1]
      const bills = results[2]

      this.todaySummary = today
      this.monthSummary = month
      // 只取最近5条账单
      this.recentBills = bills.slice(0, 5)
    } catch (err) {
      console.error('Index', `加载数据失败: ${err}`)
    }
  }

  /**
   * 下拉刷新回调
   * 重新加载所有数据
   */
  async onRefresh(): Promise<void> {
    this.isRefreshing = true
    await this.loadData()
    this.isRefreshing = false
  }

  // ==================== 交互事件 ====================

  /**
   * 点击账单项 - 跳转编辑页面
   * @param billId 账单ID
   */
  onBillEdit(billId: string): void {
    router.pushUrl({
      url: 'pages/AddBill',
      params: { billId: billId, mode: 'edit' }
    })
  }

  /**
   * 长按账单项 - 弹出删除确认
   * @param billId 账单ID
   */
  onBillDelete(billId: string): void {
    AlertDialog.show({
      title: '确认删除',
      message: '确定要删除这条账单吗？删除后无法恢复。',
      primaryButton: {
        value: '取消',
        action: () => {
          console.info('Index', '用户取消删除')
        }
      },
      secondaryButton: {
        value: '删除',
        fontColor: '#FF4D4F',
        action: async () => {
          try {
            await this.db.deleteBill(billId)
            console.info('Index', `账单删除成功: ${billId}`)
            // 删除成功后刷新数据
            await this.loadData()
          } catch (err) {
            console.error('Index', `删除账单失败: ${err}`)
          }
        }
      }
    })
  }

  /**
   * 底部导航栏切换（@Watch 回调，由 TabBar 通过 @Link 触发）
   * 当 currentTabIndex 变化时自动执行页面跳转
   * 使用 replaceUrl 避免页面栈堆积
   */
  onTabIndexChange(): void {
    const index = this.currentTabIndex
    // 根据索引跳转对应页面
    switch (index) {
      case 0:
        // 首页，无需跳转
        break
      case 1:
        router.pushUrl({ url: 'pages/BillList' })
        break
      case 2:
        router.pushUrl({ url: 'pages/Statistics' })
        break
      case 3:
        router.pushUrl({ url: 'pages/Export' })
        break
    }
  }

  /**
   * 点击浮动按钮 - 跳转记账页面
   */
  onAddBill(): void {
    router.pushUrl({
      url: 'pages/AddBill',
      params: { mode: 'add' }
    })
  }

  // ==================== UI 构建 ====================

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        // ===== 顶部标题栏 =====
        Row() {
          Text('记账本')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeColors.TEXT_PRIMARY)

          Blank()

          Text(getToday())
            .fontSize(14)
            .fontColor(ThemeColors.TEXT_PLACEHOLDER)
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 16, bottom: 12 })

        // ===== 可滚动内容区域（支持下拉刷新） =====
        Refresh({ refreshing: $$this.isRefreshing }) {
          Scroll() {
            Column() {
              // ---------- 今日收支卡片区域 ----------
              this.TodaySummarySection()

              // ---------- 本月收支卡片区域 ----------
              this.MonthSummarySection()

              // ---------- 最近账单列表区域 ----------
              this.RecentBillsSection()
            }
            .width('100%')
            .padding({ left: 16, right: 16, bottom: 80 })
          }
          .width('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
        }
        .onRefreshing(() => {
          this.onRefresh()
        })
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(ThemeColors.BG_PAGE)

      // ===== 底部悬浮 "+" 按钮 =====
      this.FloatingAddButton()

      // ===== 底部导航栏 =====
      Column() {
        // @Link 双向绑定：TabBar 内部点击会自动回写 currentTabIndex
        TabBar({ currentIndex: $currentTabIndex })
      }
      .width('100%')
      .position({ x: 0, y: '100%' })
      .translate({ y: '-100%' })
    }
    .width('100%')
    .height('100%')
  }

  // ==================== 子组件构建方法 ====================

  /**
   * 今日收支汇总卡片区域
   */
  @Builder
  TodaySummarySection() {
    Column() {
      Text('今日收支')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(ThemeColors.TEXT_SECONDARY)
        .margin({ bottom: 12 })

      Row() {
        // 支出卡片
        DashboardCard({
          title: '支出',
          amount: this.todaySummary.totalExpense,
          icon: '💸',
          color: ThemeColors.EXPENSE
        })
        .layoutWeight(1)
        .margin({ right: 8 })

        // 收入卡片
        DashboardCard({
          title: '收入',
          amount: this.todaySummary.totalIncome,
          icon: '💰',
          color: ThemeColors.INCOME
        })
        .layoutWeight(1)
        .margin({ left: 4, right: 4 })

        // 结余卡片
        DashboardCard({
          title: '结余',
          amount: this.todaySummary.balance,
          icon: '📊',
          color: ThemeColors.PRIMARY
        })
        .layoutWeight(1)
        .margin({ left: 8 })
      }
      .width('100%')
    }
    .width('100%')
    .margin({ bottom: 20 })
  }

  /**
   * 本月收支汇总卡片区域
   */
  @Builder
  MonthSummarySection() {
    Column() {
      Text('本月收支')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(ThemeColors.TEXT_SECONDARY)
        .margin({ bottom: 12 })

      Row() {
        // 支出卡片
        DashboardCard({
          title: '支出',
          amount: this.monthSummary.totalExpense,
          icon: '💸',
          color: ThemeColors.EXPENSE
        })
        .layoutWeight(1)
        .margin({ right: 8 })

        // 收入卡片
        DashboardCard({
          title: '收入',
          amount: this.monthSummary.totalIncome,
          icon: '💰',
          color: ThemeColors.INCOME
        })
        .layoutWeight(1)
        .margin({ left: 4, right: 4 })

        // 结余卡片
        DashboardCard({
          title: '结余',
          amount: this.monthSummary.balance,
          icon: '📊',
          color: ThemeColors.PRIMARY
        })
        .layoutWeight(1)
        .margin({ left: 8 })
      }
      .width('100%')
    }
    .width('100%')
    .margin({ bottom: 20 })
  }

  /**
   * 最近账单列表区域
   */
  @Builder
  RecentBillsSection() {
    Column() {
      // 区域标题栏
      Row() {
        Text('最近账单')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(ThemeColors.TEXT_SECONDARY)

        Blank()

        Text('查看全部 >')
          .fontSize(14)
          .fontColor(ThemeColors.PRIMARY)
          .onClick(() => {
            router.pushUrl({ url: 'pages/BillList' })
          })
      }
      .width('100%')
      .margin({ bottom: 12 })

      // 账单列表
      if (this.recentBills.length === 0) {
        // 空状态提示
        Column() {
          Text('📝')
            .fontSize(48)
            .margin({ bottom: 12 })

          Text('暂无账单记录')
            .fontSize(15)
            .fontColor(ThemeColors.TEXT_DISABLED)

          Text('点击右下角 "+" 开始记账')
            .fontSize(13)
            .fontColor(ThemeColors.TEXT_DISABLED)
            .margin({ top: 6 })
        }
        .width('100%')
        .padding({ top: 40, bottom: 40 })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        // 账单列表
        ForEach(this.recentBills, (bill: Bill) => {
          BillItem({
            billId: bill.id,
            amount: bill.amount,
            type: bill.type,
            category: bill.category,
            icon: getCategoryIcon(bill.category),
            description: bill.description,
            date: bill.date,
            onEdit: (editBill: Bill) => {
              this.onBillEdit(editBill.id)
            },
            onDelete: (id: string) => {
              this.onBillDelete(id)
            }
          })
          .margin({ bottom: 10 })
        })
      }
    }
    .width('100%')
  }

  /**
   * 底部悬浮 "+" 快速记账按钮
   */
  @Builder
  FloatingAddButton() {
    Button() {
      Text('+')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
    }
    .width(56)
    .height(56)
    .borderRadius(28)
    .backgroundColor(ThemeColors.PRIMARY)
    .shadow(ThemeColors.SHADOW_FAB)
    .position({ x: '80%', y: '85%' })
    .translate({ x: '-50%', y: '-50%' })
    .onClick(() => {
      this.onAddBill()
    })
  }
}
