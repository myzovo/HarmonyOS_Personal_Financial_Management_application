/**
 * CategoryPicker.ets
 * 分类选择器组件 - 以网格形式展示分类列表供用户选择
 * 支持支出/收入两种类型，选中项高亮显示
 */

// 分类数据接口：包含名称和图标
interface CategoryItem {
  name: string  // 分类名称
  icon: string  // 分类图标（emoji）
}

// 支出分类列表
const EXPENSE_CATEGORIES: CategoryItem[] = [
  { name: '餐饮', icon: '🍜' },
  { name: '交通', icon: '🚌' },
  { name: '购物', icon: '🛒' },
  { name: '住房', icon: '🏠' },
  { name: '娱乐', icon: '🎮' },
  { name: '医疗', icon: '💊' },
  { name: '教育', icon: '📚' },
  { name: '通讯', icon: '📱' },
  { name: '服饰', icon: '👔' },
  { name: '美容', icon: '💄' },
  { name: '运动', icon: '⚽' },
  { name: '旅行', icon: '✈️' },
  { name: '宠物', icon: '🐱' },
  { name: '礼物', icon: '🎁' },
  { name: '其他', icon: '📋' }
]

// 收入分类列表
const INCOME_CATEGORIES: CategoryItem[] = [
  { name: '工资', icon: '💰' },
  { name: '奖金', icon: '🏆' },
  { name: '理财', icon: '📈' },
  { name: '兼职', icon: '💼' },
  { name: '红包', icon: '🧧' },
  { name: '其他', icon: '📋' }
]

/**
 * 分类选择器组件
 * 以网格布局展示分类图标和名称，支持点击切换选中状态
 */
@Component
export struct CategoryPicker {
  /** 当前选中分类 */
  @Prop selectedCategory: string = ''
  /** 分类类型：0=支出分类，1=收入分类 */
  @Prop type: number = 0
  /** 分类选中回调 */
  onCategorySelect: (category: string) => void = () => {}

  /**
   * 根据 type 获取对应的分类列表
   * @returns 分类数据数组
   */
  private getCategoryList(): CategoryItem[] {
    if (this.type === 0) {
      return EXPENSE_CATEGORIES  // 返回支出分类
    }
    return INCOME_CATEGORIES     // 返回收入分类
  }

  build() {
    Column() {
      // 分类网格布局
      Grid() {
        ForEach(this.getCategoryList(), (item: CategoryItem) => {
          GridItem() {
            Column() {
              // 分类图标
              Text(item.icon)
                .fontSize(28)
                .margin({ bottom: 6 })

              // 分类名称
              Text(item.name)
                .fontSize(12)
                .fontColor(this.selectedCategory === item.name ? '#FFFFFF' : '#333333')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .borderRadius(12)
            // 选中状态：蓝色背景高亮；未选中：浅灰色背景
            .backgroundColor(this.selectedCategory === item.name ? '#4A90D9' : '#F5F6FA')
          }
          .onClick(() => {
            // 点击时通过回调通知父组件
            this.onCategorySelect(item.name)
          })
        })
      }
      // 5列网格布局
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
      .rowsGap(10)
      .columnsGap(10)
      .width('100%')
      // 根据分类数量自动调整网格高度（支出15项=3行，收入6项=2行）
      .height(this.type === 0 ? 260 : 170)
    }
    .width('100%')
  }
}
