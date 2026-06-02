/**
 * LineChart.ets
 * 折线图组件 - 使用 Canvas 绘制带坐标轴、网格线、数据点和触摸交互的折线图
 */

/**
 * 折线图数据点接口（用于多系列折线图）
 * @param x - X轴值（通常是日期字符串）
 * @param y - Y轴值（通常是金额数值）
 */
export interface LineDataPoint {
  x: string;
  y: number;
}

/**
 * 折线图数据系列接口
 * @param name - 系列名称（如"支出"、"收入"）
 * @param color - 线条颜色
 * @param data - 数据点数组
 */
export interface LineSeries {
  name: string;
  color: string;
  data: LineDataPoint[];
}

/**
 * 折线图数据项接口（单系列折线图）
 * @param date - 日期字符串（如 "01/15"、"2024-01-15"）
 * @param value - 数值（金额）
 */
export interface LineDataItem {
  date: string;
  value: number;
}

@Component
export struct LineChart {
  // ==================== 外部属性 ====================
  @Prop data: LineDataItem[] = [];          // 单系列折线图数据源
  @Prop series: LineSeries[] = [];          // 多系列折线图数据源
  @Prop title: string = '';                 // 图表标题
  @Prop color: string = '#4FC3F7';          // 折线颜色（单系列时使用）
  @Prop canvasWidth: number = 340;          // 画布宽度（vp）
  @Prop canvasHeight: number = 240;         // 画布高度（vp）
  @Prop showLegend: boolean = false;        // 是否显示图例

  // ==================== 内部状态 ====================
  @State touchIndex: number = -1;           // 当前触摸的数据点索引，-1 表示无触摸

  // Canvas 绘图上下文（ArkTS 要求通过 RenderingContextSettings 创建）
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  // 绘图区域边距（留出空间给坐标轴标签和标题）
  private paddingLeft: number = 60;         // 左边距：Y 轴标签区域
  private paddingRight: number = 20;        // 右边距
  private paddingTop: number = 30;          // 上边距：标题区域
  private paddingBottom: number = 50;       // 下边距：X 轴标签区域

  // 数据计算结果
  private minValue: number = 0;             // 数据最小值
  private maxValue: number = 0;             // 数据最大值
  private yTicks: number[] = [];            // Y 轴刻度值数组
  private pointXs: number[] = [];           // 每个数据点的 X 坐标
  private pointYs: number[] = [];           // 每个数据点的 Y 坐标

  // 动画相关
  private animProgress: number = 0;         // 动画当前进度 0~1
  private animTimer: number = -1;           // 动画定时器 ID

  /**
   * 组件即将出现时，预计算数据范围和刻度
   */
  aboutToAppear(): void {
    this.computeDataRange();
  }

  /**
   * 计算数据范围：最小值、最大值、Y 轴刻度
   * 自动选择"美观"的刻度值（整十、整百等）
   */
  private computeDataRange(): void {
    if (this.data.length === 0) {
      this.minValue = 0;
      this.maxValue = 100;
      this.yTicks = [0, 25, 50, 75, 100];
      return;
    }

    // 遍历数据找最小最大值
    let min: number = this.data[0].value;
    let max: number = this.data[0].value;
    for (const item of this.data) {
      if (item.value < min) {
        min = item.value;
      }
      if (item.value > max) {
        max = item.value;
      }
    }

    // 最小值向下取整，最大值向上取整，留出上下余量
    // 避免 min === max 时刻度退化
    if (min === max) {
      min = min >= 0 ? 0 : min - 10;
      max = max >= 0 ? max + 10 : 0;
    }

    const range: number = max - min;
    const margin: number = range * 0.15;  // 上下各留 15% 余量
    this.minValue = Math.max(0, min - margin);  // 不低于 0（金额通常非负）
    this.maxValue = max + margin;

    // 生成 Y 轴刻度（5 个刻度值，均匀分布）
    this.yTicks = [];
    const tickCount: number = 5;
    const tickStep: number = (this.maxValue - this.minValue) / (tickCount - 1);
    for (let i = 0; i < tickCount; i++) {
      this.yTicks.push(this.minValue + tickStep * i);
    }
  }

