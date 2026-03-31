# SwiftUI 中的 Toolbar

在 SwiftUI 中，`Toolbar` 提供了一种统一的、声明式的方式来向用户界面上的特定区域（如导航栏、底部栏、键盘附件栏等）添加操作按钮或控件。它取代了 `UIKit` 中分散的 `UINavigationBar`、`UIToolbar` 和 `inputAccessoryView` 等概念，提供了一个更强大、更具适应性的 API。

## 核心用法：`.toolbar()` 修饰符

你通过将 `.toolbar()` 修饰符附加到视图层级的任何位置来定义工具栏内容。SwiftUI 会自动将你提供的内容放置到最合适的系统区域。

`.toolbar()` 修饰符接收一个 `ToolbarContent` 构建器闭包，你可以在其中放置一个或多个 `ToolbarItem`。

```swift
import SwiftUI

struct BasicToolbarExample: View {
    var body: some View {
        NavigationView {
            Text("主内容区域")
                .navigationTitle("带 Toolbar 的视图")
                // 定义工具栏内容
                .toolbar {
                    // 创建一个工具栏项目
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("编辑") {
                            print("编辑按钮被点击")
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(systemImage: "sidebar.left") {
                            print("侧边栏按钮被点击")
                        }
                    }
                }
        }
    }
}

#Preview {
    BasicToolbarExample()
}
```

在这个例子中：
1.  我们将 `.toolbar()` 修饰符应用在 `Text` 视图上（实际上，它可以放在 `NavigationView` 内的任何地方）。
2.  在 `toolbar` 闭包内，我们定义了两个 `ToolbarItem`。
3.  `ToolbarItem` 的 `placement` 参数是关键，它告诉 SwiftUI 这个项目应该被放置在哪里。

## `ToolbarItem` 的位置 (`placement`)

`placement` 参数的类型是 `ToolbarItemPlacement`，它提供了大量预设的位置，可以适应不同平台和不同尺寸的设备。

### 导航栏相关位置

*   `.navigationBarLeading`: 导航栏左侧，通常用于返回按钮或菜单按钮。
*   `.navigationBarTrailing`: 导航栏右侧，通常用于“完成”、“编辑”、“添加”等主要操作。
*   `.principal`: 导航栏中间位置，可以放置一个自定义的标题视图，而不仅仅是文本。

### 底部栏相关位置

*   `.bottomBar`: 在 iOS 上表现为屏幕底部的工具栏。你可以放置多个 `ToolbarItem` 在这里。

```swift
.toolbar {
    ToolbarItem(placement: .bottomBar) {
        HStack {
            Button("分享", systemImage: "square.and.arrow.up") { }
            Spacer()
            Button("回复", systemImage: "arrowshape.turn.up.left") { }
            Spacer()
            Button("删除", systemImage: "trash") { }
        }
    }
}
```

### 键盘相关位置

*   `.keyboard`: 在键盘上方创建一个附件工具栏。这对于在文本输入时提供快捷操作（如“完成”、“下一步”）非常有用。

```swift
struct KeyboardToolbarExample: View {
    @State private var text = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField("输入内容...", text: $text)
            .focused($isFocused)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") {
                        isFocused = false // 点击按钮关闭键盘
                    }
                }
            }
    }
}
```

## `ToolbarItemGroup`

当你需要在同一个位置放置多个 `ToolbarItem` 时，应该使用 `ToolbarItemGroup` 将它们组合起来。这有助于 SwiftUI 更好地理解它们的逻辑分组，并应用正确的间距和布局。

```swift
.toolbar {
    // 在导航栏右侧放置一组按钮
    ToolbarItemGroup(placement: .navigationBarTrailing) {
        Button("收藏", systemImage: "star") { }
        Button("分享", systemImage: "square.and.arrow.up") { }
    }
}
```

## 自定义 `Toolbar` 的外观

从 iOS 16 开始，你可以使用一系列新的修饰符来定制 `Toolbar` 的背景和颜色方案。

*   `.toolbarBackground(_:for:)`: 设置工具栏的背景。可以是颜色、材质（Material）或任何 `ShapeStyle`。
*   `.toolbarBackground(.visible, for:)`: 确保工具栏的背景始终可见（默认情况下，在滚动时可能会变为透明）。
*   `.toolbarColorScheme(_:for:)`: 为工具栏设置一个特定的配色方案（`.dark` 或 `.light`），这会影响其中所有项目（按钮、标题）的颜色。

```swift
struct ThemedToolbarExample: View {
    var body: some View {
        NavigationStack {
            Color.gray.opacity(0.2)
                .navigationTitle("自定义 Toolbar")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("编辑") { }
                    }
                }
                // --- 自定义外观 ---
                .toolbarBackground(.purple, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar) // 让按钮和标题变为白色
        }
    }
}

#Preview {
    ThemedToolbarExample()
}
```

## 总结

`.toolbar()` 修饰符是 SwiftUI 中一个强大而灵活的工具，它统一了在应用不同区域放置操作控件的方式。

*   **声明式**: 你只需要声明你想要放置的内容和位置，SwiftUI 会负责具体的呈现。
*   **适应性强**: 同一套 `Toolbar` 定义可以根据平台（iOS/macOS）和上下文（导航栏/底部栏/键盘）自动调整其外观。
*   **位置精确**: 通过 `ToolbarItemPlacement`，你可以精确地控制每个控件应该出现的位置。
*   **可定制**: 支持通过 `.toolbarBackground` 等修饰符来定制外观，以匹配你的应用品牌风格。

通过熟练使用 `.toolbar()`，你可以构建出符合平台规范、功能强大且外观精美的导航和操作界面。
