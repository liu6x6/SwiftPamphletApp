# Scanner：底层的字符串解析利器

在处理字符串时，除了使用正则表达式 (\`NSRegularExpression\` 或 Swift 新的 \`Regex\`) 或者是原生的 \`String.split\`，Apple 的 Foundation 框架中还有一个历史极其悠久且非常强大的工具：**\`Scanner\` (以前叫 \`NSScanner\`)**。

\`Scanner\` 的核心思想是提供一个“游标（光标）”，在一段极长的字符串中从左向右扫描，提取出特定类型的数字、浮点数或连续字符。

## 1. 为什么使用 Scanner？

当你需要解析一些**格式非常固定且高度结构化**的文本（比如：解析十六进制颜色代码、解析 CSV 文件、解析自定义的数学表达式）时，\`Scanner\` 比繁重的正则表达式更轻量，且具有极高的性能。

## 2. 基础用法：提取数字

假设我们有一段文本：\`"今天卖出了 150 个苹果，赚了 $20.55"\`。我们需要提取其中的数字。

```swift
import Foundation

let text = "今天卖出了 150 个苹果，赚了 $20.55"
let scanner = Scanner(string: text)

// 忽略所有不需要的字符（Scanner 默认会自动跳过空格和换行）
// 这里我们手动让它跳过所有不是数字的字符，直接去找数字
scanner.charactersToBeSkipped = CharacterSet(charactersIn: "0123456789.").inverted

// 1. 扫描整数
var count: Int = 0
if scanner.scanInt(&count) {
    print("数量: \(count)") // 输出: 150
}

// 2. 扫描浮点数 (游标此时已经走过了 "150"，继续往后找)
var money: Double = 0.0
if scanner.scanDouble(&money) {
    print("金额: \(money)") // 输出: 20.55
}
```
*注意：在较老的 iOS 版本中，Scanner 的 API 是基于指针的（通过 \`&变量\` 传入）。在现代 Swift 中有更优雅的变体。*

## 3. 现代 Swift 的 Scanner API (iOS 13+)

Apple 为 \`Scanner\` 提供了一套对 Swift 更友好的、返回 Optional 值的现代 API，告别了繁琐的指针参数。

### 实战：解析十六进制颜色代码 (#FF5500)

这是一个极度典型的使用 \`Scanner\` 的场景。

```swift
func color(from hexString: String) -> UIColor? {
    let scanner = Scanner(string: hexString)
    
    // 如果有 "#" 开头，游标直接跳过它
    _ = scanner.scanString("#")
    
    // 扫描接下来的十六进制数字 (UInt64)
    // 这里的 scanHexInt64() 返回一个 UInt64?，如果解析失败则为 nil
    guard let hexValue = scanner.scanHexInt64() else {
        return nil
    }
    
    // 提取 RGB
    let r = CGFloat((hexValue & 0xFF0000) >> 16) / 255.0
    let g = CGFloat((hexValue & 0x00FF00) >> 8)  / 255.0
    let b = CGFloat(hexValue & 0x0000FF)         / 255.0
    
    return UIColor(red: r, green: g, blue: b, alpha: 1.0)
}

print(color(from: "#FF0000")!) // 得到红色 UIColor
```

## 4. 扫描到特定字符停止

如果你在解析类似 \`[key:value]\` 这样的自定义标记。

```swift
let tag = "[Author:John Doe]"
let scanner = Scanner(string: tag)

// 跳过开头的 "["
_ = scanner.scanString("[")

// 扫描直到遇到 ":" 为止，并将扫描经过的内容作为字符串返回
if let key = scanner.scanUpToString(":") {
    print("Key is: \(key)") // 输出: Author
}

// 跳过 ":"
_ = scanner.scanString(":")

// 扫描直到遇到 "]" 为止
if let value = scanner.scanUpToString("]") {
    print("Value is: \(value)") // 输出: John Doe
}
```

## 总结

当你觉得 \`String.split\` 无法处理复杂的结构，而 \`Regex\` 又过于晦涩难懂时，试着拿起 \`Scanner\` 这个老牌游标解析器。它非常适合编写高效的词法分析器 (Lexer) 和协议文本解析器。
