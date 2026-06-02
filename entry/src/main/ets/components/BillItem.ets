/**
 * BillItem.ets
 * 账单列表项组件 - 展示单条账单信息，支持删除和长按编辑操作
 */

import { Bill, BillType } from '../model/Bill'
import { ThemeColors } from '../utils/ThemeColors'

@Component
export struct BillItem {
  /**
   * 分类名称，例如 "餐饮"、"交通"
   */
  @Prop category: string = ''

  /**
   * 分类图标（emoji），例如 "🍔"、"🚗"
   */
  @Prop icon: string = ''

  /**
   * 金额数值
   */
  @Prop amount: number = 0

  /**
   * 账单类型：0-支出，1-收入
   */
  @Prop type: number = 0

  /**
   * 账单日期，格式为 YYYY-MM-DD
   */
  @Prop date: string = ''

  /**
   * 账单描述/备注
   */
  @Prop description: string = ''

  /**
   * 账单唯一标识，用于删除操作
   */
  @Prop billId: string = ''

  /**
   * 删除回调函数，传递账单 id
   */
  onDelete: (id: string) => void = () => {}

  /**
   * 编辑回调函数，传递完整账单对象
   */
  onEdit: (bill: Bill) => void = () => {}

  build() {
    Column() {
      // 主内容区域
      Row() {
        // 左侧：图标和分类信息
        Row() {
          // 分类图标
          Text(this.icon)
            .fontSize(28)
            .margin({ right: 12 })

          // 分类名称和描述
          Column() {
            Text(this.category)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(ThemeColors.TEXT_NORMAL)

            // 描述文字（仅在有描述时显示）
            if (this.description) {
              Text(this.description)
                .fontSize(12)
                .fontColor(ThemeColors.TEXT_PLACEHOLDER)
                .margin({ top: 4 })
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
          }
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)
        .alignItems(VerticalAlign.Center)

        // 右侧：金额、日期和删除按钮
        Column() {
          // 金额显示：支出为红色，收入为绿色
          Text(`${this.type === BillType.EXPENSE ? '-' : '+'} ¥${this.amount.toFixed(2)}`)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.type === BillType.EXPENSE ? ThemeColors.ERROR : ThemeColors.SUCCESS)

          // 日期显示
          Text(this.date)
            .fontSize(12)
            .fontColor(ThemeColors.TEXT_PLACEHOLDER)
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.End)

        // 删除按钮
        Button('删除')
          .type(ButtonType.Normal)
          .fontSize(12)
          .fontColor('#FFFFFF')
          .backgroundColor(ThemeColors.ERROR)
          .borderRadius(12)
          .height(28)
          .padding({ left: 10, right: 10 })
          .margin({ left: 8 })
          .onClick(() => {
            this.onDelete(this.billId)
          })
      }
      .width('100%')
      .padding({
        left: 16,
        right: 16,
        top: 14,
        bottom: 14
      })
      .backgroundColor(ThemeColors.BG_CARD)
      .gesture(
        LongPressGesture()
          .onAction(() => {
            // 长按触发编辑回调
            this.onEdit({
              id: this.billId,
              amount: this.amount,
              type: this.type as BillType,
              category: this.category,
              description: this.description,
              date: this.date,
              createdAt: '',
              updatedAt: ''
            })
          })
      )

      // 分割线
      Divider()
        .strokeWidth(0.5)
        .color(ThemeColors.DIVIDER)
        .margin({ left: 56 }) // 对齐图标右侧
    }
  }
}
