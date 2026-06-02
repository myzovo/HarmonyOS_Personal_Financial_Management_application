/**
 * AddBill.ets
 * 添加/编辑账单页面 - 仿记账风格
 * 底部固定数字键盘 + 分类图标网格 + 时间/备注行
 */

import { router } from '@kit.ArkUI'
import { promptAction } from '@kit.ArkUI'
import { Bill, BillType } from '../model/Bill'
import { DatabaseHelper } from '../utils/DatabaseHelper'

// ==================== 颜色常量 ====================
const COLOR_BG: string = '#FFFFFF'
const COLOR_PRIMARY: string = '#287BFF'
const COLOR_TEXT: string = '#222222'
const COLOR_GRAY: string = '#999999'
const COLOR_LIGHT_GRAY: string = '#F5F5F5'
const COLOR_BORDER: string = '#EEEEEE'
const COLOR_DIVIDER: string = '#F0F0F0'

// ==================== 分类数据 ====================
interface CategoryItem {
  name: string
  icon: string
}

// 支出分类（2页，每页10个）
const EXPENSE_PAGE1: CategoryItem[] = [
  { name: '转账', icon: '↗️' },
  { name: '餐饮', icon: '🍜' },
  { name: '购物', icon: '🛒' },
  { name: '消费', icon: '💳' },
  { name: '其他', icon: '📋' },
  { name: '娱乐', icon: '🎮' },
  { name: '交通', icon: '🚌' },
  { name: '住房', icon: '🏠' },
  { name: '红包', icon: '🧧' },
  { name: '医疗', icon: '💊' }
]

const EXPENSE_PAGE2: CategoryItem[] = [
  { name: '教育', icon: '📚' },
  { name: '通讯', icon: '📱' },
  { name: '服饰', icon: '👔' },
  { name: '美容', icon: '💄' },
  { name: '运动', icon: '⚽' },
  { name: '旅行', icon: '✈️' },
  { name: '宠物', icon: '🐱' },
  { name: '礼物', icon: '🎁' },
  { name: '居住', icon: '🏡' },
  { name: '其他', icon: '📦' }
]

// 收入分类
const INCOME_PAGE1: CategoryItem[] = [
  { name: '工资', icon: '💰' },
  { name: '奖金', icon: '🏆' },
  { name: '理财', icon: '📈' },
  { name: '兼职', icon: '💼' },
  { name: '红包', icon: '🧧' },
  { name: '其他', icon: '📋' },
  { name: '退款', icon: '↩️' },
  { name: '报销', icon: '🧾' },
  { name: '租金', icon: '🏠' },
  { name: '转账', icon: '↗️' }
]

// 其他分类
const OTHER_PAGE1: CategoryItem[] = [
  { name: '借出', icon: '📤' },
  { name: '借入', icon: '📥' },
  { name: '还款', icon: '💳' },
  { name: '收款', icon: '💰' },
  { name: '其他', icon: '📋' },
  { name: '转入', icon: '↙️' },
  { name: '转出', icon: '↗️' },
  { name: '投资', icon: '📈' },
  { name: '取现', icon: '🏧' },
  { name: '充值', icon: '🔋' }
]

@Entry
@Component
struct AddBill {
  // ==================== 路由参数 ====================
  private billId: string = ''
  @State isEditMode: boolean = false

  // ==================== 表单状态 ====================
  @State billType: BillType = BillType.EXPENSE
  @State amountStr: string = ''
  @State selectedCategory: string = ''
  @State remark: string = ''
  @State isSaving: boolean = false

  // 类型标签索引：0=支出，1=收入，2=其他
  @State typeTabIndex: number = 0

  // 分类分页
  @State categoryPage: number = 0

  // 时间
  @State selectedTime: string = ''

  // 备注弹窗
  @State showRemarkInput: boolean = false
  @State remarkInputValue: string = ''

  // ==================== 数据库实例 ====================
  private db: DatabaseHelper = DatabaseHelper.getInstance()

  // ==================== 生命周期 ====================

  aboutToAppear(): void {
    // 初始化当前时间
    this.selectedTime = this.getCurrentDateTime()

    try {
      const params = router.getParams() as Record<string, string>
      if (params && params['billId']) {
        this.billId = params['billId']
        this.isEditMode = true
        this.loadBillData()
      }
    } catch (err) {
      console.error('AddBill', `获取路由参数失败: ${err}`)
    }
  }

