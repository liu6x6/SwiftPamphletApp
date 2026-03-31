# 字符串与时间的相互转换

在绝大多数移动端业务中（特别是从网络接口解析 JSON 时），我们收到的时间并不是一个现成的 \`Date\` 对象，而是一个像 \`"2023-11-15T08:30:00Z"\` 或 \`"2023-11-15 08:30:00"\` 这样的字符串。

如何安全、高效地在这两者之间转换，是必备的基本功。

## 1. 传统解析方案：DateFormatter

如果你收到的字符串格式是不规则的，或者不是标准的 ISO8601，你必须使用 \`DateFormatter\`，并极其严谨地提供一个 \`dateFormat\` 模板。

### String -> Date (解析)
```swift
let customDateString = "2023/11/15 08:30 PM"

let formatter = DateFormatter()
// 必须严格匹配字符串的每一个字符和空格！
// yyyy: 四位年份, MM: 两位月份, dd: 两位日期
// hh: 12小时制, mm: 分钟, a: AM/PM 标识
formatter.dateFormat = "yyyy/MM/dd hh:mm a"

// 注意坑点 1：必须设置 Locale，否则如果用户的手机不是英语环境，"PM" 可能无法解析！
formatter.locale = Locale(identifier: "en_US_POSIX")

if let parsedDate = formatter.date(from: customDateString) {
    print("解析成功: \(parsedDate)")
} else {
    print("解析失败！字符串格式不匹配")
}
```

### Date -> String (格式化输出)
*（注意：对于将 Date 转 String 展示给用户看，强烈推荐使用最新的 \`.formatted()\` API，详见《时间-formatted(ap).md》。以下展示老版本写法作为补充）*

```swift
let formatter2 = DateFormatter()
formatter2.dateFormat = "yyyy年MM月dd日"
let displayString = formatter2.string(from: Date())
```

## 2. 国际标准方案：ISO8601DateFormatter

这是现代互联网 API 的标准。如果你的后端返回类似 \`"2023-10-01T12:00:00Z"\`（末尾带 Z 表示 UTC 零时区）或者带时区偏移 \`"2023-10-01T20:00:00+08:00"\` 的字符串，**绝对不要自己写 dateFormat去解析**。

请使用 Apple 专门提供的、性能更好且绝对不会被本地化影响的 \`ISO8601DateFormatter\`。

```swift
let isoString = "2023-10-01T12:00:00Z"

let isoFormatter = ISO8601DateFormatter()
// isoFormatter 默认自带了各种严格的保护规则
if let date = isoFormatter.date(from: isoString) {
    print("极其安全地解析出 ISO8601 时间: \(date)")
}

// 有时候后端传的字符串带有毫秒级的小数尾巴："2023-10-01T12:00:00.123Z"
// 默认的解析器会失败！你必须加上 fractionalSeconds 参数：
let msIsoFormatter = ISO8601DateFormatter()
msIsoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
```

## 3. 在 JSONDecoder 中的无缝处理 (推荐)

如果你正在使用 \`Codable\` 解析后端的 JSON 数据，你完全不需要在结构体里把时间声明为 \`String\` 然后自己用 \`DateFormatter\` 去转。

你可以直接在结构体里声明 \`var createdAt: Date\`，然后给 \`JSONDecoder\` 配置统一的时间解析策略！

```swift
struct Article: Codable {
    let title: String
    let createdAt: Date // 直接声明为 Date！
}

let jsonStr = """
{
    "title": "Swift 教学",
    "createdAt": "2023-10-01T12:00:00Z"
}
"""

let decoder = JSONDecoder()
// 告诉解码器：只要你在 JSON 里看到是要解析成 Date 的字段，
// 就一律使用 ISO8601 标准去把那个字符串翻译过来！
decoder.dateDecodingStrategy = .iso8601 

// 如果后端的格式极其奇葩，你也可以传入自定义的 formatter
// decoder.dateDecodingStrategy = .formatted(myCustomFormatter)

if let data = jsonStr.data(using: .utf8),
   let article = try? decoder.decode(Article.self, from: data) {
    print("模型解析成功，时间是真实的 Date 对象: \(article.createdAt)")
}
```

**总结**：处理网络时间字符串的第一原则是：**逼迫后端输出标准的 ISO8601 格式，并在前端使用 \`JSONDecoder.dateDecodingStrategy = .iso8601\` 自动处理**。
