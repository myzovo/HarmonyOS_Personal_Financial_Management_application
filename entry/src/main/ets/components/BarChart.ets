/**
 * BarChart.ets
 * 柱状图组件 - 使用 Canvas 绘制带动画的柱状图
 * 支持触摸高亮、数值显示、自定义颜色
 */

/**
 * 柱状图数据项接口
 * @param name  - X 轴标签名称（如分类名）
 * @param value - 数值（金额）
 * @param color - 柱状条颜色
 */
export interface BarDataItem {
  name: string;
  value: number;
  color: string;
}

/**
 * 柱状图系列配置接口（用于多系列柱状图）
 * @param name  - 系列名称（如"支出"、"收入"）
 * @param color - 该系列柱子的颜色
 */
export interface BarSeries {
  name: string;
  color: string;
}

@Component
export struct BarChart {
  // ==================== 外部属性 ====================
  @Prop data: BarDataItem[] = [];          // 数据项数组
  @Prop series: BarSeries[] = [];          // 多系列配置
  @Prop title: string = '';                // 图表标题
  @Prop chartWidth: number = 300;          // 图表宽度
  @Prop chartHeight: number = 220;         // 图表高度
  @Prop showLegend: boolean = false;       // 是否显示图例

  // ==================== 内部状态 ====================
  @State animProgress: number = 0;         // 动画进度 0~1
  @State highlightIndex: number = -1;      // 当前高亮柱子索引，-1 表示无高亮

  // Canvas 绘图上下文
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  // 绘图区域边距
  private paddingLeft: number = 55;
  private paddingRight: number = 20;
  private paddingTop: number = 30;
  private paddingBottom: number = 45;

  // 动画定时器
  private animTimer: number = -1;

  // 柱子位置缓存，用于触摸命中检测
  private barRects: Rect[] = [];

  /**
   * 获取所有数据中的最大 Y 值
   * 用于计算 Y 轴刻度上限
   */
  private getMaxY(): number {
    let maxY: number = 0;
    for (const item of this.data) {
      if (item.value > maxY) {
        maxY = item.value;
      }
    }
    if (maxY === 0) {
      return 100;
    }
    // 向上取整到合适的刻度值
    const magnitude: number = Math.pow(10, Math.floor(Math.log10(maxY)));
    return Math.ceil(maxY / magnitude) * magnitude;
  }

