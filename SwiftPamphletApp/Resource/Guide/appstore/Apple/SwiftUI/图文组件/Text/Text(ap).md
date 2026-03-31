# SwiftUI 中的 Text 视图详解

`Text` 是 SwiftUI 中最基础、最核心的视图之一，用于在界面上显示只读的文本内容。尽管它看起来很简单，但 SwiftUI 为 `Text` 提供了极为丰富的修饰符和初始化方法，使其能够处理从简单的静态标签到复杂的、格式化的富文本等各种场景。

## 基本用法

创建一个 `Text` 视图最简单的方式就是提供一个字符串。

```swift
import SwiftUI

struct BasicTextExample: View {
    var body: some View {
        Text("Hello, SwiftUI!")
    }
}
```

## 常用文本样式修饰符

你可以通过链式调用一系列修饰符来改变文本的外观。

### 字体 (`.font()`)

`.font()` 修饰符用于设置文本的字体。你可以使用系统预设的动态类型字体，也可以使用自定义字体。

```swift
VStack(alignment: .leading, spacing: 10) {
    Text("系统大标题样式")
        .font(.largeTitle)
    
    Text("系统正文样式")
        .font(.body)
    
    Text("自定义字体和大小")
        .font(.custom("Georgia", size: 24))
}
```

使用 `.largeTitle`, `.body` 等系统动态类型字体是最佳实践，因为它们会自动适应用户的辅助功能设置（如“更大字体”）。

### 字重 (`.fontWeight()`)

`.fontWeight()` 或 `.bold()` 用于改变文本的粗细。

```swift
Text("Bold Text")
    .fontWeight(.bold) // 或者直接用 .bold()

Text("Light Text")
    .fontWeight(.light)
```

### 颜色 (`.foregroundColor()`)

设置文本的颜色。

```swift
Text("Red Text")
    .foregroundColor(.red)
```

### 斜体 (`.italic()`)

```swift
Text("Italic Text")
    .italic()
```

### 删除线和下划线

```swift
VStack(alignment: .leading) {
    Text("Strikethrough")
        .strikethrough(true, color: .red)
    
    Text("Underline")
        .underline(true, color: .blue)
}
```

## 文本布局修饰符

### 多行对齐 (`.multilineTextAlignment()`)

当文本有多行时，此修饰符用于控制文本的水平对齐方式。

```swift
Text("This is a long text that will wrap into multiple lines.")
    .multilineTextAlignment(.center) // .leading, .trailing
    .frame(width: 200)
```

### 行数限制 (`.lineLimit()`)

限制文本显示的最大行数。如果内容超出限制，末尾会自动显示省略号（...）。

```swift
Text("A very long text that will be truncated because it exceeds the line limit of two.")
    .lineLimit(2)
```

### 行间距 (`.lineSpacing()`)

调整多行文本之间的垂直间距。

```swift
Text("Line 1\nLine 2\nLine 3")
    .lineSpacing(10)
```

### 允许紧缩 (`.allowsTightening()`)

当空间不足时，允许系统稍微压缩字符间距以试图容纳所有文本。

```swift
Text("Allows Tightening")
    .allowsTightening(true)
```

## 富文本和组合

SwiftUI 的 `Text` 视图可以通过 `+` 操作符进行拼接，从而轻松地创建出具有不同样式的富文本。

```swift
struct RichTextExample: View {
    var body: some View {
        Text("SwiftUI is ")
            .font(.headline)
        + Text("awesome!")
            .font(.largeTitle)
            .fontWeight(.black)
            .foregroundColor(.purple)
        + Text(" It makes UI development fun and easy.")
            .font(.body)
            .italic()
    }
}

#Preview {
    RichTextExample()
}
```

当你用 `+` 连接多个 `Text` 视图时，它们会被组合成一个单一的文本块，并能正确地处理换行和布局。

## 显示特殊类型的数据

`Text` 不仅能显示字符串，还能直接处理和格式化其他数据类型。

### 数字和格式化

```swift
VStack(alignment: .leading, spacing: 10) {
    Text(123.456, format: .number)
    Text(99, format: .percent)
    Text(500, format: .currency(code: "USD"))
}
```

### 日期和时间

`Text` 可以显示动态更新的相对时间或倒计时，也可以格式化日期。

```swift
VStack(alignment: .leading, spacing: 10) {
    // 动态更新的倒计时
    Text(Date().addingTimeInterval(3600), style: .timer)
    
    // 格式化的日期
    Text(Date(), format: .dateTime.year().month().day())
}
```

### Markdown (iOS 15+)

从 iOS 15 开始，`Text` 可以直接渲染 Markdown 字符串，支持粗体、斜体、删除线、代码块和链接。

```swift
Text("**Bold** and *italic* text. Visit [Apple](https://apple.com). `code`")
```

## 总结

`Text` 是 SwiftUI 中一个看似简单但功能极其丰富的组件。掌握它的各种修饰符和初始化方法是构建任何 SwiftUI 应用的基础。关键点包括：

*   **样式修饰符**：通过 `.font`, `.foregroundColor` 等改变外观。
*   **布局修饰符**：通过 `.lineLimit`, `.multilineTextAlignment` 等控制布局。
*   **富文本组合**：使用 `+` 操作符拼接不同样式的 `Text`。
*   **数据格式化**：直接显示和格式化数字、日期等数据类型。

通过灵活组合这些功能，你可以用 `Text` 视图满足绝大多数文本显示的需求。
