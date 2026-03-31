#!/bin/bash
DIR="SwiftPamphletApp/Resource/Guide/appstore/Apple/基础库"

cat << 'FILE1' > "$DIR/时间/Calendar(ap).md"
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
FILE1

cat << 'FILE2' > "$DIR/时间/TimeInterval(ap).md"
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
FILE2

cat << 'FILE3' > "$DIR/Data(ap).md"
# Data：字节流的统治者

在 Swift 和 Foundation 框架中，`Data` 结构体是处理所有底层二进制数据（Bytes）的绝对核心。
无论是从网络下载的图片、从磁盘读取的文件内容，还是使用 JSONEncoder 编码后的模型，最终都会变成一坨 `Data`。

## 1. 什么是 Data？

在概念上，你可以把 `Data` 想象成一个超级巨大的、存放着无数个 `UInt8`（0 到 255 之间的无符号整数）的数组。
`Data` 的底层对其在内存中的存储进行了极其深度的优化，支持写时复制（Copy-on-Write）和连续/非连续内存的高效映射。

## 2. 基础的相互转换

这是最日常的操作：如何把人类可读的内容变成 `Data`，或者反过来。

### String 与 Data 互转
```swift
import Foundation

// 1. String 转 Data (编码)
let myString = "Hello, Swift!"
// 指定使用 UTF-8 编码规则将字符串切碎成字节
if let stringData = myString.data(using: .utf8) {
    print("字符串转换成了 \(stringData.count) 个字节的 Data")
}

// 2. Data 转 String (解码)
// 假设你从网络接收到了一段 Data，你预期它是一段文本
if let decodedString = String(data: stringData, encoding: .utf8) {
    print("解开的数据: \(decodedString)")
}
```

### JSON (Codable) 与 Data 互转
```swift
struct User: Codable { let name: String; let age: Int }
let user = User(name: "Alice", age: 30)

// 模型 -> Data (用于发送给服务器或保存到本地)
let jsonData = try? JSONEncoder().encode(user)

// Data -> 模型 (从服务器接收后解析)
let parsedUser = try? JSONDecoder().decode(User.self, from: jsonData!)
```

### 图片/文件 与 Data 互转 (iOS环境)
```swift
import UIKit

// UIImage 转 Data
let image = UIImage(named: "logo")!
let pngData = image.pngData()
let jpegData = image.jpegData(compressionQuality: 0.8)

// Data 转 UIImage
if let loadedImage = UIImage(data: pngData!) {
    // 渲染图片
}
```

## 3. 直接操作字节 (Bytes)

由于 `Data` 遵循 `Collection` 协议，你可以像操作普通数组一样直接操作它的每一个字节。

```swift
var data = Data([0x00, 0xFF, 0x1A]) // 初始化 3 个字节

// 读取第一个字节
let firstByte: UInt8 = data[0]

// 添加字节
data.append(0x2B)

// 遍历所有的字节，打印出它们的十六进制表示
for byte in data {
    print(String(format: "%02X", byte))
}
```

## 4. 高级：与 C 语言指针的交互 (Unsafe Pointers)

在调用极其底层的 C 语言库（比如 `CommonCrypto` 加解密库或 `SQLite3` 底层 API）时，C 函数通常不认识 Swift 的 `Data` 结构体，它们只接受 `const void *` 或 `uint8_t *` 这样的原始内存指针。

`Data` 提供了非常安全的方法让你临时把底层内存借给 C 函数读取：

```swift
let secretData = "TopSecret".data(using: .utf8)!

// withUnsafeBytes 会临时锁住这段内存，并把一个只读指针 (buffer) 传给闭包
let result = secretData.withUnsafeBytes { bufferPointer -> Int in
    // 将指针转换为 C 语言能看懂的基址指针
    guard let baseAddress = bufferPointer.baseAddress else { return 0 }
    
    // 调用需要指针的虚构 C 函数 (假装有这个函数)
    // return c_language_hash_function(baseAddress, bufferPointer.count)
    return bufferPointer.count
}
```
**安全警告**：绝对不要把 `baseAddress` 指针保存到闭包外部并在以后使用！当闭包结束时，这块内存可能就会被系统回收或移动，使用悬垂指针会导致极其严重的灾难性 Crash！
FILE3

