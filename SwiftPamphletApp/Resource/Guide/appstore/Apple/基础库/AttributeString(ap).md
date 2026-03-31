# AttributedString：新一代富文本排版引擎

在 iOS 15 和 macOS 12 中，Apple 推出了基于纯 Swift 编写的全新结构体 **\`AttributedString\`**，彻底重构了历史悠久且基于 Objective-C 的 \`NSAttributedString\`。

它更加类型安全、语法现代，并且**深度、原生集成于 SwiftUI 的 \`Text\` 视图之中**。

## 1. 为什么需要 AttributedString？

原生的 \`NSAttributedString\` 使用 \`[NSAttributedString.Key: Any]\` 字典来管理样式（如字体大小、颜色、下划线），极其容易写错键名，而且强转类型非常繁琐。

新的 \`AttributedString\` 利用了 Swift 的动态成员查找（dynamic member lookup）等高级特性，让你可以像修改结构体属性一样、以类型绝对安全的方式去设置文本样式。

## 2. 基础用法与样式设置

### 创建并设置全局样式
```swift
import SwiftUI

var str = AttributedString("这是新一代富文本")
// 类型安全！不需要像以前那样传 UIFont 或字典
str.font = .system(size: 20, weight: .bold)
str.foregroundColor = .blue
str.underlineStyle = .single
str.underlineColor = .red
```

### 设置局部文字样式
你可以使用 Swift 的各种集合操作或原生 \`Range\` 来修改一段文字中特定部分的样式。

```swift
var msg = AttributedString("请仔细阅读 隐私政策 并同意。")

// 查找特定字符串的范围 (Range)
if let range = msg.range(of: "隐私政策") {
    // 对这四个字应用特殊的高亮样式和超链接
    msg[range].foregroundColor = .blue
    msg[range].font = .boldSystemFont(ofSize: 16)
    msg[range].link = URL(string: "https://example.com/privacy")!
}
```

## 3. 在 SwiftUI 中无缝渲染

在以前，要在 SwiftUI 里显示富文本简直是噩梦（通常要用 \`UIViewRepresentable\` 包装 \`UILabel\`）。现在，SwiftUI 的 \`Text\` 视图直接接受 \`AttributedString\` 作为参数！

```swift
struct RichTextView: View {
    var body: some View {
        // 直接把上面构造好的 msg 传给 Text
        Text(msg)
            .padding()
            // 如果 AttributedString 里包含了 link，用户可以直接点击跳转
    }
}
```

## 4. 基于 Markdown 初始化

这是 \`AttributedString\` 最令人兴奋的特性之一。它可以直接解析遵循 Markdown 语法的字符串！

```swift
let markdownText = """
# 重大更新
这是 **极其重要** 的内容，请访问 [苹果官网](https://apple.com) 了解。
* 支持斜体
* 支持~~删除线~~
"""

do {
    // 直接从 Markdown 字符串生成带完整排版样式的富文本
    let attrStr = try AttributedString(markdown: markdownText)
    
    // 你依然可以拿着这个 attrStr 传给 SwiftUI 的 Text 进行显示
} catch {
    print("Markdown 解析失败")
}
```

## 5. 与旧版 NSAttributedString 互相转换

由于底层的 UIKit（如 \`UITextView\`, \`UILabel\`）依然只接收旧版的 \`NSAttributedString\`，Apple 提供了双向转换的桥梁。

```swift
// Swift 结构体 -> ObjC 类
let oldObjcStr = NSAttributedString(msg)

// ObjC 类 -> Swift 结构体
let newSwiftStr = try? AttributedString(oldObjcStr)
```

## 总结

处理带有高亮、多颜色、包含超链接文字的需求，不再需要拼接多个 Text (例如 \`Text("a") + Text("b").foregroundColor(.red)\`)，请一律使用最新的 \`AttributedString\`，并在最后抛给一个单一的 SwiftUI \`Text\` 渲染。