  /**
   * 计算绘制区域的实际宽高和数据点坐标
   * 在 Canvas onReady 回调中调用，确保画布尺寸已确定
   */
  private computeLayout(): void {
    const chartWidth: number = this.canvasWidth - this.paddingLeft - this.paddingRight;
    const chartHeight: number = this.canvasHeight - this.paddingTop - this.paddingBottom;

    this.pointXs = [];
    this.pointYs = [];

    if (this.data.length === 0) {
      return;
    }

    const valueRange: number = this.maxValue - this.minValue;

    for (let i = 0; i < this.data.length; i++) {
      // X 坐标：等间距分布，第一个点和最后一个点留出半间距
      let x: number;
      if (this.data.length === 1) {
        x = this.paddingLeft + chartWidth / 2;
      } else {
        x = this.paddingLeft + (i / (this.data.length - 1)) * chartWidth;
      }

      // Y 坐标：值越大越靠上（Canvas Y 轴向下）
      let y: number;
      if (valueRange === 0) {
        y = this.paddingTop + chartHeight / 2;
      } else {
        const ratio: number = (this.data[i].value - this.minValue) / valueRange;
        y = this.paddingTop + chartHeight * (1 - ratio);
      }

      this.pointXs.push(x);
      this.pointYs.push(y);
    }
  }

  /**
   * 将十六进制颜色字符串转换为带透明度的 rgba 格式
   * @param hex - 十六进制颜色（如 '#4FC3F7'）
   * @param alpha - 透明度（0~1）
   * @returns rgba 颜色字符串
   */
  private hexToRgba(hex: string, alpha: number): string {
    // 去掉 # 前缀
    const hexStr: string = hex.replace('#', '');
    const r: number = parseInt(hexStr.substring(0, 2), 16);
    const g: number = parseInt(hexStr.substring(2, 4), 16);
    const b: number = parseInt(hexStr.substring(4, 6), 16);
    return 'rgba(' + r + ',' + g + ',' + b + ',' + alpha + ')';
  }

  /**
   * 格式化金额数值：大于等于 10000 显示为 x.x 万，否则保留整数或一位小数
   * @param value - 金额数值
   * @returns 格式化后的字符串
   */
  private formatAmount(value: number): string {
    if (Math.abs(value) >= 10000) {
      return (value / 10000).toFixed(1) + '万';
    }
    // 如果是整数直接显示，否则保留一位小数
    if (value === Math.floor(value)) {
      return value.toFixed(0);
    }
    return value.toFixed(1);
  }

