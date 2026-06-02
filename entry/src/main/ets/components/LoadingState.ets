/**
 * LoadingState.ets
 * 加载状态组件 - 用于数据加载时的友好提示
 * 提供统一的加载样式和动画效果
 */

import { ThemeColors } from '../utils/ThemeColors'

@Component
export struct LoadingState {
  /**
   * 加载提示文字
   */
  @Prop message: string = '加载中...'

  /**
   * 是否显示加载动画
   */
  @Prop showAnimation: boolean = true

  /**
   * 动画旋转角度
   */
  @State rotationAngle: number = 0

  /**
   * 组件即将显示时启动动画
   */
  aboutToAppear(): void {
    if (this.showAnimation) {
      this.startRotationAnimation()
    }
  }

  /**
   * 启动旋转动画
   */
  startRotationAnimation(): void {
    // 持续旋转动画
    this.rotationAngle = 360
  }

  build() {
    Column() {
      // 加载动画图标
      if (this.showAnimation) {
        Text('⏳')
          .fontSize(36)
          .rotate({ angle: this.rotationAngle })
          .animation({
            duration: 1000,
            iterations: -1, // 无限循环
            curve: Curve.Linear
          })
          .margin({ bottom: 16 })
      }

      // 加载提示文字
      Text(this.message)
        .fontSize(14)
        .fontColor(ThemeColors.TEXT_PLACEHOLDER)
    }
    .width('100%')
    .padding({ top: 40, bottom: 40 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
