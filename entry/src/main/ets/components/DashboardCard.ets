/**
 * DashboardCard.ets
 * 仪表盘卡片组件 - 用于展示财务数据摘要（今日支出、本月收入等）
 */

import { ThemeColors } from '../utils/ThemeColors'

@Component
export struct DashboardCard {
  /**
   * 卡片标题，例如 "今日支出"、"本月收入"
   */
  @Prop title: string = ''

  /**
   * 金额数值
   */
  @Prop amount: number = 0

  /**
   * 图标（emoji），例如 "💰"、"📈"
   */
  @Prop icon: string = ''

  /**
   * 主题色，例如 "#FF6B6B"、"#4ECDC4"
   */
  @Prop color: string = '#4A90D9'

  build() {
    Column() {
      // 顶部图标区域
      Row() {
        Text(this.icon)
          .fontSize(28)
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
      .padding({ bottom: 8 })

      // 金额显示（保留两位小数）
      Text(`¥ ${this.amount.toFixed(2)}`)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeColors.TEXT_NORMAL)
        .margin({ bottom: 6 })

      // 卡片标题
      Text(this.title)
        .fontSize(14)
        .fontColor(ThemeColors.TEXT_PLACEHOLDER)
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor(ThemeColors.BG_CARD)
    .shadow(ThemeColors.SHADOW_CARD)
    .alignItems(HorizontalAlign.Start)
  }
}