  /**
   * 核心绘制方法：绘制完整的折线图
   * @param ctx - Canvas 2D 绘图上下文
   * @param progress - 绘制进度，范围 0~1，用于折线生长动画
   */
  private drawChart(ctx: CanvasRenderingContext2D, progress: number): void {
    const w: number = this.canvasWidth;
    const h: number = this.canvasHeight;

    // 清空画布
    ctx.clearRect(0, 0, w, h);

    // 绘制白色背景
    ctx.fillStyle = '#FFFFFF';
    ctx.fillRect(0, 0, w, h);

    // 数据为空时绘制空状态提示
    if (this.data.length === 0) {
      ctx.fillStyle = '#999999';
      ctx.font = '14px sans-serif';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText('暂无数据', w / 2, h / 2);
      return;
    }

    const chartLeft: number = this.paddingLeft;
    const chartRight: number = w - this.paddingRight;
    const chartTop: number = this.paddingTop;
    const chartBottom: number = h - this.paddingBottom;
    const chartWidth: number = chartRight - chartLeft;
    const chartHeight: number = chartBottom - chartTop;

    // ==================== 1. 绘制标题 ====================
    if (this.title.length > 0) {
      ctx.fillStyle = '#333333';
      ctx.font = 'bold 15px sans-serif';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'top';
      ctx.fillText(this.title, w / 2, 8);
    }

    // ==================== 2. 绘制网格线（水平虚线） ====================
    ctx.strokeStyle = '#EEEEEE';
    ctx.lineWidth = 1;
    ctx.setLineDash([4, 4]);  // 设置虚线样式
    for (let i = 0; i < this.yTicks.length; i++) {
      const value: number = this.yTicks[i];
      const ratio: number = (value - this.minValue) / (this.maxValue - this.minValue);
      const y: number = chartBottom - ratio * chartHeight;
      ctx.beginPath();
      ctx.moveTo(chartLeft, y);
      ctx.lineTo(chartRight, y);
      ctx.stroke();
    }
    ctx.setLineDash([]);  // 恢复实线

    // ==================== 3. 绘制坐标轴 ====================
    ctx.strokeStyle = '#CCCCCC';
    ctx.lineWidth = 1;
    // Y 轴（左侧竖线）
    ctx.beginPath();
    ctx.moveTo(chartLeft, chartTop);
    ctx.lineTo(chartLeft, chartBottom);
    ctx.stroke();
    // X 轴（底部横线）
    ctx.beginPath();
    ctx.moveTo(chartLeft, chartBottom);
    ctx.lineTo(chartRight, chartBottom);
    ctx.stroke();

    // ==================== 4. 绘制 Y 轴刻度标签 ====================
    ctx.fillStyle = '#888888';
    ctx.font = '11px sans-serif';
    ctx.textAlign = 'right';
    ctx.textBaseline = 'middle';
    for (let i = 0; i < this.yTicks.length; i++) {
      const value: number = this.yTicks[i];
      const ratio: number = (value - this.minValue) / (this.maxValue - this.minValue);
      const y: number = chartBottom - ratio * chartHeight;
      ctx.fillText(this.formatAmount(value), chartLeft - 8, y);
    }

    // ==================== 5. 绘制 X 轴日期标签（旋转 45 度） ====================
    ctx.fillStyle = '#888888';
    ctx.font = '11px sans-serif';
    ctx.textAlign = 'right';
    ctx.textBaseline = 'top';
    for (let i = 0; i < this.data.length; i++) {
      const x: number = this.pointXs[i];
      const y: number = chartBottom + 6;

      // 保存画布状态，旋转绘制日期文字
      ctx.save();
      ctx.translate(x, y);
      ctx.rotate(-Math.PI / 4);  // 逆时针旋转 45 度
      ctx.fillText(this.data[i].date, 0, 0);
      ctx.restore();
    }

    // ==================== 6. 绘制折线渐变填充区域 ====================
    if (this.data.length >= 2) {
      // 创建从上到下的渐变（折线下方半透明填充）
      const gradient: CanvasGradient = ctx.createLinearGradient(0, chartTop, 0, chartBottom);
      gradient.addColorStop(0, this.hexToRgba(this.color, 0.3));
      gradient.addColorStop(1, this.hexToRgba(this.color, 0.02));

      // 填充区域路径：折线 + 底部闭合
      ctx.beginPath();
      // 计算动画进度下的绘制终点索引
      const endIndex: number = Math.min(
        Math.ceil(progress * this.data.length),
        this.data.length
      );
      if (endIndex > 0) {
        ctx.moveTo(this.pointXs[0], chartBottom);  // 起点在底部
        for (let i = 0; i < endIndex; i++) {
          ctx.lineTo(this.pointXs[i], this.pointYs[i]);
        }
        // 最后一个点根据进度插值
        if (endIndex < this.data.length && progress < 1) {
          const frac: number = (progress * this.data.length) - Math.floor(progress * this.data.length);
          const lastX: number = this.pointXs[endIndex - 1] +
            frac * (this.pointXs[endIndex] - this.pointXs[endIndex - 1]);
          const lastY: number = this.pointYs[endIndex - 1] +
            frac * (this.pointYs[endIndex] - this.pointYs[endIndex - 1]);
          ctx.lineTo(lastX, lastY);
          ctx.lineTo(lastX, chartBottom);
        } else {
          ctx.lineTo(this.pointXs[endIndex - 1], chartBottom);
        }
        ctx.closePath();
        ctx.fillStyle = gradient;
        ctx.fill();
      }
    }

    // ==================== 7. 绘制折线 ====================
    if (this.data.length >= 2) {
      ctx.strokeStyle = this.color;
      ctx.lineWidth = 2.5;
      ctx.lineJoin = 'round';   // 折线拐角圆滑
      ctx.lineCap = 'round';    // 线帽圆滑
      ctx.beginPath();
      ctx.moveTo(this.pointXs[0], this.pointYs[0]);
      for (let i = 1; i < this.data.length; i++) {
        // 根据动画进度决定绘制到哪里
        const drawRatio: number = progress * (this.data.length - 1);
        if (i <= drawRatio) {
          ctx.lineTo(this.pointXs[i], this.pointYs[i]);
        } else {
          // 在两个点之间插值，实现平滑生长效果
          const frac: number = drawRatio - (i - 1);
          const interpX: number = this.pointXs[i - 1] +
            frac * (this.pointXs[i] - this.pointXs[i - 1]);
          const interpY: number = this.pointYs[i - 1] +
            frac * (this.pointYs[i] - this.pointYs[i - 1]);
          ctx.lineTo(interpX, interpY);
          break;
        }
      }
      ctx.stroke();
    }

    // ==================== 8. 绘制数据点和数值标签 ====================
    const drawCount: number = Math.ceil(progress * this.data.length);
    for (let i = 0; i < drawCount && i < this.data.length; i++) {
      const x: number = this.pointXs[i];
      const y: number = this.pointYs[i];
      const isTouched: boolean = i === this.touchIndex;

      // 绘制数据点圆圈
      ctx.beginPath();
      if (isTouched) {
        // 触摸状态：大圆 + 外圈光晕
        ctx.fillStyle = this.color;
        ctx.arc(x, y, 7, 0, 2 * Math.PI);
        ctx.fill();
        // 外圈白色边框
        ctx.strokeStyle = '#FFFFFF';
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.arc(x, y, 7, 0, 2 * Math.PI);
        ctx.stroke();
        // 光晕效果
        ctx.beginPath();
        ctx.arc(x, y, 12, 0, 2 * Math.PI);
        ctx.fillStyle = this.hexToRgba(this.color, 0.2);
        ctx.fill();
      } else {
        // 普通状态：白色填充 + 彩色边框
        ctx.fillStyle = '#FFFFFF';
        ctx.arc(x, y, 4, 0, 2 * Math.PI);
        ctx.fill();
        ctx.strokeStyle = this.color;
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.arc(x, y, 4, 0, 2 * Math.PI);
        ctx.stroke();
      }

      // 在数据点上方绘制数值
      ctx.fillStyle = isTouched ? '#333333' : '#666666';
      ctx.font = isTouched ? 'bold 12px sans-serif' : '11px sans-serif';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'bottom';
      ctx.fillText(this.formatAmount(this.data[i].value), x, y - (isTouched ? 16 : 10));
    }

    // ==================== 9. 绘制触摸指示线和提示框 ====================
    if (this.touchIndex >= 0 && this.touchIndex < this.data.length) {
      const tx: number = this.pointXs[this.touchIndex];
      const ty: number = this.pointYs[this.touchIndex];

      // 绘制垂直虚线指示线
      ctx.strokeStyle = this.hexToRgba(this.color, 0.5);
      ctx.lineWidth = 1;
      ctx.setLineDash([3, 3]);
      ctx.beginPath();
      ctx.moveTo(tx, chartTop);
      ctx.lineTo(tx, chartBottom);
      ctx.stroke();
      ctx.setLineDash([]);

      // 绘制提示框背景
      const tooltipText: string =
        this.data[this.touchIndex].date + ': ' + this.formatAmount(this.data[this.touchIndex].value);
      ctx.font = 'bold 12px sans-serif';
      const textWidth: number = ctx.measureText(tooltipText).width;
      const boxW: number = textWidth + 16;
      const boxH: number = 26;
      let boxX: number = tx - boxW / 2;
      let boxY: number = ty - 40;

      // 防止提示框超出画布左边界
      if (boxX < 4) {
        boxX = 4;
      }
      // 防止提示框超出画布右边界
      if (boxX + boxW > this.canvasWidth - 4) {
        boxX = this.canvasWidth - 4 - boxW;
      }
      // 防止提示框超出画布顶部
      if (boxY < 4) {
        boxY = ty + 20;
      }

      // 绘制圆角矩形背景
      const cornerRadius: number = 6;
      ctx.fillStyle = this.color;
      ctx.beginPath();
      ctx.moveTo(boxX + cornerRadius, boxY);
      ctx.lineTo(boxX + boxW - cornerRadius, boxY);
      ctx.arcTo(boxX + boxW, boxY, boxX + boxW, boxY + cornerRadius, cornerRadius);
      ctx.lineTo(boxX + boxW, boxY + boxH - cornerRadius);
      ctx.arcTo(boxX + boxW, boxY + boxH, boxX + boxW - cornerRadius, boxY + boxH, cornerRadius);
      ctx.lineTo(boxX + cornerRadius, boxY + boxH);
      ctx.arcTo(boxX, boxY + boxH, boxX, boxY + boxH - cornerRadius, cornerRadius);
      ctx.lineTo(boxX, boxY + cornerRadius);
      ctx.arcTo(boxX, boxY, boxX + cornerRadius, boxY, cornerRadius);
      ctx.closePath();
      ctx.fill();

      // 绘制提示框文字
      ctx.fillStyle = '#FFFFFF';
      ctx.font = 'bold 12px sans-serif';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText(tooltipText, boxX + boxW / 2, boxY + boxH / 2);
    }
  }

