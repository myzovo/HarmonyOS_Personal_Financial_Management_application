/**
 * PieChart.ets
 * 饼图组件 - 使用 Canvas 绘制带动画和触摸交互的饼图
 */

/**
 * 饼图数据项接口
 * @param name - 分类名称
 * @param value - 数值
 * @param color - 扇形颜色（十六进制字符串，如 '#FF6384'）
 */
export interface PieDataItem {
  name: string;
  value: number;
  color: string;
}

@Component
export struct PieChart {
  // ==================== 外部属性 ====================
  @Prop data: PieDataItem[] = [];        // 饼图数据源
  @Prop chartSize: number = 200;         // 饼图尺寸（宽高，单位 vp）
  @Prop title: string = '';              // 图表标题（显示在饼图中心）

  // ==================== 内部状态 ====================
  @State currentIndex: number = -1;      // 当前高亮扇形索引，-1 表示无高亮

  // Canvas 绘图上下文（ArkTS 要求通过 RenderingContextSettings 创建）
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  // 几何计算数据
  private angles: number[] = [];         // 每个扇形的起始角度（弧度）
  private sweeps: number[] = [];         // 每个扇形的扫过角度（弧度）
  private total: number = 0;             // 所有数据项数值之和
  private centerX: number = 0;           // 圆心 X 坐标
  private centerY: number = 0;           // 圆心 Y 坐标
  private radius: number = 0;            // 饼图半径

  // 动画相关
  private animProgress: number = 0;      // 动画当前进度 0~1
  private animTimer: number = -1;        // 动画定时器 ID

  /**
   * 组件即将出现时，预计算几何数据
   */
  aboutToAppear(): void {
    this.computeGeometry();
  }

  /**
   * 计算饼图几何信息：总和、每个扇形的起始角度和扫过角度
   * 从 12 点钟方向（-PI/2）开始，顺时针绘制
   */
  private computeGeometry(): void {
    this.total = 0;
    for (const item of this.data) {
      this.total += item.value;
    }
    if (this.total === 0) {
      this.angles = [];
      this.sweeps = [];
      return;
    }

    this.angles = [];
    this.sweeps = [];
    let startAngle: number = -Math.PI / 2; // 从 12 点钟方向开始

    for (const item of this.data) {
      const sweep: number = (item.value / this.total) * 2 * Math.PI;
      this.angles.push(startAngle);
      this.sweeps.push(sweep);
      startAngle += sweep;
    }
  }

  /**
   * 触摸事件处理：根据触摸点坐标判断属于哪个扇形
   * 使用极坐标法：计算触摸点到圆心的距离和角度，匹配扇形区间
   */
  private handleTouch(event: TouchEvent): void {
    if (this.total === 0 || this.data.length === 0) {
      return;
    }

    // ArkTS TouchEvent 中触摸点使用 localX/localY（相对组件左上角）
    const touchX: number = event.touches[0].x;
    const touchY: number = event.touches[0].y;

    // 计算触摸点相对于圆心的偏移
    const dx: number = touchX - this.centerX;
    const dy: number = touchY - this.centerY;
    const dist: number = Math.sqrt(dx * dx + dy * dy);

    // 如果触摸点在圆外，取消高亮
    if (dist > this.radius) {
      if (this.currentIndex !== -1) {
        this.currentIndex = -1;
        this.drawPie(this.context, 1);
      }
      return;
    }

    // 计算触摸点的极角（atan2 返回 [-PI, PI]）
    let touchAngle: number = Math.atan2(dy, dx);

    // 将角度规范化到与扇形相同的区间（从 -PI/2 开始）
    if (touchAngle < -Math.PI / 2) {
      touchAngle += 2 * Math.PI;
    }

    // 遍历所有扇形，判断触摸点落入哪个区间
    let found: number = -1;
    for (let i = 0; i < this.data.length; i++) {
      const start: number = this.angles[i];
      const end: number = start + this.sweeps[i];

      if (touchAngle >= start && touchAngle < end) {
        found = i;
        break;
      }
    }

    // 仅在高亮状态变化时重绘，避免不必要的渲染
    if (found !== this.currentIndex) {
      this.currentIndex = found;
      this.drawPie(this.context, 1);
    }
  }

  /**
   * 获取第 index 个扇形之前所有扇形的累积角度之和
   * 用于动画进度中判断当前扇形是否应该开始绘制
   */
  private getAccumulatedAngle(index: number): number {
    let acc: number = 0;
    for (let j = 0; j < index; j++) {
      acc += this.sweeps[j];
    }
    return acc;
  }