  /**
   * 绘制柱状图
   * @param ctx      - Canvas 2D 绘图上下文
   * @param progress - 绘制动画进度 0~1
   */
  private drawChart(ctx: CanvasRenderingContext2D, progress: number): void {
    const w: number = this.chartWidth;
    const h: number = this.chartHeight;

    // 清空画布
    ctx.clearRect(0, 0, w, h);

    // 计算绘图区域边界
    const chartLeft: number = this.paddingLeft;
    const chartRight: number = w - this.paddingRight;
    const chartTop: number = this.paddingTop;
    const chartBottom: number = h - this.paddingBottom;
    const chartWidth: number = chartRight - chartLeft;
    const chartHeight: number = chartBottom - chartTop;

    const maxY: number = this.getMaxY();
    const count: number = this.data.length;

    // 无数据时绘制提示
    if (count === 0) {
      ctx.fillStyle = '#CCCCCC';
      ctx.font = '14px sans-serif';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText('暂无数据', w / 2, h / 2);
      return;
    }

    // ===== 绘制标题 =====
    if (this.title.length > 0) {
      ctx.fillStyle = '#333333';
      ctx.font = 'bold 14px sans-serif';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'top';
      ctx.fillText(this.title, w / 2, 8);
    }

    // ===== 绘制网格线（水平虚线，5 条） =====
    ctx.strokeStyle = '#EEEEEE';
    ctx.lineWidth = 0.5;
    ctx.setLineDash([4, 4]);
    for (let i: number = 0; i <= 4; i++) {
      const y: number = chartTop + (chartHeight / 4) * i;
      ctx.beginPath();
      ctx.moveTo(chartLeft, y);
      ctx.lineTo(chartRight, y);
      ctx.stroke();
    }
    ctx.setLineDash([]);

    // ===== 绘制坐标轴 =====
    ctx.strokeStyle = '#DDDDDD';
    ctx.lineWidth = 1;
    // Y 轴
    ctx.beginPath();
    ctx.moveTo(chartLeft, chartTop);
    ctx.lineTo(chartLeft, chartBottom);
    ctx.stroke();
    // X 轴
    ctx.beginPath();
    ctx.moveTo(chartLeft, chartBottom);
    ctx.lineTo(chartRight, chartBottom);
    ctx.stroke();

    // ===== 绘制 Y 轴刻度标签（金额） =====
    ctx.fillStyle = '#999999';
    ctx.font = '11px sans-serif';
    ctx.textAlign = 'right';
    ctx.textBaseline = 'middle';
    for (let i: number = 0; i <= 4; i++) {
      const y: number = chartTop + (chartHeight / 4) * i;
      const value: number = maxY - (maxY / 4) * i;
      // 格式化金额显示
      let label: string;
      if (value >= 10000) {
        label = `${(value / 10000).toFixed(1)}万`;
      } else if (value >= 1000) {
        label = `${(value / 1000).toFixed(1)}k`;
      } else {
        label = value.toFixed(0);
      }
      ctx.fillText(label, chartLeft - 8, y);
    }

    // ===== 绘制柱状条 =====
    const barGroupWidth: number = chartWidth / count;
    const barPadding: number = barGroupWidth * 0.2;  // 柱子左右间距
    const barWidth: number = barGroupWidth - barPadding * 2;

    // 清空柱子位置缓存
    this.barRects = [];

    for (let i: number = 0; i < count; i++) {
      const item: BarDataItem = this.data[i];
      const isHighlight: boolean = (i === this.highlightIndex);

      // 柱子 X 坐标
      const barX: number = chartLeft + barGroupWidth * i + barPadding;
      // 柱子高度（带动画）
      const barHeight: number = (item.value / maxY) * chartHeight * progress;
      const barY: number = chartBottom - barHeight;

      // 缓存柱子位置
      this.barRects.push({ x: barX, y: barY, w: barWidth, h: barHeight });

      // 绘制圆角矩形柱子
      const radius: number = Math.min(4, barWidth / 2);
      ctx.fillStyle = item.color;
      ctx.globalAlpha = isHighlight ? 1.0 : 0.85;

      ctx.beginPath();
      ctx.moveTo(barX + radius, barY);
      ctx.lineTo(barX + barWidth - radius, barY);
      ctx.arcTo(barX + barWidth, barY, barX + barWidth, barY + radius, radius);
      ctx.lineTo(barX + barWidth, chartBottom);
      ctx.lineTo(barX, chartBottom);
      ctx.lineTo(barX, barY + radius);
      ctx.arcTo(barX, barY, barX + radius, barY, radius);
      ctx.closePath();
      ctx.fill();

      // 高亮时绘制边框
      if (isHighlight) {
        ctx.strokeStyle = item.color;
        ctx.lineWidth = 2;
        ctx.stroke();
      }

      ctx.globalAlpha = 1.0;

      // 在柱子顶部显示数值（动画完成后）
      if (progress >= 1 && item.value > 0) {
        ctx.fillStyle = '#555555';
        ctx.font = isHighlight ? 'bold 11px sans-serif' : '10px sans-serif';
        ctx.textAlign = 'center';
        ctx.textBaseline = 'bottom';
        // 格式化数值
        let valueLabel: string;
        if (item.value >= 10000) {
          valueLabel = `${(item.value / 10000).toFixed(1)}万`;
        } else if (item.value >= 1000) {
          valueLabel = `${(item.value / 1000).toFixed(1)}k`;
        } else {
          valueLabel = item.value.toFixed(0);
        }
        ctx.fillText(valueLabel, barX + barWidth / 2, barY - 4);
      }

      // 绘制 X 轴标签（名称）
      ctx.fillStyle = isHighlight ? '#333333' : '#999999';
      ctx.font = isHighlight ? 'bold 11px sans-serif' : '10px sans-serif';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'top';
      // 截断过长的名称
      let nameLabel: string = item.name;
      if (nameLabel.length > 4) {
        nameLabel = nameLabel.substring(0, 4) + '..';
      }
      ctx.fillText(nameLabel, barX + barWidth / 2, chartBottom + 6);
    }
  }

  /**
   * 启动绘制动画
   * 柱子从底部生长到目标高度
   */
  private startAnimation(): void {
    if (this.animTimer !== -1) {
      clearInterval(this.animTimer);
      this.animTimer = -1;
    }

    this.animProgress = 0;
    const duration: number = 800;
    const interval: number = 16;
    const step: number = interval / duration;

    this.animTimer = setInterval(() => {
      this.animProgress += step;
      if (this.animProgress >= 1) {
        this.animProgress = 1;
        clearInterval(this.animTimer);
        this.animTimer = -1;
      }
      this.drawChart(this.context, this.animProgress);
    }, interval) as number;
  }

  /**
   * 触摸命中检测
   * 判断触摸点是否落在某个柱子上
   * @param x - 触摸点 X 坐标
   * @param y - 触摸点 Y 坐标
   * @returns 命中的柱子索引，未命中返回 -1
   */
  private hitTest(x: number, y: number): number {
    for (let i: number = 0; i < this.barRects.length; i++) {
      const r: Rect = this.barRects[i];
      if (x >= r.x && x <= r.x + r.w && y >= r.y && y <= r.y + r.h) {
        return i;
      }
    }
    return -1;
  }

  build() {
    Column() {
      // ===== 柱状图画布 =====
      Canvas(this.context)
        .width(this.chartWidth)
        .height(this.chartHeight)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .onReady(() => {
          this.drawChart(this.context, 1);
          this.startAnimation();
        })
        .onTouch((event: TouchEvent) => {
          if (event.type === TouchType.Move || event.type === TouchType.Down) {
            const touch: TouchObject = event.touches[0];
            const index: number = this.hitTest(touch.x, touch.y);
            if (index !== this.highlightIndex) {
              this.highlightIndex = index;
              this.drawChart(this.context, 1);
            }
          } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
            this.highlightIndex = -1;
            this.drawChart(this.context, 1);
          }
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .padding(8)
  }
}

/**
 * 柱子位置矩形（用于触摸命中检测）
 */
interface Rect {
  x: number;
  y: number;
  w: number;
  h: number;
}