  /**
   * 触摸事件处理：根据触摸点坐标查找最近的数据点
   * 使用最近邻算法，找到距离最近的数据点
   */
  private handleTouch(event: TouchEvent): void {
    if (this.data.length === 0) {
      return;
    }

    const touchX: number = event.touches[0].x;
    const touchY: number = event.touches[0].y;

    // 查找最近的数据点
    let minDist: number = Number.MAX_VALUE;
    let nearest: number = -1;
    for (let i = 0; i < this.pointXs.length; i++) {
      const dx: number = touchX - this.pointXs[i];
      const dy: number = touchY - this.pointYs[i];
      const dist: number = Math.sqrt(dx * dx + dy * dy);
      if (dist < minDist) {
        minDist = dist;
        nearest = i;
      }
    }

    // 只有在合理距离内才触发高亮（防止触摸空白区域误触发）
    const chartBottom: number = this.canvasHeight - this.paddingBottom;
    const chartTop: number = this.paddingTop;
    if (touchY >= chartTop - 20 && touchY <= chartBottom + 20 && minDist < 50) {
      if (nearest !== this.touchIndex) {
        this.touchIndex = nearest;
        this.drawChart(this.context, 1);
      }
    } else {
      // 触摸点不在图表区域，取消高亮
      if (this.touchIndex !== -1) {
        this.touchIndex = -1;
        this.drawChart(this.context, 1);
      }
    }
  }

