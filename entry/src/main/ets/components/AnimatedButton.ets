/**
 * AnimatedButton.ets
 * 带点击动画的按钮组件
 * 提供按压缩放效果，增强交互反馈
 */

import { ThemeColors } from '../utils/ThemeColors'

@Component
export struct AnimatedButton {
  /**
   * 按钮文字
   */
  @Prop label: string = ''

  /**
   * 按钮宽度
   */
  @Prop width: string | number = '100%'

  /**
   * 按钮高度
   */
  @Prop height: number = 50

  /**
   * 字体大小
   */
  @Prop fontSize: number = 17

  /**
   * 背景颜色
   */
  @Prop bgColor: string = ThemeColors.PRIMARY

  /**
   * 文字颜色
   */
  @Prop textColor: string = '#FFFFFF'

  /**
   * 圆角大小
   */
  @Prop borderRadius: number = 25

  /**
   * 是否禁用
   */
  @Prop disabled: boolean = false

  /**
   * 点击回调
   */
  onClick: () => void = () => {}

  /**
   * 按压缩放状态
   */
  @State isPressed: boolean = false

  build() {
    Button(this.label)
      .width(this.width)
      .height(this.height)
      .fontSize(this.fontSize)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.textColor)
      .backgroundColor(this.disabled ? '#B0C4DE' : this.bgColor)
      .borderRadius(this.borderRadius)
      .enabled(!this.disabled)
      .scale({
        x: this.isPressed ? 0.95 : 1.0,
        y: this.isPressed ? 0.95 : 1.0
      })
      .animation({
        duration: 100,
        curve: Curve.EaseInOut
      })
      .shadow(ThemeColors.SHADOW_BUTTON)
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
          this.isPressed = true
        } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.isPressed = false
        }
      })
      .onClick(() => {
        if (!this.disabled) {
          this.onClick()
        }
      })
  }
}