  // ==================== 工具方法 ====================

  private getCurrentDateTime(): string {
    const now = new Date()
    const year = now.getFullYear()
    const month = String(now.getMonth() + 1).padStart(2, '0')
    const day = String(now.getDate()).padStart(2, '0')
    const hours = String(now.getHours()).padStart(2, '0')
    const minutes = String(now.getMinutes()).padStart(2, '0')
    return `${year}-${month}-${day} ${hours}:${minutes}`
  }

  showToast(message: string): void {
    promptAction.showToast({ message: message, duration: 2000 })
  }

  // ==================== 数据加载 ====================

  async loadBillData(): Promise<void> {
    try {
      const bills: Bill[] = await this.db.queryBills()
      const bill: Bill | undefined = bills.find((b: Bill) => b.id === this.billId)
      if (bill) {
        this.billType = bill.type
        this.typeTabIndex = bill.type === BillType.EXPENSE ? 0 : 1
        this.amountStr = bill.amount.toString()
        this.selectedCategory = bill.category
        this.remark = bill.description
        this.selectedTime = bill.date
      }
    } catch (err) {
      this.showToast('加载数据失败')
    }
  }

  // ==================== 保存逻辑 ====================

  validateForm(): boolean {
    if (!this.amountStr || this.amountStr.trim().length === 0) {
      this.showToast('请输入金额')
      return false
    }
    const amount: number = parseFloat(this.amountStr)
    if (isNaN(amount) || amount <= 0) {
      this.showToast('金额必须大于0')
      return false
    }
    if (!this.selectedCategory || this.selectedCategory.trim().length === 0) {
      this.showToast('请选择分类')
      return false
    }
    return true
  }

  async saveBill(): Promise<void> {
    if (this.isSaving) return
    if (!this.validateForm()) return

    this.isSaving = true
    try {
      const amount: number = parseFloat(this.amountStr)
      const dateStr: string = this.selectedTime.split(' ')[0]

      if (this.isEditMode) {
        const updatedBill: Bill = {
          id: this.billId,
          amount: amount,
          type: this.billType,
          category: this.selectedCategory,
          description: this.remark,
          date: dateStr,
          createdAt: '',
          updatedAt: ''
        }
        await this.db.updateBill(updatedBill)
        this.showToast('账单更新成功')
      } else {
        const newBill: Bill = {
          id: '',
          amount: amount,
          type: this.billType,
          category: this.selectedCategory,
          description: this.remark,
          date: dateStr,
          createdAt: '',
          updatedAt: ''
        }
        await this.db.insertBill(newBill)
        this.showToast('账单添加成功')
      }
      router.back()
    } catch (err) {
      this.showToast('保存失败，请重试')
    } finally {
      this.isSaving = false
    }
  }

  // ==================== 获取当前分类页数据 ====================

  private getCurrentCategories(): CategoryItem[] {
    if (this.typeTabIndex === 0) {
      return this.categoryPage === 0 ? EXPENSE_PAGE1 : EXPENSE_PAGE2
    } else if (this.typeTabIndex === 1) {
      return INCOME_PAGE1
    }
    return OTHER_PAGE1
  }

  private getCategoryPageCount(): number {
    if (this.typeTabIndex === 0) return 2
    return 1
  }

  private getCategoryPageIndicators(): number[] {
    const count: number = this.getCategoryPageCount()
    const result: number[] = []
    for (let i: number = 0; i < count; i++) {
      result.push(i)
    }
    return result
  }

  // ==================== UI 构建 ====================

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        // 1. 状态栏
        this.StatusBar()

        // 2. 导航栏
        this.NavBar()

        // 可滚动内容区
        Scroll() {
          Column() {
            // 3. 收支标签切换
            this.TypeTabs()

            // 4. 金额输入区
            this.AmountSection()

            // 5. 分类图标区
            this.CategoryGrid()

            // 6. 时间+备注信息列表
            this.InfoList()
          }
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)

