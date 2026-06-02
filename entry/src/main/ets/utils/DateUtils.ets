/**
 * 日期工具类
 * 提供日期格式化、范围计算、解析等纯工具函数，不依赖系统 API
 */

// ======================== 内部辅助函数 ========================

/**
 * 将数字补零到两位
 * @param num 需要补零的数字
 * @returns 补零后的字符串
 */
function padZero(num: number): string {
  return num < 10 ? `0${num}` : `${num}`;
}

/**
 * 将数字补零到三位（用于毫秒）
 * @param num 需要补零的数字
 * @returns 补零后的字符串
 */
function padZero3(num: number): string {
  if (num < 10) {
    return `00${num}`;
  } else if (num < 100) {
    return `0${num}`;
  }
  return `${num}`;
}

/**
 * 生成一个新的 Date 对象，避免修改原始对象
 * @param date 原始日期
 * @returns 新的 Date 副本
 */
function cloneDate(date: Date): Date {
  return new Date(date.getTime());
}

/**
 * 解析日期字符串为 Date 对象，支持常见分隔符
 * @param dateStr 日期字符串，如 "2026-06-01"、"2026/06/01"、"2026.06.01"
 * @returns Date 对象
 */
export function parseDate(dateStr: string): Date {
  // 统一将分隔符替换为 "-"，兼容 "2026/06/01" 和 "2026.06.01"
  const normalized: string = dateStr.replace(/[\/\.]/g, '-');

  // 尝试解析 YYYY-MM-DD 或 YYYY-MM-DD HH:mm:ss 格式
  const parts: string[] = normalized.split(' ');
  const datePart: string = parts[0];
  const timePart: string = parts.length > 1 ? parts[1] : '';

  const dateSegments: string[] = datePart.split('-');
  const year: number = parseInt(dateSegments[0], 10);
  const month: number = dateSegments.length > 1 ? parseInt(dateSegments[1], 10) - 1 : 0;
  const day: number = dateSegments.length > 2 ? parseInt(dateSegments[2], 10) : 1;

  let hour: number = 0;
  let minute: number = 0;
  let second: number = 0;

  if (timePart !== '') {
    const timeSegments: string[] = timePart.split(':');
    hour = parseInt(timeSegments[0], 10);
    minute = timeSegments.length > 1 ? parseInt(timeSegments[1], 10) : 0;
    second = timeSegments.length > 2 ? parseInt(timeSegments[2], 10) : 0;
  }

  return new Date(year, month, day, hour, minute, second);
}

// ======================== 日期格式化 ========================

/**
 * 格式化日期为指定格式的字符串
 * @param date 需要格式化的 Date 对象
 * @param format 格式模板，支持以下占位符：
 *   - YYYY: 四位年份（如 2026）
 *   - YY: 两位年份（如 26）
 *   - MM: 两位月份（如 06）
 *   - M: 一位月份（如 6）
 *   - DD: 两位日期（如 01）
 *   - D: 一位日期（如 1）
 *   - HH: 两位24小时制小时（如 08）
 *   - H: 一位24小时制小时（如 8）
 *   - mm: 两位分钟（如 05）
 *   - m: 一位分钟（如 5）
 *   - ss: 两位秒数（如 03）
 *   - s: 一位秒数（如 3）
 *   - SSS: 三位毫秒（如 007）
 * @returns 格式化后的日期字符串
 * @example formatDate(new Date(), 'YYYY-MM-DD') // "2026-06-01"
 * @example formatDate(new Date(), 'YYYY/MM/DD HH:mm:ss') // "2026/06/01 14:30:00"
 */
export function formatDate(date: Date, format: string): string {
  const year: number = date.getFullYear();
  const month: number = date.getMonth() + 1;
  const day: number = date.getDate();
  const hour: number = date.getHours();
  const minute: number = date.getMinutes();
  const second: number = date.getSeconds();
  const millisecond: number = date.getMilliseconds();

  let result: string = format;

  // 按照从长到短的顺序替换，避免短占位符误匹配
  // 年份
  result = result.replace('YYYY', `${year}`);
  result = result.replace('YY', `${year % 100}`);

  // 月份
  result = result.replace('MM', padZero(month));
  result = result.replace('M', `${month}`);

  // 日期
  result = result.replace('DD', padZero(day));
  result = result.replace('D', `${day}`);

  // 小时
  result = result.replace('HH', padZero(hour));
  result = result.replace('H', `${hour}`);

  // 分钟
  result = result.replace('mm', padZero(minute));
  result = result.replace('m', `${minute}`);

  // 秒数
  result = result.replace('ss', padZero(second));
  result = result.replace('s', `${second}`);

  // 毫秒
  result = result.replace('SSS', padZero3(millisecond));

  return result;
}

