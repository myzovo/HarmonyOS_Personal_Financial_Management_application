/**
 * BackButton.ets
 * 通用返回按钮组件
 * 提供统一的返回按钮样式和交互效果
 */

import { router } from '@kit.ArkUI'
import { ThemeColors } from '../utils/ThemeColors'

@Component
export struct BackButton {
  /**
   * 按钮颜色，默认为主题色
   */
  @Prop color: string = ThemeColors.TEXT_NORMAL

  /**
   * 按钮大小，默认 24
   */
  @Prop size: number = 24

  /**
   * 自定义点击事件，如果不传则默认 router.back()
   */
  onCustomClick: () => void = () => {
    router.back()
  }

  build() {
    Row() {
      // 返回箭头图标
      Text('←')
        .fontSize(this.size)
        .fontColor(this.color)
        .fontWeight(FontWeight.Bold)
    }
    .width(44)
    .height(44)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .borderRadius(22)
    .backgroundColor(ThemeColors.BG_SECTION)
    .animation({
      duration: 150,
      curve: Curve.EaseInOut
    })
    .onClick(() => {
      this.onCustomClick()
    })
  }
}
