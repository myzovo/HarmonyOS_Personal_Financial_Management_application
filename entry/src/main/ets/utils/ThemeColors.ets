/**
 * ThemeColors.ets
 * 主题颜色常量定义
 * 统一管理应用的颜色方案，确保视觉一致性
 */

/**
 * 阴影选项接口
 */
interface ShadowOptions {
  radius: number
  color: string
  offsetX: number
  offsetY: number
}

/**
 * 主题颜色常量
 * 包含主色调、功能色、中性色等
 */
export class ThemeColors {
  // ==================== 主色调 ====================

  /** 主题蓝 - 按钮、链接、选中状态 */
  static readonly PRIMARY: string = '#4A90D9'

  /** 主题蓝浅色 - 背景、卡片高亮 */
  static readonly PRIMARY_LIGHT: string = '#E8F0FE'

  /** 主题蓝深色 - 按下状态 */
  static readonly PRIMARY_DARK: string = '#3A7BC8'

  // ==================== 功能色 ====================

  /** 支出红 - 支出金额、支出指示 */
  static readonly EXPENSE: string = '#FF6B6B'

  /** 支出红浅色 - 背景色 */
  static readonly EXPENSE_LIGHT: string = '#FFF2F0'

  /** 收入绿 - 收入金额、收入指示 */
  static readonly INCOME: string = '#52C41A'

  /** 收入绿浅色 - 背景色 */
  static readonly INCOME_LIGHT: string = '#F6FFED'

  /** 警告橙 - 警告提示 */
  static readonly WARNING: string = '#FAAD14'

  /** 错误红 - 错误提示、删除操作 */
  static readonly ERROR: string = '#FF4D4F'

  /** 成功绿 - 成功提示 */
  static readonly SUCCESS: string = '#52C41A'

  // ==================== 中性色 ====================

  /** 主要文字色 - 标题、重要信息 */
  static readonly TEXT_PRIMARY: string = '#1A1A1A'

  /** 常规文字色 - 正文内容 */
  static readonly TEXT_NORMAL: string = '#333333'

  /** 次要文字色 - 辅助信息 */
  static readonly TEXT_SECONDARY: string = '#666666'

  /** 占位文字色 - 提示文字 */
  static readonly TEXT_PLACEHOLDER: string = '#999999'

  /** 禁用文字色 */
  static readonly TEXT_DISABLED: string = '#CCCCCC'

  // ==================== 背景色 ====================

  /** 页面背景色 */
  static readonly BG_PAGE: string = '#F5F6FA'

  /** 卡片背景色 */
  static readonly BG_CARD: string = '#FFFFFF'

  /** 区域背景色 - 分组标题背景 */
  static readonly BG_SECTION: string = '#F8F8F8'

  /** 输入框背景色 */
  static readonly BG_INPUT: string = '#F5F6FA'

  /** 遮罩层背景色 */
  static readonly BG_OVERLAY: string = 'rgba(0, 0, 0, 0.4)'

  // ==================== 边框色 ====================

  /** 默认边框色 */
  static readonly BORDER: string = '#EEEEEE'

  /** 分割线色 */
  static readonly DIVIDER: string = '#F0F0F0'

  /** 输入框边框色 */
  static readonly BORDER_INPUT: string = '#DDDDDD'

  // ==================== 图表色 ====================

  /** 饼图配色方案 */
  static readonly CHART_COLORS: string[] = [
    '#FF6384', '#36A2EB', '#FFCE56', '#4BC0C0',
    '#9966FF', '#FF9F40', '#C9CBCF', '#7BC8A4',
    '#E76F51', '#2A9D8F', '#264653', '#F4A261'
  ]

  // ==================== 阴影 ====================

  /** 卡片阴影 */
  static readonly SHADOW_CARD: ShadowOptions = {
    radius: 12,
    color: 'rgba(0, 0, 0, 0.08)',
    offsetX: 0,
    offsetY: 4
  }

  /** 导航栏阴影 */
  static readonly SHADOW_NAV: ShadowOptions = {
    radius: 4,
    color: 'rgba(0, 0, 0, 0.05)',
    offsetX: 0,
    offsetY: 2
  }

  /** 底部导航栏阴影 */
  static readonly SHADOW_TAB: ShadowOptions = {
    radius: 16,
    color: 'rgba(0, 0, 0, 0.08)',
    offsetX: 0,
    offsetY: -4
  }

  /** 按钮阴影 */
  static readonly SHADOW_BUTTON: ShadowOptions = {
    radius: 8,
    color: 'rgba(74, 144, 217, 0.3)',
    offsetX: 0,
    offsetY: 4
  }

  /** 浮动按钮阴影 */
  static readonly SHADOW_FAB: ShadowOptions = {
    radius: 12,
    color: 'rgba(74, 144, 217, 0.4)',
    offsetX: 0,
    offsetY: 4
  }
}
