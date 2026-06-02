/**
 * EmptyState.ets
 * 空状态组件 - 用于无数据时的友好提示
 * 提供统一的空状态样式和交互引导
 */

import { ThemeColors } from '../utils/ThemeColors'

@Component
export struct EmptyState {
  /**
   * 图标（emoji）
   */
  @Prop icon: string = '📝'

  /**
   * 主标题
   */
  @Prop title: string = '暂无数据'

  /**
   * 副标题/提示文字
   */
  @Prop subtitle: string = ''

  /**
   * 操作按钮文字（可选）
   */
  @Prop actionText: string = ''

  /**
   * 操作按钮点击回调（可选）
   */
  onAction: () => void = () => {}

  build() {
    Column() {
      // 图标
      Text(this.icon)
        .fontSize(64)
        .margin({ bottom: 16 })

      // 主标题
      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(ThemeColors.TEXT_SECONDARY)
        .margin({ bottom: 8 })

      // 副标题
      if (this.subtitle.length > 0) {
        Text(this.subtitle)
          .fontSize(14)
          .fontColor(ThemeColors.TEXT_DISABLED)
          .margin({ bottom: 24 })
          .textAlign(TextAlign.Center)
      }

      // 操作按钮（可选）
      if (this.actionText.length > 0) {
        Button(this.actionText)
          .fontSize(14)
          .fontColor(ThemeColors.PRIMARY)
          .backgroundColor(ThemeColors.PRIMARY_LIGHT)
          .borderRadius(20)
          .height(36)
          .padding({ left: 20, right: 20 })
          .onClick(() => {
            this.onAction()
          })
      }
    }
    .width('100%')
    .padding({ top: 60, bottom: 60 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