cat << 'FILE4' > "$DIR/随机(ap).md"
# Swift 中的随机数生成 (Randomness)

在 Swift 4.2 及其之后的版本中，Apple 彻底抛弃了古老且丑陋的 C 语言函数 `arc4random_uniform()` 和 `srand()`。Swift 引入了一套原生的、类型安全的、并且**默认密码学安全 (Cryptographically Secure)** 的随机数 API。

## 1. 最基础的随机数：`.random(in:)`

这是你使用最频繁的 API。所有的基础数值类型（`Int`, `Double`, `Float`, `CGFloat` 甚至 `Bool`）都直接内置了这个静态方法。

```swift
// 生成一个 1 到 100 之间的随机整数（包含 1 和 100）
let randomInt = Int.random(in: 1...100)

// 生成一个 0.0 到 1.0 之间的随机浮点数（不包含 1.0）
let randomDouble = Double.random(in: 0.0..<1.0)

// 抛硬币，直接随机生成一个布尔值
let isHeads = Bool.random()
```

## 2. 集合的随机操作：`.randomElement()` 与 `.shuffled()`

如果你有一个数组（或者任何遵循 `Collection` 协议的集合），你可以非常优雅地对其进行随机操作。

```swift
let names = ["Alice", "Bob", "Charlie", "David"]

// 1. 随机抽取一个元素 (类似于抽奖)
// 注意：如果数组是空的，它会安全地返回 nil，所以它是 Optional
if let winner = names.randomElement() {
    print("中奖者是：\(winner)")
}

// 2. 将数组里的元素顺序彻底打乱 (类似于洗牌)
// 返回一个全新的、被洗切过的数组
let shuffledNames = names.shuffled()

// 3. 如果是用 var 声明的可变数组，可以原地洗牌
var deckOfCards = [1, 2, 3, 4, 5]
deckOfCards.shuffle() // 原地打乱
```

## 3. 密码学安全的底层原理：SystemRandomNumberGenerator

在很多语言（比如老版本的 JS 或 C）中，默认的随机函数生成的都是**伪随机数 (Pseudo-Random)**。如果你知道了随机种子（Seed），你就能完美预测出接下来的每一个数字。这在编写抽奖系统或生成加密密钥时是极其危险的。

**Swift 的伟大之处在于，当你调用 `Int.random(in:)` 时，它底层默认使用的是 `SystemRandomNumberGenerator`。**

这个生成器直接连接到了操作系统的底层安全熵源（如 macOS 的 `/dev/urandom`）。这意味着它生成的数字是**密码学安全**的，即使是最高明的黑客也无法通过前面的数字预测出下一个结果。你可以放心地用它来生成临时的密码、验证码。

## 4. 自定义随机数生成器 (Custom Generator)

如果默认的“绝对不可预测”不符合你的需求怎么办？

假设你在开发一个“随机迷宫生成”游戏（如《Minecraft》的地图种子），你希望：只要玩家输入相同的“种子码（Seed）”，系统每次生成的看似随机的迷宫结构都必须**一模一样**。
这就要求随机数是可预测的伪随机。

这时候，你需要自己实现一个遵循 `RandomNumberGenerator` 协议的结构体（例如使用经典的线性同余或梅森旋转算法），然后把它作为参数传给 random 方法：

```swift
// 假设你或者第三方库实现了一个基于种子的可预测生成器
var mySeededGenerator = MyPredictableGenerator(seed: 12345)

// 将你的生成器传给 inout 参数
let randomA = Int.random(in: 1...100, using: &mySeededGenerator)
let randomB = Int.random(in: 1...100, using: &mySeededGenerator)

// 只要 seed 还是 12345，无论你运行多少次 App，randomA 和 randomB 的结果都将永恒不变。
```

## 总结
*   日常业务开发，无脑使用 `类型.random(in:)` 和 `数组.randomElement()`。它们安全、优雅、性能极高。
*   绝对不需要再去调用 `arc4random` 甚至做任何取模求余（`%`）的运算（那会导致模偏差 Modulo Bias 问题）。
FILE4

cat << 'FILE5' > "$DIR/格式化/格式化-度量值(ap).md"
# 格式化度量值：MeasurementFormatter