// ======================== 今日日期 ========================

/**
 * 获取今日日期字符串（格式：YYYY-MM-DD）
 * @returns 今日日期字符串
 * @example getToday() // "2026-06-01"
 */
export function getToday(): string {
  return formatDate(new Date(), 'YYYY-MM-DD');
}

// ======================== 本月范围 ========================

/**
 * 获取本月第一天的日期字符串（格式：YYYY-MM-DD）
 * @returns 本月第一天
 * @example getMonthStart() // "2026-06-01"
 */
export function getMonthStart(): string {
  const now: Date = new Date();
  const firstDay: Date = new Date(now.getFullYear(), now.getMonth(), 1);
  return formatDate(firstDay, 'YYYY-MM-DD');
}

/**
 * 获取本月最后一天的日期字符串（格式：YYYY-MM-DD）
 * @returns 本月最后一天
 * @example getMonthEnd() // "2026-06-30"
 */
export function getMonthEnd(): string {
  const now: Date = new Date();
  // 下个月的第 0 天即为本月最后一天
  const lastDay: Date = new Date(now.getFullYear(), now.getMonth() + 1, 0);
  return formatDate(lastDay, 'YYYY-MM-DD');
}

// ======================== 本周范围 ========================

/**
 * 获取本周第一天（周一）的日期字符串（格式：YYYY-MM-DD）
 * @returns 本周第一天
 * @example getWeekStart() // "2026-06-01"
 */
export function getWeekStart(): string {
  const now: Date = cloneDate(new Date());
  const dayOfWeek: number = now.getDay();
  // getDay() 返回 0（周日）到 6（周六），将周一作为一周的开始
  // 周日时 dayOfWeek 为 0，需要回退 6 天；其他天回退 dayOfWeek - 1 天
  const diff: number = dayOfWeek === 0 ? 6 : dayOfWeek - 1;
  now.setDate(now.getDate() - diff);
  return formatDate(now, 'YYYY-MM-DD');
}

/**
 * 获取本周最后一天（周日）的日期字符串（格式：YYYY-MM-DD）
 * @returns 本周最后一天
 * @example getWeekEnd() // "2026-06-07"
 */
export function getWeekEnd(): string {
  const now: Date = cloneDate(new Date());
  const dayOfWeek: number = now.getDay();
  // 周日时 dayOfWeek 为 0，不需前进；其他天前进 7 - dayOfWeek 天
  const diff: number = dayOfWeek === 0 ? 0 : 7 - dayOfWeek;
  now.setDate(now.getDate() + diff);
  return formatDate(now, 'YYYY-MM-DD');
}

// ======================== 日期范围计算 ========================

/**
 * 获取指定日期范围内的所有日期列表（包含起止日期）
 * @param start 开始日期字符串，格式如 "2026-06-01"
 * @param end 结束日期字符串，格式如 "2026-06-07"
 * @returns 日期字符串数组，格式为 "YYYY-MM-DD"
 * @example getDaysInRange("2026-06-01", "2026-06-03") // ["2026-06-01", "2026-06-02", "2026-06-03"]
 */
export function getDaysInRange(start: string, end: string): string[] {
  const result: string[] = [];
  const startDate: Date = parseDate(start);
  const endDate: Date = parseDate(end);

  // 确保开始日期不晚于结束日期
  const current: Date = cloneDate(startDate);
  while (current.getTime() <= endDate.getTime()) {
    result.push(formatDate(current, 'YYYY-MM-DD'));
    current.setDate(current.getDate() + 1);
  }

  return result;
}

// ======================== 最近 N 天 ========================

/**
 * 获取最近 7 天的日期列表（包含今天，从 6 天前到今天）
 * @returns 日期字符串数组，格式为 "YYYY-MM-DD"，按时间正序排列
 * @example getLast7Days() // ["2026-05-26", "2026-05-27", ..., "2026-06-01"]
 */
export function getLast7Days(): string[] {
  const result: string[] = [];
  const today: Date = new Date();

  for (let i: number = 6; i >= 0; i--) {
    const date: Date = cloneDate(today);
    date.setDate(date.getDate() - i);
    result.push(formatDate(date, 'YYYY-MM-DD'));
  }

  return result;
}
