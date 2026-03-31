# Date：时间的锚点

在 Swift 和 Foundation 框架中，**\`Date\`** 结构体是一切时间操作的绝对基石。

## 1. 什么是 Date？

\`Date\` 的本质极其单纯：它就是**一个用来记录流逝秒数的 \`Double\` 类型的数字**。
它记录的是一个绝对的物理瞬间：自 **2001年1月1日 00:00:00 UTC (世界协调时间)** 以来，所经过的秒数。

*   **没有时区**：\`Date\` 不知道你是中国人还是美国人。
*   **没有日历**：\`Date\` 不知道今天是星期几，不知道是农历还是公历。
*   **没有格式**：\`Date\` 不能被直接当成字符串 "2023-10-10" 输出。

它只是一个锚点。所有的“几点几分”、“哪一年”都必须借助 \`Calendar\` 或 \`DateFormatter\` 进行解释才能得到。

## 2. 创建 Date

```swift
import Foundation

// 1. 获取此刻的绝对瞬间 (最常用)
let rightNow = Date()

// 2. 从某个已知的 Date 出发，向前或向后推移特定的秒数
// (例如：获取 60 秒之后的瞬间)
let oneMinuteLater = Date(timeIntervalSinceNow: 60)

// 3. 基于经典的 Unix 时间戳（自 1970年1月1日0点 起的秒数，常用于和后端通信）
// 假设后端返回的时间戳是 1697382000
let dateFromUnix = Date(timeIntervalSince1970: 1697382000)

// 4. 获取极端的占位符时间
let distantPast = Date.distantPast // 很久很久以前 (0001年)
let distantFuture = Date.distantFuture // 遥远的未来 (4000年)
```

## 3. Date 之间的比较

因为 \`Date\` 底层就是个 \`Double\`，所以它们完美支持所有的比较运算符。

```swift
let date1 = Date()
let date2 = Date(timeIntervalSinceNow: 3600) // 1小时后

// 越晚的时间，其底层秒数越大
if date2 > date1 {
    print("date2 在 date1 之后")
}

if date1 == date2 {
    print("它们代表完全相同的绝对瞬间")
}

// 高级比较方法：忽略几秒钟的微小误差
// 比如比较 date1 是不是在 date2 之前
if date1.compare(date2) == .orderedAscending {
    print("date1 earlier than date2")
}
```

## 4. 获取两个 Date 之间的时间间隔

这是获取代码执行耗时、或计算倒计时最基础的方法：

```swift
let start = Date()

// ... 执行一段耗时代码 ...
Thread.sleep(forTimeInterval: 1.5)

let end = Date()

// timeIntervalSince 返回一个 Double 类型的秒数
let executionTime = end.timeIntervalSince(start)
print("耗时: \(executionTime) 秒") // 约输出 1.5
```

## 5. Date 的性能建议

由于 \`Date()\` 每次调用都会向操作系统底层请求当前的系统时钟，这虽然很快，但在一个极高频的循环（如游戏引擎每秒 60 次的渲染循环、或者几十万次的数据排序计算）中反复调用 \`Date()\` 会产生可观的性能开销。

在需要极其高精度且高频的耗时计算时，推荐使用 \`CFAbsoluteTimeGetCurrent()\` (Core Foundation API) 或更为底层且不受系统时钟修改影响的 **\`DispatchTime.now()\`** 或 **\`CACurrentMediaTime()\`**。
