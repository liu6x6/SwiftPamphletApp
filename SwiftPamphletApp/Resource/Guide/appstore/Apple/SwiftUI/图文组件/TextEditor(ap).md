# SwiftUI 中的 TextEditor 视图

当你需要处理多行文本的输入或显示时，`TextEditor` 是 SwiftUI 提供的标准解决方案。它相当于 UIKit 中的 `UITextView`，非常适合用于创建笔记应用、代码编辑器、长篇表单填写等场景。

与用于单行文本输入的 `TextField` 不同，`TextEditor` 天生支持垂直滚动，可以容纳任意长度的文本内容。

## 基本用法

创建一个 `TextEditor` 非常简单，你只需要将其绑定到一个字符串类型的 `@State` 变量即可。

```swift
import SwiftUI

struct BasicTextEditorExample: View {
    @State private var fullText: String = "这是初始文本..."

    var body: some View {
        VStack {
            Text("笔记内容")
                .font(.headline)
            
            // 将 TextEditor 与 fullText 状态变量绑定
            TextEditor(text: $fullText)
                .font(.body)
                .frame(height: 200) // 建议为 TextEditor 设置一个初始框架
                .border(Color.gray, width: 1)
        }
        .padding()
    }
}

#Preview {
    BasicTextEditorExample()
}
```

在这个例子中：
1.  我们声明了一个名为 `fullText` 的 `@State` 变量来存储编辑器的内容。
2.  `TextEditor(text: $fullText)` 创建了编辑器实例，并通过 `$` 符号实现了双向绑定。这意味着当用户在编辑器中输入时，`fullText` 的值会自动更新；反之，如果代码改变了 `fullText` 的值，编辑器中的文本也会刷新。
3.  我们为 `TextEditor` 设置了 `.frame()` 和 `.border()` 来定义其在界面上的可见区域和外观。

## 自定义外观

`TextEditor` 本身是一个非常基础的视图，但你可以像对待其他 SwiftUI 视图一样，通过应用各种修饰符来自定义其外观。

### 字体和颜色

你可以使用 `.font()` 和 `.foregroundColor()` 来改变文本的样式。

```swift
TextEditor(text: $fullText)
    .font(.custom("Menlo", size: 16)) // 设置为等宽字体
    .foregroundColor(.blue)
```

### 行间距

使用 `.lineSpacing()` 可以调整文本行与行之间的距离。

```swift
TextEditor(text: $fullText)
    .lineSpacing(10)
```

### 背景颜色

`TextEditor` 的背景默认是透明的。如果你想改变它的背景色，需要注意一个细节：在 iOS 16 之前，你需要使用 `UITextView.appearance()` 来全局设置；而在 iOS 16 及之后，你可以使用 `.scrollContentBackground()` 修饰符。

```swift
struct BackgroundTextEditorExample: View {
    @State private var text: String = ""

    var body: some View {
        TextEditor(text: $text)
            .padding()
            .background(Color.clear) // 确保背景是透明的，以便 .scrollContentBackground 生效
            .scrollContentBackground(.hidden) // 隐藏系统默认的背景
            .background(Color.yellow.opacity(0.2)) // 应用你自己的背景颜色
            .cornerRadius(10)
    }
}

#Preview {
    BackgroundTextEditorExample()
}
```

**对于 iOS 16+**: `.scrollContentBackground(.hidden)` 是关键，它移除了系统默认的背景，让你自己的 `.background()` 修饰符能够显示出来。

### 禁用自动大写和拼写检查

对于代码编辑器或特定输入场景，你可能希望禁用系统的自动更正功能。

```swift
TextEditor(text: $fullText)
    .autocapitalization(.none) // 禁用首字母自动大写
    .disableAutocorrection(true) // 禁用自动拼写纠正
```

## 处理键盘

在移动设备上，如何处理键盘的出现和消失是一个常见的挑战。当 `TextEditor` 获得焦点时，键盘会弹出，并可能遮挡住编辑器本身。

虽然 SwiftUI 本身没有提供一个直接的“躲避键盘”修饰符，但 `TextEditor` 在 `ScrollView` 或 `List` 中时，通常会自动处理滚动以确保光标可见。

对于更复杂的场景，你可能需要观察键盘的 `UIResponder.keyboardWillShowNotification` 和 `UIResponder.keyboardWillHideNotification` 通知，来手动调整你的布局，但这通常超出了 `TextEditor` 本身的范畴。

## 与 `TextField` 的选择

*   **`TextField`**: 用于**单行**文本输入。例如：用户名、密码、搜索框。
*   **`TextEditor`**: 用于**多行**文本输入。例如：笔记、评论、文章正文。

## 总结

`TextEditor` 是 SwiftUI 中处理多行文本输入不可或缺的工具。它的核心是通过与 `@State` 变量的双向绑定来工作。虽然它的内置可定制性选项不多，但你可以充分利用 SwiftUI 强大的修饰符系统，通过组合 `.font()`, `.foregroundColor()`, `.lineSpacing()`, `.background()` 等来打造出符合你设计需求的文本编辑区域。

记住，对于 iOS 16 及更高版本，使用 `.scrollContentBackground(.hidden)` 是自定义背景的关键。