在应用中展示长度、重量、温度等物理量时，我们不能仅仅把数字拼上单位（如 `print("\(weight) kg")`），因为这完全没有考虑到用户的地区偏好（美国用户习惯磅 lb，欧洲用户习惯千克 kg）。

`MeasurementFormatter` 是苹果官方提供的一把极其锋利的瑞士军刀，它能自动根据用户手机的 Locale（区域语言设置），将抽象的 `Measurement` 转化为完美的本地化字符串。

## 1. 基础自动本地化

假设你的服务器返回了一段以“公里”为单位的距离。

```swift
import Foundation

// 1. 构造一个绝对准确的度量值对象（5公里）
let rawDistance = Measurement(value: 5, unit: UnitLength.kilometers)

// 2. 创建格式化器
let formatter = MeasurementFormatter()

// 3. 输出字符串
let displayString = formatter.string(from: rawDistance)
print(displayString)
```
**魔法就在这里发生**：
*   如果用户的 iPhone 是**中国区域 (zh_CN)**，输出可能是：`"5 公里"`。
*   如果用户的 iPhone 是**美国区域 (en_US)**，系统会自动把 5 公里转换成英制，输出可能是：`"3.107 miles"`。
*   你完全不需要自己写 `if locale == "US" { ... }` 这种极其丑陋的转换代码！

## 2. 核心属性与配置选项

你可以通过配置 `MeasurementFormatter` 的属性，精细控制输出的样式。

### A. unitOptions：单位转换策略
*   `.naturalScale` (默认值)：极其聪明。如果你传入的是 `0.001` 公里，它觉得这太怪了，会自动帮你缩放并显示为 `"1 米"`。
*   `.providedUnit`：**强行禁用自动转换**。就算用户是美国人，只要你代码里指定的是千米，就必须输出为千米（比如在进行极其专业的国际物理学术报告展示时）。
*   `.temperatureWithoutUnit`：只显示数字，不显示 °C 或 °F（极少使用）。

```swift
formatter.unitOptions = .providedUnit // 强制只用我提供的单位
```

### B. unitStyle：单位的长度风格
用于控制单位单词的缩写程度。
```swift
let temp = Measurement(value: 30, unit: UnitTemperature.celsius)
let styleFormatter = MeasurementFormatter()

// 1. .short (默认) -> "30°C" 
styleFormatter.unitStyle = .short

// 2. .medium -> "30 °C" (间距略微不同)
styleFormatter.unitStyle = .medium

// 3. .long -> "30 degrees Celsius" 或 "30摄氏度"
styleFormatter.unitStyle = .long
```

### C. numberFormatter：控制核心数字的精度
`MeasurementFormatter` 内部包含了一个 `NumberFormatter`，你可以通过修改它来控制数字要保留几位小数。

```swift
let weight = Measurement(value: 85.3456, unit: UnitMass.kilograms)
let numFormatter = MeasurementFormatter()

// 告诉内部的数字格式化器：最多只保留 1 位小数
numFormatter.numberFormatter.maximumFractionDigits = 1
numFormatter.numberFormatter.minimumFractionDigits = 1

print(numFormatter.string(from: weight)) 
// 中文区输出: "85.3 公斤"
```

## 3. 在 SwiftUI 中的现代替代方案：.formatted()

与日期格式化一样，如果你使用 iOS 15 及以上的版本，苹果在 SwiftUI 体系中也为 `Measurement` 提供了极其优雅的 `.formatted()` 扩展宏，可以完全抛弃实例化 `MeasurementFormatter` 的繁琐过程。

```swift
import SwiftUI

struct WorkoutView: View {
    let runDistance = Measurement(value: 12.5, unit: UnitLength.kilometers)
    
    var body: some View {
        // 直接在 Text 视图中使用 format！
        // .measurement(...) 参数内部同样可以配置使用本地缩放、长度风格等
        Text(runDistance, format: .measurement(width: .abbreviated, usage: .asProvided))
            .font(.title)
    }
}
```
**总结**：在处理国际化应用的各种物理单位展示时，让底层框架来做单位的缩放（米变公里）和度量衡体系的切换（公制变英制），永远不要相信自己手写的乘除法换算公式。
FILE5