        // 7. 底部数字键盘
        this.NumericKeyboard()
      }
      .width('100%')
      .height('100%')
      .backgroundColor(COLOR_BG)

      // 备注输入弹窗（浮层）
      this.RemarkDialog()
    }
    .width('100%')
    .height('100%')
  }

  // ==================== 1. 状态栏 ====================

  @Builder
  StatusBar() {
    Row() {
      Text('10:46')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(COLOR_TEXT)

      Blank()

      Row() {
        Text('1.15KB/s')
          .fontSize(10)
          .fontColor(COLOR_GRAY)
          .margin({ right: 6 })

        Text('📶')
          .fontSize(12)
          .margin({ right: 4 })

        Text('🔋')
          .fontSize(12)
      }
    }
    .width('100%')
    .height(44)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
  }

  // ==================== 2. 导航栏 ====================

  @Builder
  NavBar() {
    Row() {
      Text('×')
        .fontSize(28)
        .fontColor(COLOR_TEXT)
        .fontWeight(FontWeight.Medium)
        .onClick(() => {
          router.back()
        })

      Blank()

      Text(this.isEditMode ? '编辑账单' : '记一笔')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLOR_TEXT)

      Blank()

      // 右侧占位，保持标题居中
      Text('')
        .width(28)
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
  }

  // ==================== 3. 收支标签切换栏 ====================

  @Builder
  TypeTabs() {
    Row() {
      // 支出
      Column() {
        Text('支出')
          .fontSize(16)
          .fontWeight(this.typeTabIndex === 0 ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.typeTabIndex === 0 ? COLOR_TEXT : COLOR_GRAY)
          .padding({ left: 16, right: 16, top: 12, bottom: 10 })

        Divider()
          .strokeWidth(3)
          .color(COLOR_PRIMARY)
          .width(24)
          .visibility(this.typeTabIndex === 0 ? Visibility.Visible : Visibility.Hidden)
      }
      .onClick(() => {
        this.switchType(0)
      })

      // 收入
      Column() {
        Text('收入')
          .fontSize(16)
          .fontWeight(this.typeTabIndex === 1 ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.typeTabIndex === 1 ? COLOR_TEXT : COLOR_GRAY)
          .padding({ left: 16, right: 16, top: 12, bottom: 10 })

        Divider()
          .strokeWidth(3)
          .color(COLOR_PRIMARY)
          .width(24)
          .visibility(this.typeTabIndex === 1 ? Visibility.Visible : Visibility.Hidden)
      }
      .onClick(() => {
        this.switchType(1)
      })

      // 其他
      Column() {
        Text('其他')
          .fontSize(16)
          .fontWeight(this.typeTabIndex === 2 ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(this.typeTabIndex === 2 ? COLOR_TEXT : COLOR_GRAY)
          .padding({ left: 16, right: 16, top: 12, bottom: 10 })

        Divider()
          .strokeWidth(3)
          .color(COLOR_PRIMARY)
          .width(24)
          .visibility(this.typeTabIndex === 2 ? Visibility.Visible : Visibility.Hidden)
      }
      .onClick(() => {
        this.switchType(2)
      })
    }
    .width('100%')
    .justifyContent(FlexAlign.Start)
    .border({ width: { bottom: 1 }, color: COLOR_BORDER })
  }

  private switchType(index: number): void {
    if (this.typeTabIndex !== index) {
      this.typeTabIndex = index
      this.billType = index === 0 ? BillType.EXPENSE : BillType.INCOME
      this.selectedCategory = ''
      this.categoryPage = 0
    }
  }

  // ==================== 4. 金额输入区 ====================

  @Builder
  AmountSection() {
    Column() {
      Row() {
        Text('¥')
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLOR_TEXT)
          .margin({ right: 8 })

        Text(this.amountStr.length > 0 ? this.amountStr : '0.00')
          .fontSize(42)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.amountStr.length > 0 ? COLOR_TEXT : '#CCCCCC')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 20, bottom: 12 })

      // 蓝色下划线
      Divider()
        .strokeWidth(2)
        .color(COLOR_PRIMARY)
        .width('100%')
    }
    .width('100%')
    .backgroundColor(COLOR_BG)
  }

  // ==================== 5. 分类图标区 ====================

  @Builder
  CategoryGrid() {
    Column() {
      // 分类网格（2行×5列）
      Grid() {
        ForEach(this.getCurrentCategories(), (item: CategoryItem) => {
          GridItem() {
            Column() {
              // 图标容器（圆角方框）
              Column() {
                Text(item.icon)
                  .fontSize(24)
              }
              .width(48)
              .height(48)
              .borderRadius(12)
              .border({ width: 1, color: '#D6E8FF' })
              .backgroundColor('#F0F7FF')
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)

              // 分类名
              Text(item.name)
                .fontSize(11)
                .fontColor(COLOR_TEXT)
                .margin({ top: 6 })
                .maxLines(1)
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
            .opacity(this.selectedCategory === item.name ? 1 : 0.8)
            .onClick(() => {
              this.selectedCategory = item.name
            })
          }
        })
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
      .rowsGap(16)
      .columnsGap(8)
      .width('100%')
      .height(160)
      .padding({ left: 16, right: 16, top: 16 })

      // 分页指示器
      Row() {
        ForEach(this.getCategoryPageIndicators(), (index: number) => {
          Circle()
            .width(8)
            .height(8)
            .fill(index === this.categoryPage ? '#555555' : '#CCCCCC')
            .margin({ left: 4, right: 4 })
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: 12, bottom: 16 })
    }
    .width('100%')
    .backgroundColor(COLOR_BG)
  }

  // ==================== 6. 时间+备注信息列表 ====================

  @Builder
  InfoList() {
    Column() {
      // 时间行
      Row() {
        Text('🕐')
          .fontSize(18)
          .margin({ right: 10 })

        Text('时间')
          .fontSize(15)
          .fontColor(COLOR_TEXT)

        Blank()

        Text(this.selectedTime)
          .fontSize(14)
          .fontColor(COLOR_TEXT)
          .margin({ right: 6 })

        Text('>')
          .fontSize(14)
          .fontColor(COLOR_GRAY)
      }
      .width('100%')
      .height(52)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)

      // 分割线
      Divider()
        .strokeWidth(0.5)
        .color(COLOR_DIVIDER)
        .margin({ left: 44 })

      // 备注行
      Row() {
        Text('📅')
          .fontSize(18)
          .margin({ right: 10 })

        Text('备注')
          .fontSize(15)
          .fontColor(COLOR_TEXT)

        Blank()

        Text(this.remark.length > 0 ? this.remark : '点击添加备注')
          .fontSize(14)
          .fontColor(this.remark.length > 0 ? COLOR_TEXT : COLOR_GRAY)
          .margin({ right: 6 })

        Text('>')
          .fontSize(14)
          .fontColor(COLOR_GRAY)
      }
      .width('100%')
      .height(52)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
      .onClick(() => {
        this.remarkInputValue = this.remark
        this.showRemarkInput = true
      })
    }
    .width('100%')
    .backgroundColor(COLOR_BG)
    .border({ width: { top: 0.5 }, color: COLOR_DIVIDER })
  }

  // ==================== 备注输入弹窗 ====================

  @Builder
  RemarkDialog() {
    if (this.showRemarkInput) {
      Column() {
        // 遮罩
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#80000000')
          .position({ x: 0, y: 0 })
          .onClick(() => {
            this.showRemarkInput = false
          })

        // 弹窗内容
        Column() {
          Text('添加备注')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(COLOR_TEXT)
            .margin({ bottom: 16 })

          TextInput({ placeholder: '例如：午餐、地铁、购物...', text: this.remarkInputValue })
            .fontSize(15)
            .fontColor(COLOR_TEXT)
            .backgroundColor(COLOR_LIGHT_GRAY)
            .borderRadius(8)
            .padding(12)
            .height(48)
            .width('100%')
            .placeholderColor(COLOR_GRAY)
            .onChange((value: string) => {
              this.remarkInputValue = value
            })

          Row() {
            Text('取消')
              .fontSize(15)
              .fontColor(COLOR_GRAY)
              .layoutWeight(1)
              .height(44)
              .textAlign(TextAlign.Center)
              .backgroundColor(COLOR_LIGHT_GRAY)
              .borderRadius(8)
              .margin({ right: 6 })
              .onClick(() => {
                this.showRemarkInput = false
              })

            Text('确定')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .backgroundColor(COLOR_PRIMARY)
              .borderRadius(8)
              .layoutWeight(1)
              .height(44)
              .textAlign(TextAlign.Center)
              .margin({ left: 6 })
              .onClick(() => {
                this.remark = this.remarkInputValue
                this.showRemarkInput = false
              })
          }
          .width('100%')
          .margin({ top: 20 })
        }
        .width('85%')
        .padding(24)
        .borderRadius(16)
        .backgroundColor(COLOR_BG)
        .position({ x: '7.5%', y: '30%' })
      }
      .width('100%')
      .height('100%')
      .position({ x: 0, y: 0 })
      .zIndex(100)
    }
  }

  // ==================== 7. 底部数字键盘 ====================

  @Builder
  NumericKeyboard() {
    Column() {
      // 第1行：1 2 3 删除
      Row() {
        this.NumKey('1')
        this.NumKey('2')
        this.NumKey('3')
        this.FuncKey('⌫')
      }
      .width('100%')

      // 第2行：4 5 6 +
      Row() {
        this.NumKey('4')
        this.NumKey('5')
        this.NumKey('6')
        this.FuncKey('+')
      }
      .width('100%')

      // 第3行：7 8 9 -
      Row() {
        this.NumKey('7')
        this.NumKey('8')
        this.NumKey('9')
        this.FuncKey('-')
      }
      .width('100%')

      // 第4行：. 0 再记一笔 完成
      Row() {
        this.NumKey('.')
        this.NumKey('0')

        // 再记一笔按钮
        Column() {
          Text('再记一笔')
            .fontSize(14)
            .fontColor(COLOR_GRAY)
        }
        .layoutWeight(1)
        .height(52)
        .borderRadius(8)
        .backgroundColor(COLOR_LIGHT_GRAY)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .margin(3)
        .onClick(() => {
          this.saveAndContinue()
        })

        // 完成按钮
        Column() {
          Text('完成')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
        }
        .layoutWeight(1)
        .height(52)
        .borderRadius(8)
        .backgroundColor(COLOR_PRIMARY)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .margin(3)
        .onClick(() => {
          this.saveBill()
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding(3)
    .backgroundColor('#E8E8E8')
  }

  // ==================== 数字键 ====================

  @Builder
  NumKey(label: string) {
    Column() {
      Text(label)
        .fontSize(22)
        .fontWeight(FontWeight.Medium)
        .fontColor(COLOR_TEXT)
    }
    .layoutWeight(1)
    .height(52)
    .borderRadius(8)
    .backgroundColor(COLOR_BG)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .margin(3)
    .onClick(() => {
      this.onNumKeyPress(label)
    })
  }

  // ==================== 功能键 ====================

  @Builder
  FuncKey(label: string) {
    Column() {
      Text(label)
        .fontSize(22)
        .fontWeight(FontWeight.Medium)
        .fontColor(COLOR_TEXT)
    }
    .layoutWeight(1)
    .height(52)
    .borderRadius(8)
    .backgroundColor(COLOR_LIGHT_GRAY)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .margin(3)
    .onClick(() => {
      this.onFuncKeyPress(label)
    })
  }

  // ==================== 按键处理 ====================

  private onNumKeyPress(label: string): void {
    if (label === '.') {
      if (!this.amountStr.includes('.')) {
        this.amountStr += this.amountStr.length === 0 ? '0.' : '.'
      }
    } else {
      // 限制小数位数为2位
      if (this.amountStr.includes('.')) {
        const decimalPart: string = this.amountStr.split('.')[1]
        if (decimalPart && decimalPart.length >= 2) {
          return
        }
      }
      this.amountStr += label
    }
  }

  private onFuncKeyPress(label: string): void {
    if (label === '⌫') {
      if (this.amountStr.length > 0) {
        this.amountStr = this.amountStr.substring(0, this.amountStr.length - 1)
      }
    } else if (label === '+') {
      // TODO: 连加逻辑
    } else if (label === '-') {
      // TODO: 连减逻辑
    }
  }

  // ==================== 再记一笔 ====================

  private async saveAndContinue(): Promise<void> {
    if (!this.validateForm()) return

    this.isSaving = true
    try {
      const amount: number = parseFloat(this.amountStr)
      const dateStr: string = this.selectedTime.split(' ')[0]

      const newBill: Bill = {
        id: '',
        amount: amount,
        type: this.billType,
        category: this.selectedCategory,
        description: this.remark,
        date: dateStr,
        createdAt: '',
        updatedAt: ''
      }
      await this.db.insertBill(newBill)
      this.showToast('已保存，继续记账')

      // 重置表单（保留分类和时间）
      this.amountStr = ''
      this.remark = ''
    } catch (err) {
      this.showToast('保存失败，请重试')
    } finally {
      this.isSaving = false
    }
  }
}
