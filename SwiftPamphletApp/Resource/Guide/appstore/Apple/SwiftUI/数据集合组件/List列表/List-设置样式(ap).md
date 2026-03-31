# SwiftUI List：设置样式

SwiftUI 的 `List` 是一个功能强大且高度可定制的组件。除了显示数据，它还提供了一系列修饰符，让你能够精细地控制其外观和感觉，以匹配你的应用设计并符合平台规范。

## 1. 列表样式 (`.listStyle()`)

`.listStyle()` 是定制 `List` 整体外观的最主要方式。SwiftUI 提供了多种内置样式，它们在不同平台和上下文中的表现各不相同。

*   **`.automatic`**: 默认样式，由系统根据上下文（如是否在 `NavigationView` 中）自动选择。
*   **`.plain`**: 朴素样式。行与行之间只有简单的分隔线，没有额外的背景或分组。
*   **`.grouped`**: 分组样式。`Section` 会被渲染成带有页眉和页脚的、视觉上独立的分组，通常用于设置页面。
*   **`.insetGrouped`**: 内嵌分组样式（iOS 上的默认样式）。与 `.grouped` 类似，但整个列表会有圆角和边距，使其从屏幕边缘内缩。
*   **`.sidebar`**: 侧边栏样式（在 macOS 和 iPadOS 上）。专门为 `NavigationSplitView` 的侧边栏设计的样式，通常具有半透明的背景和适应性的行高亮。

```swift
import SwiftUI

struct ListStyleExample: View {
    var body: some View {
        // 尝试在不同的设备（iPhone/iPad）上预览，观察样式的变化
        List {
            Section(header: Text("Section 1")) {
                Text("Item 1")
                Text("Item 2")
            }
            Section(header: Text("Section 2")) {
                Text("Item 3")
                Text("Item 4")
            }
        }
        //.listStyle(.plain)
        //.listStyle(.grouped)
        .listStyle(.insetGrouped)
    }
}

#Preview {
    ListStyleExample()
}
```

## 2. 行级样式修饰符

你可以对 `List` 中的每一行应用修饰符，来单独控制其外观。

### 行背景 (`.listRowBackground()`)

为单个或多个行设置一个自定义的背景视图。这对于高亮显示特定行或创建交替行颜色（斑马条纹）非常有用。

```swift
List(1..<11) { i in
    Text("Row \(i)")
        .listRowBackground((i % 2 == 0) ? Color.blue.opacity(0.1) : Color.clear)
}
```

### 行分隔线 (`.listRowSeparator` & `.listRowSeparatorTint`)

从 iOS 15 开始，你可以更精细地控制行分隔线的可见性和颜色。

*   **`.listRowSeparator(.hidden)`**: 隐藏某一行的分隔线。
*   **`.listRowSeparatorTint(_:)`**: 改变分隔线的颜色。

```swift
List(1..<11) { i in
    Text("Row \(i)")
        .listRowSeparator(i % 2 == 0 ? .hidden : .visible)
        .listRowSeparatorTint(i == 5 ? .red : .gray)
}
```

### 行内边距 (`.listRowInsets()`)

覆盖系统为列表行提供的默认内边距。

```swift
Text("Custom Insets")
    .listRowInsets(EdgeInsets(top: 0, leading: 40, bottom: 0, trailing: 0))
```

## 3. Section 样式

`Section` 的页眉（`header`）和页脚（`footer`）可以是任何 `View`，这为你提供了丰富的自定义空间。

```swift
Section(
    header: 
        HStack {
            Image(systemName: "flame.fill")
            Text("热门项目")
        }
        .font(.headline)
        .foregroundColor(.red),
    footer: 
        Text("数据每小时更新一次。")
) {
    // ... Section 内容
}
```

## 4. 列表整体外观

### 背景 (`.background` & `.scrollContentBackground`)

*   **`.background()`**: 为 `List` 设置背景。在 iOS 16 之前，这通常需要一些额外的技巧（如 `ZStack` 或修改 `UITableView.appearance()`）。
*   **`.scrollContentBackground(.hidden)`** (iOS 16+): 这是一个重要的修饰符，它会**隐藏** `List` 默认的、不透明的背景（如纯白色或灰色），从而让你自己的 `.background()` 修饰符能够显示出来。

```swift
// iOS 16+ 的推荐做法
List { ... }
    .scrollContentBackground(.hidden) // 隐藏默认背景
    .background(LinearGradient(...)) // 应用你自己的背景
```

### 改变 `List` 的颜色

*   **`.tint()`**: 改变 `List` 中可交互元素的默认颜色，例如 `NavigationLink` 的箭头、编辑模式下的图标等。
*   **`.foregroundColor()`**: 改变 `List` 中所有文本的默认颜色（除非被行内视图自己的 `.foregroundColor` 覆盖）。

## 总结

SwiftUI 的 `List` 提供了从宏观到微观的、丰富的样式定制能力。

*   **整体风格**: 使用 `.listStyle()` 来设定 `List` 的整体外观（如 `.plain`, `.grouped`, `.insetGrouped`）。
*   **行级控制**: 使用 `.listRowBackground`, `.listRowSeparator`, `.listRowInsets` 等修饰符来精细地调整每一行的样式。
*   **背景与颜色**: 在 iOS 16+ 中，使用 `.scrollContentBackground(.hidden)` 配合 `.background()` 来设置自定义背景；使用 `.tint()` 来改变交互元素的颜色。

通过组合使用这些样式修饰符，你可以将一个标准的 `List`，打造成完全符合你的应用设计风格的、功能强大且外观精美的数据展示组件。