  /**
   * 核心绘制方法：根据进度绘制饼图的各个扇形
   * @param ctx - Canvas 2D 绘图上下文
   * @param progress - 绘制进度，范围 0~1，1 表示完整绘制
   */
  private drawPie(ctx: CanvasRenderingContext2D, progress: number): void {
    const w: number = this.chartSize;
    const h: number = this.chartSize;

    // 清空整个画布
    ctx.clearRect(0, 0, w, h);

    // 数据为空时绘制灰色占位圆
    if (this.total === 0 || this.data.length === 0) {
      ctx.fillStyle = '#CCCCCC';
      ctx.beginPath();
      ctx.arc(this.centerX, this.centerY, this.radius, 0, 2 * Math.PI);
      ctx.fill();

      // 绘制空状态提示文字
      ctx.fillStyle = '#999999';
      ctx.font = '14px sans-serif';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText('暂无数据', this.centerX, this.centerY);
      return;
    }

    // 当前动画已绘制的总角度上限
    const maxAngle: number = progress * 2 * Math.PI;

    // 逐个绘制扇形
    for (let i = 0; i < this.data.length; i++) {
      // 计算当前扇形在动画进度下实际应绘制的角度
      const accumulated: number = this.getAccumulatedAngle(i);
      const sweep: number = Math.min(
        this.sweeps[i],
        Math.max(0, maxAngle - accumulated)
      );

      // 该扇形尚未到绘制时机，跳过
      if (sweep <= 0) {
        continue;
      }

      const startAngle: number = this.angles[i];
      const endAngle: number = startAngle + sweep;

      // 判断是否为高亮扇形
      const isHighlighted: boolean = i === this.currentIndex;

      // 高亮效果：半径放大 + 向外偏移（"弹出"效果）
      const drawRadius: number = isHighlighted ? this.radius * 1.08 : this.radius;
      let offsetX: number = 0;
      let offsetY: number = 0;
      if (isHighlighted) {
        const midAngle: number = startAngle + sweep / 2;
        offsetX = Math.cos(midAngle) * 8;
        offsetY = Math.sin(midAngle) * 8;
      }

      // 绘制扇形路径
      ctx.beginPath();
      ctx.moveTo(this.centerX + offsetX, this.centerY + offsetY);
      ctx.arc(
        this.centerX + offsetX,
        this.centerY + offsetY,
        drawRadius,
        startAngle,
        endAngle
      );
      ctx.closePath();

      // 填充扇形颜色
      ctx.fillStyle = this.data[i].color;
      ctx.fill();

      // 绘制白色分隔线
      ctx.strokeStyle = '#FFFFFF';
      ctx.lineWidth = 2;
      ctx.stroke();
    }

    // 在饼图中心绘制标题文字
    if (this.title.length > 0) {
      ctx.fillStyle = '#333333';
      ctx.font = 'bold 14px sans-serif';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText(this.title, this.centerX, this.centerY);
    }
  }

  /**
   * 启动扇形依次绘制的动画效果
   * 通过定时器逐步增加进度，模拟"生长"动画
   * @param ctx - Canvas 2D 绘图上下文
   */
  private startAnimation(ctx: CanvasRenderingContext2D): void {
    // 清除可能残留的旧动画定时器
    if (this.animTimer !== -1) {
      clearInterval(this.animTimer);
      this.animTimer = -1;
    }

    this.animProgress = 0;
    const duration: number = 1200; // 动画总时长（毫秒）
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

      // 按当前进度重绘饼图
      this.drawPie(ctx, this.animProgress);
    }, interval) as number;
  }

  build() {
    Column() {
      // ==================== 饼图画布 ====================
      // Canvas 组件绑定 context，在 onReady 回调中执行首次绘制
      Canvas(this.context)
        .width(this.chartSize)
        .height(this.chartSize)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .onReady(() => {
          // 初始化圆心和半径（留出边距防止高亮偏移时溢出）
          this.centerX = this.chartSize / 2;
          this.centerY = this.chartSize / 2;
          this.radius = this.chartSize / 2 - 20;

          // 重新计算几何数据（确保与最新 data 同步）
          this.computeGeometry();

          // 启动入场动画
          this.startAnimation(this.context);
        })
        .onTouch((event: TouchEvent) => {
          this.handleTouch(event);
        })

      // ==================== 图例区域（使用 ArkTS 原生组件） ====================
      Column() {
        ForEach(this.data, (item: PieDataItem, index: number) => {
          Row() {
            // 颜色指示方块
            Text('')
              .width(14)
              .height(14)
              .backgroundColor(item.color)
              .borderWidth(1)
              .borderColor('#CCCCCC')
              .borderRadius(3)

            // 分类名称（高亮时加粗）
            Text(item.name)
              .fontSize(13)
              .fontColor(index === this.currentIndex ? '#000000' : '#666666')
              .fontWeight(index === this.currentIndex ? FontWeight.Bold : FontWeight.Normal)
              .margin({ left: 8 })
              .constraintSize({ maxWidth: this.chartSize * 0.45 })

            // 百分比数值
            Text(this.total > 0
              ? ((item.value / this.total) * 100).toFixed(1) + '%'
              : '0%')
              .fontSize(13)
              .fontColor('#999999')
              .margin({ left: 6 })

            // 数值
            Text(String(item.value))
              .fontSize(12)
              .fontColor('#BBBBBB')
              .margin({ left: 6 })
          }
          .width('100%')
          .height(30)
          .padding({ left: 12, right: 12 })
          .borderRadius(4)
          .backgroundColor(index === this.currentIndex ? '#F5F5F5' : '#FFFFFF')
          .onClick(() => {
            // 点击图例项：切换高亮状态
            this.currentIndex = (index === this.currentIndex) ? -1 : index;
            this.drawPie(this.context, 1);
          })
        }, (item: PieDataItem, index: number) => index.toString())
      }
      .width(this.chartSize + 24)
      .margin({ top: 12 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .padding(16)
  }
}