  /**
   * 启动折线生长动画
   * 通过定时器逐步增加进度，模拟折线从左到右依次绘制的效果
   * @param ctx - Canvas 2D 绘图上下文
   */
  private startAnimation(ctx: CanvasRenderingContext2D): void {
    // 清除可能残留的旧动画定时器
    if (this.animTimer !== -1) {
      clearInterval(this.animTimer);
      this.animTimer = -1;
    }

    this.animProgress = 0;
    const duration: number = 1000; // 动画总时长（毫秒）
    const interval: number = 16;   // 刷新间隔，约 60fps
    const step: number = interval / duration;

    this.animTimer = setInterval(() => {
      this.animProgress += step;

      // 动画结束
      if (this.animProgress >= 1) {
        this.animProgress = 1;
        clearInterval(this.animTimer);
        this.animTimer = -1;
      }

      // 按当前进度重绘折线图
      this.drawChart(ctx, this.animProgress);
    }, interval) as number;
  }

  build() {
    Column() {
      // ==================== 折线图画布 ====================
      Canvas(this.context)
        .width(this.canvasWidth)
        .height(this.canvasHeight)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .shadow({
          radius: 8,
          color: 'rgba(0,0,0,0.08)',
          offsetX: 0,
          offsetY: 2
        })
        .onReady(() => {
          // 重新计算数据范围（确保与最新 data 同步）
          this.computeDataRange();
          // 计算布局和数据点坐标
          this.computeLayout();
          // 启动入场动画
          this.startAnimation(this.context);
        })
        .onTouch((event: TouchEvent) => {
          // 仅响应按下和移动事件，抬起时清除触摸状态
          if (event.type === TouchType.Down || event.type === TouchType.Move) {
            this.handleTouch(event);
          } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
            if (this.touchIndex !== -1) {
              this.touchIndex = -1;
              this.drawChart(this.context, 1);
            }
          }
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .padding(12)
  }
}
