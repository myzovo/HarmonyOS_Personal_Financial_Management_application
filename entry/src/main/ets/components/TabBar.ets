/**
 * TabBar.ets
 * 底部导航栏组件 - 用于页面切换
 * 支持四个标签页：首页、账单、统计、导出
 *
 * 使用说明：
 *   - 父组件通过 @State + @Link 实现双向绑定
 *   - 点击导航项会自动通过 @Link 回写父组件的 currentIndex
 *   - 底部自动适配安全区域（刘海屏、手势条等）
 *
 * 示例：
 *   @State currentTabIndex: number = 0
 *   TabBar({ currentIndex: $currentTabIndex })
 */

import { ThemeColors } from '../utils/ThemeColors'

// ==================== 接口定义 ====================

/**
 * 标签页配置接口
 * title: 标签文字
 * icon: 默认图标（未选中状态）
 * activeIcon: 选中状态图标
 */
interface TabItem {
  title: string
  icon: string
  activeIcon: string
}

// ==================== 常量配置 ====================

/** 导航栏高度（不含安全区域） */
const BAR_HEIGHT: number = 56

/** 标签页配置列表：首页🏠、账单📋、统计📊、导出📤 */
const TAB_LIST: TabItem[] = [
  { title: '首页', icon: '🏠', activeIcon: '🏡' },
  { title: '账单', icon: '📋', activeIcon: '📝' },
  { title: '统计', icon: '📊', activeIcon: '📈' },
  { title: '导出', icon: '📤', activeIcon: '💾' }
]

// ==================== 组件定义 ====================

@Component
export struct TabBar {
  /**
   * 当前选中的标签索引（双向绑定）
   * 父组件传入 $currentTabIndex 即可实现双向数据流
   */
  @Link currentIndex: number

  build() {
    Column() {
      // ===== 顶部边框线 =====
      Divider()
        .color(ThemeColors.BORDER)
        .strokeWidth(0.5)

      // ===== 导航项行 =====
      Row() {
        ForEach(TAB_LIST, (item: TabItem, index: number) => {
          // 单个导航项：垂直排列图标和文字
          Column() {
            // 图标：选中与未选中使用不同 emoji
            Text(index === this.currentIndex ? item.activeIcon : item.icon)
              .fontSize(22)
              .margin({ bottom: 2 })
              .opacity(index === this.currentIndex ? 1.0 : 0.6)
              .animation({
                duration: 200,
                curve: Curve.EaseInOut
              })

            // 文字标签
            Text(item.title)
              .fontSize(11)
              .fontColor(index === this.currentIndex ? ThemeColors.PRIMARY : ThemeColors.TEXT_PLACEHOLDER)
              .fontWeight(index === this.currentIndex ? FontWeight.Medium : FontWeight.Normal)
              .animation({
                duration: 200,
                curve: Curve.EaseInOut
              })
          }
          .layoutWeight(1)                 // 均匀分配宽度
          .height(BAR_HEIGHT)
          .justifyContent(FlexAlign.Center) // 垂直居中
          .alignItems(HorizontalAlign.Center) // 水平居中

          // 选中指示器：底部高亮小圆点
          .overlay(() => {
            if (index === this.currentIndex) {
              Circle()
                .width(4)
                .height(4)
                .fill(ThemeColors.PRIMARY)
                .offset({ y: (BAR_HEIGHT / 2) - 2 })
            }
          })

          // 点击事件：通过 @Link 直接回写父组件状态
          .onClick(() => {
            this.currentIndex = index
          })
        })
      }
      .width('100%')
      .height(BAR_HEIGHT)
      .backgroundColor(ThemeColors.BG_CARD)

      // ===== 底部安全区域占位 =====
      Row()
        .width('100%')
        .backgroundColor(ThemeColors.BG_CARD)
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    }
    .width('100%')
    .backgroundColor(ThemeColors.BG_CARD)

    // 整体阴影效果：向上投射，营造悬浮感
    .shadow(ThemeColors.SHADOW_TAB)
  }
}
