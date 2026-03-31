# 时间的现代格式化魔法：.formatted()

在过去十多年的 iOS 开发中，我们如果想把一个 \`Date\` 转成漂亮的字符串给用户看，唯一的选择是实例化一个 \`DateFormatter\`，然后痛苦地查阅文档，写下极其容易拼错的神秘代码：\`formatter.dateFormat = "yyyy-MM-dd HH:mm"\`。

在 **iOS 15 / macOS 12** 之后，Apple 引入了一套基于纯 Swift 新特性、极其优雅、声明式且类型安全的全新格式化 API：**\`.formatted()\`**。

## 1. 告别 DateFormatter

不再需要实例化笨重的 formatter，也不需要处理其极其耗时的内存创建开销。你现在可以直接对着 \`Date\` 调用方法。

```swift
let now = Date()

// 最基础的用法：系统会自动根据用户的地区（Locale）给出一个合理的中等长度格式
// 比如在美国显示 "Oct 15, 2023, 2:30 PM"，在中国显示 "2023年10月15日 下午2:30"
print(now.formatted())
```

## 2. 声明式定制格式 (Date.FormatStyle)

这是新 API 最强大的地方。你可以通过链式调用，像写英文句子一样精确描述你想要的格式。

```swift
let now = Date()

// 1. 只显示日期，不要时间，并且要详细的文字
// 输出: "2023年10月15日星期日"
let s1 = now.formatted(
    .dateTime
    .year()
    .month(.wide)   // .wide 代表完整的词，比如 "10月" 或 "October"
    .day()
    .weekday(.wide)
)

// 2. 只显示时间，忽略日期
// 输出: "14:30:55"
let s2 = now.formatted(
    .dateTime
    .hour()
    .minute()
    .second()
)

// 3. 数字风格，省略前导零
// 输出: "23/10/15" (取决于地区习惯，可能是月/日/年)
let s3 = now.formatted(
    .dateTime
    .year(.twoDigits)
    .month(.defaultDigits)
    .day()
)
```

## 3. ISO8601 标准的究极简化

与后端进行 JSON 通信时，我们通常需要国际标准的 ISO8601 字符串（如 \`2023-10-15T14:30:00Z\`）。以前你需要专门用 \`ISO8601DateFormatter\`，现在一句话搞定：

```swift
let jsonDateString = Date().formatted(.iso8601)
// 输出: "2023-10-15T14:30:00Z"

// 还可以精确控制：只要日期，不要时间，并且用短横线连起来
let justDateISO = Date().formatted(.iso8601.year().month().day().dateSeparator(.dash))
// 输出: "2023-10-15"
```

## 4. SwiftUI Text 中的无缝集成

新 API 与 SwiftUI 达到了完美的融合。你甚至不需要在传给 \`Text\` 之前把它转成 \`String\`。

```swift
struct TimeView: View {
    let meetingDate = Date()
    
    var body: some View {
        VStack {
            // 直接在 Text 里面写 format 规则！
            Text(meetingDate, format: .dateTime.month().day().hour().minute())
                .font(.headline)
            
            // 连 ISO8601 都能直接渲染
            Text(meetingDate, format: .iso8601)
                .font(.caption)
        }
    }
}
```

## 5. 为什么要用新 API 代替旧的 dateFormat？

除了写起来更爽，新 API 最核心的优势是：**本地化安全 (Localization Safe)**。

如果你以前手写 \`dateFormat = "MM-dd"\`，在美国用户看来是 "10-15"，在中国用户看来也是 "10-15"，这可能不符合某些国家的习惯（他们可能习惯 日/月）。
当你使用 \`.formatted(.dateTime.month().day())\` 时，你只是告诉系统**“我需要这两个信息”**，系统会**自动判断**到底是按 "10/15" 还是 "15/10" 还是 "10月15日" 来渲染，永远不会出错。
