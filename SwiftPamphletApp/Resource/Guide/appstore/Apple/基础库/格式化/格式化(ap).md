# 格式化 (Formatter) 概览

在软件开发中，“格式化 (Formatting)”是指**“将内存里冰冷的数字和数据结构，转换为人类（且是具有不同语言、文化背景的人类）能够读懂的美观字符串”**的过程。

Apple 的 \`Foundation\` 框架提供了整个业界最为强大、复杂且绝对正确的本地化格式化引擎。

## 1. 为什么坚决不要自己写格式化代码？

新手最常犯的错误是：
*   想把 1000 块钱格式化，于是写：\`"$\(money)"\`
*   想把 12 月 1 号格式化，于是写：\`"\(month)/\(day)"\`

**这在多语言（国际化 / i18n）开发中是绝对的灾难！**
*   在欧洲很多国家，小数点的符号是逗号 `,`，千分位的符号是句号 `.`。你写死的 `1,000.50` 在他们眼里是“一千块零五毛”还是“一块零五毛”？
*   日期的分隔符在德国可能是 `.`，在英国可能是 `-`。
*   阿拉伯语国家的文字是从右向左排版 (RTL) 的。

**Apple 的 Formatter 家族完美地解决了这一切。它会去读取当前设备的地区 (Locale) 设置，自动运用正确的符号和排版顺序。**

## 2. 旧时代的王者：Formatter 家族 (基于 Objective-C)

在 iOS 15 之前，所有格式化都依赖于继承自抽象类 \`Formatter\` 的几个大将军：
*   **\`DateFormatter\`**：把 \`Date\` 转成字符串。
*   **\`NumberFormatter\`**：把 \`Int\`, \`Double\`, \`NSNumber\` 转成货币、百分比、普通数字。
*   **\`MeasurementFormatter\`**：把长度、重量（千克转磅）等物理单位转成字符串。
*   **\`PersonNameComponentsFormatter\`**：把人名转成符合当地习惯的“名+姓”或“姓+名”。

**这些类的缺点**：
1. 创建它们的实例极其消耗内存和 CPU 性能。如果在 \`TableView\` 的滚动闭包里疯狂 \`let formatter = DateFormatter()\`，App 会立刻卡死。必须使用全局单例或静态变量。
2. API 非常繁琐，需要死记硬背很多字符串模板（如 \`yyyy-MM-dd\`）。

## 3. 新时代的革命：Swift 声明式 .formatted() (iOS 15+)

为了解决旧 API 难用和性能拉胯的问题，Apple 在 Swift 5.5 中引入了基于协议的全新格式化引擎。

现在的核心思想是：**你不要去创建格式化器，你直接对着数据本身（Date, Int, Double）呼叫 \`.formatted()\` 魔法。**

```swift
// 旧方法 (繁琐且耗时)
let formatter = NumberFormatter()
formatter.numberStyle = .currency
formatter.currencyCode = "USD"
let oldStr = formatter.string(from: 1000)

// 新方法 (优雅、类型安全、性能极高)
let newStr = 1000.formatted(.currency(code: "USD"))
```

## 4. 学习建议

由于很多企业级项目依然需要兼容 iOS 13 / 14，你依然**必须**掌握传统的 \`NumberFormatter\` 和 \`DateFormatter\` 的用法和单例性能优化技巧。
但在编写仅支持 iOS 15+ 的新页面或小组件时，请全面拥抱 \`.formatted()\`。
