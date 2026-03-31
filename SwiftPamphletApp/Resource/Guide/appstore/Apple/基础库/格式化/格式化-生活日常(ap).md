# 生活日常的格式化 (姓名、列表与时间)

在日常 App 开发中，有几种文本的拼接极度繁琐，比如：如何把“姓”和“名”按当地习惯拼在一起？如何把数组 \`["苹果", "香蕉", "橘子"]\` 变成 \`"苹果、香蕉和橘子"\`？如何显示“距离现在还有 3 小时”？

Apple 提供了一系列极其贴心的 Formatter，帮你完美处理这些细枝末节的本地化问题。

## 1. 姓名格式化：PersonNameComponentsFormatter

在美国，“名在前，姓在后”（John Smith）；在中国，“姓在前，名在后”（张三）。如果你自己写 \`\(firstName) \(lastName)\`，在国际化时必出 Bug。

```swift
import Foundation

var nameComps = PersonNameComponents()
nameComps.givenName = "Steve"
nameComps.familyName = "Jobs"
nameComps.nickname = "Steve"

let formatter = PersonNameComponentsFormatter()

// .default -> "Steve Jobs" (或中文下的 "Jobs Steve"，取决于系统语言)
// .short -> "Steve" (通常只显示名，适合聊天列表)
// .abbreviated -> "SJ" (自动提取姓名首字母，极其适合做默认头像的占位符！)
formatter.style = .abbreviated
print(formatter.string(from: nameComps)) // 输出: SJ
```

**现代 Swift 替代方案 (iOS 15+)：**
```swift
let nameString = nameComps.formatted(.name(style: .abbreviated))
```

## 2. 数组列表格式化：ListFormatter

当你有一个数组 \`["北京", "上海", "广州"]\` 时，不要再傻傻地去写 \`.joined(separator: ", ")\` 了。因为在英文里，最后一个逗号应该变成 "and" (Beijing, Shanghai, and Guangzhou)！

```swift
let cities = ["北京", "上海", "广州"]

let listFormatter = ListFormatter()
// 在中文环境下输出："北京、上海和广州"
// 在英文环境下输出："北京, 上海, and 广州"
let result = listFormatter.string(from: cities)
print(result!)
```

**现代 Swift 替代方案 (iOS 15+)：**
```swift
let listString = cities.formatted(.list(type: .and, width: .standard))
```

## 3. 相对时间格式化：RelativeDateTimeFormatter

用于社交网络或新闻列表中的 "3 分钟前"、"昨天"、"1 个月前"。

```swift
let formatter = RelativeDateTimeFormatter()

// 1. .named 风格：会输出 "昨天", "明天"
formatter.dateTimeStyle = .named

// 2. .numeric 风格：会严格输出 "1天前", "1天后"
formatter.dateTimeStyle = .numeric

// 计算从现在起 2 小时前的时间
let pastDate = Date(timeIntervalSinceNow: -2 * 3600)

// 中文输出："2小时前"
print(formatter.localizedString(for: pastDate, relativeTo: Date()))
```

## 4. 时长格式化：DateComponentsFormatter

如果你做的是视频播放器或运动打卡软件，你需要把 \`125\` 秒变成 \`"02:05"\` 或者是 \`"2 分 5 秒"\`。

```swift
let formatter = DateComponentsFormatter()
// 允许输出分钟和秒
formatter.allowedUnits = [.minute, .second]

// .positional -> "2:05" (最适合视频播放器的时间轴)
// .abbreviated -> "2m 5s"
// .spellOut -> "2 minutes, 5 seconds"
formatter.unitsStyle = .positional
// 确保秒数个位数时前面补 0 (比如不是 2:5 而是 2:05)
formatter.zeroFormattingBehavior = .pad

if let durationString = formatter.string(from: 125.0) {
    print(durationString) // 输出: "2:05"
}
```
