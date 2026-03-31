# TimeInterval：时间段的精确表达

在 Swift 中，`TimeInterval` 是一个极其常见的类型。它的本质只是一个定义别名（Typealias）：
`typealias TimeInterval = Double`

它代表的是一段**“时间的流逝长度”**，单位永远是**秒 (Seconds)**。

## 1. 为什么它是 Double 而不是 Int？

因为在底层的物理运算、动画引擎（如 Core Animation）或者音视频播放（AVFoundation）中，时间通常要求极其苛刻的精度。使用 64 位的浮点数（Double）可以提供亚毫秒级（Sub-millisecond）的极高精度。

## 2. 基础用法：获取与运算

### 测量代码执行耗时
```swift
import Foundation

let startTime = CFAbsoluteTimeGetCurrent() // 极其底层的获取高精度当前时间的方法

// ... 假设这里有一段非常耗时的排序循环 ...
for _ in 0..<100_000 { _ = 1 + 1 }

let endTime = CFAbsoluteTimeGetCurrent()

// 两者相减，得到一个 TimeInterval (Double)
let executionTime: TimeInterval = endTime - startTime
print("代码执行耗时: \(executionTime) 秒") 
```

### 与 Date 的交互
正如在 `Date` 章节提到的，`Date` 本质上就是以 2001 年 1 月 1 日为基准的一个巨大的 `TimeInterval`。

```swift
// 获取一个 Date 实例距离基准时间的 TimeInterval
let timestamp = Date().timeIntervalSince1970
print("当前的 Unix 时间戳 (秒): \(timestamp)")

// 使用 TimeInterval 推移时间
// 创建一个表示 5 分钟的 TimeInterval
let fiveMinutes: TimeInterval = 5 * 60
// 获取 5 分钟后的绝对时间
let future = Date(timeIntervalSinceNow: fiveMinutes)
```

## 3. 在 API 设计中的陷阱

很多初级开发者在设计 API 时，会把 `TimeInterval` 滥用来表示“天数”或“月数”。

**错误的做法：**
```swift
// 试图用 TimeInterval 表示 3 天
let threeDays: TimeInterval = 3 * 24 * 60 * 60 
// 危险！如果这 3 天跨越了夏令时 (DST) 的切换，或者跨越了有闰秒的一天，
// 真实的三天后可能并不是当前的秒数加上这个粗暴的乘积！
```

**正确的观念：**
*   `TimeInterval` 只应该用来表示**物理上的绝对持续时间**（比如：视频播放了 30.5 秒、网络请求超时时间设置为 15 秒、倒计时还剩 60 秒）。
*   当你想表达“历法上的相对时间”（比如 3 天后、2 个月后）时，必须使用 `DateComponents` 和 `Calendar` 引擎。

## 4. Swift 新趋势：Duration 与 Clock (iOS 16+)

在最新的 Swift Concurrency (并发模型) 中，为了解决 `TimeInterval` 仅仅是一个裸 `Double` 缺乏语义的问题，Apple 引入了更加现代、类型安全的 `Duration` 结构体。

现在我们写 `Task.sleep` 时，不再使用容易让人搞不清单位的底层函数了：

```swift
// 以前的做法 (要求传入纳秒级别的 UInt64)
// try await Task.sleep(nanoseconds: 2_000_000_000) 

// iOS 16+ 极其优雅的新写法
try await Task.sleep(for: .seconds(2))
// 或者
try await Task.sleep(for: .milliseconds(500))
```
随着 Swift 语言的发展，在纯异步任务控制和计时领域，新的 `Duration` 类型正在逐渐取代古老的 `TimeInterval`。
