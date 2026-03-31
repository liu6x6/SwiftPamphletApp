# Calendar：时间的历法引擎

如果说 `Date` 是一张没有任何单位刻度的白纸，那么 `Calendar` 就是一把复杂的、印有各种当地语言和历法刻度的尺子。

在 Foundation 框架中，**你不能也不应该脱离 `Calendar` 去谈论“今天”、“明天”、“这个月”或“星期几”**。

## 1. 初始化与获取

我们通常使用的是与用户设备设置完全一致的日历：

```swift
import Foundation

// 最常用：获取当前用户在系统设置里指定的日历（包含了用户的时区、语言和历法偏好）
let calendar = Calendar.current

// 获取一个不受用户当前时区影响的，只看地理时区绝对值的“公历”
let gregorianCalendar = Calendar(identifier: .gregorian)

// 获取伊斯兰历、希伯来历、日本历等
let japaneseCalendar = Calendar(identifier: .japanese)
```

## 2. 核心功能 1：时间比较 (Comparison)

千万不要用 `date1 == date2` 来判断“这两个时间是不是在同一天”。因为只要差了 1 秒钟，这个等式就是 `false`。
你必须使用 `Calendar` 提供的方法，忽略时分秒，只比较天。

```swift
let date1 = Date()
let date2 = Date(timeIntervalSinceNow: 3600) // 1 小时后

// 完美判断两个 Date 是否属于“历法上的同一天”
if calendar.isDate(date1, inSameDayAs: date2) {
    print("它们是同一天！")
}

// 极其方便的快捷方法
if calendar.isDateInToday(date1) { print("是今天") }
if calendar.isDateInTomorrow(date2) { print("是明天") }
if calendar.isDateInWeekend(date1) { print("是周末") }
```

## 3. 核心功能 2：基于逻辑推移时间 (Date Math)

如果你想在一个时间上加“3个月”，由于有的月 31 天有的月 28 天，你不能加绝对的秒数。`Calendar` 会极其智能地帮你处理这种非线性问题。

```swift
let today = Date()

// 将时间向未来推移 3 个月
if let futureDate = calendar.date(byAdding: .month, value: 3, to: today) {
    print("3个月后是：\(futureDate)")
}

// 组合推移：减去 1 年 又 5 天
if let pastDate = calendar.date(byAdding: DateComponents(year: -1, day: -5), to: today) {
    print("过去的时间是：\(pastDate)")
}
```

## 4. 核心功能 3：寻找特定的界限 (Boundaries)

我们经常需要知道“今天/本月/本周的第一秒和最后一秒是什么时候”。这在查询数据库时极其有用（比如 `where createdAt >= startOfDay and createdAt <= endOfDay`）。

```swift
let now = Date()

// 获取“今天”的午夜 00:00:00 的绝对时间
let startOfDay = calendar.startOfDay(for: now)

// 获取本月的第一天是哪一天，以及本月一共有多少天
if let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start {
    print("本月的第一秒: \(startOfMonth)")
}

if let daysRange = calendar.range(of: .day, in: .month, for: now) {
    print("本月共有 \(daysRange.count) 天") // 可能是 28, 29, 30 或 31
}
```

## 5. 核心功能 4：寻找下一个特定的日子

假设你要设置一个“每个星期一早上 9 点开会”的闹钟，你需要知道下一个“星期一早上 9 点”在时间轴上到底是哪个瞬间。

```swift
var nextMeeting = DateComponents()
nextMeeting.weekday = 2 // 星期一 (周日是1)
nextMeeting.hour = 9
nextMeeting.minute = 0

// 从现在开始往后找，寻找完全匹配上述条件的下一个时间点
if let nextMeetingDate = calendar.nextDate(after: Date(), matching: nextMeeting, matchingPolicy: .nextTime) {
    print("下次开会时间: \(nextMeetingDate)")
}
```

**总结**：只要你的业务需求中出现了“年、月、周、日、时、分、闰年”这些字眼，请立即停下手里的加减乘除计算器，把计算任务全部外包给 `Calendar`。
