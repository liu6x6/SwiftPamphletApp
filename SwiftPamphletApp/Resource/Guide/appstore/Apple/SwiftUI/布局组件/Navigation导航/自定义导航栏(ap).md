# SwiftUI 中自定义导航栏

导航栏（Navigation Bar）是应用中最重要的 UI 元素之一，它不仅提供了导航上下文（如标题和返回按钮），还是放置主要操作按钮（如“编辑”、“完成”、“添加”）的核心区域。SwiftUI 提供了一系列强大的修饰符，让你能够以声明式的方式，轻松地定制导航栏的外观和内容。

这些定制主要通过一系列以 `.toolbar` 和 `.navigation` 开头的修饰符来完成。

## 1. 设置标题 (`.navigationTitle`)

`.navigationTitle()` 是设置导航栏标题最直接的方式。它可以接受一个字符串，或者一个自定义的 `View`。

```swift
import SwiftUI

struct NavigationTitleExample: View {
    var body: some View {
        NavigationStack {
            Text("内容")
                // 设置一个简单的文本标题
                .navigationTitle("我的标题")
        }
    }
}
```

### 标题显示模式 (`.navigationBarTitleDisplayMode`)

你可以通过这个修饰符来控制标题的显示样式：

*   `.large`: 大标题样式，在 iOS 上会随着滚动自动切换为小标题。
*   `.inline`: 小标题样式，始终紧凑地显示在导航栏中间。
*   `.automatic`: 默认行为，由系统根据上下文决定。

```swift
NavigationStack {
    List(0..<50) { i in
        Text("Row \(i)")
    }
    .navigationTitle("滚动标题")
    .navigationBarTitleDisplayMode(.large) // 初始为大标题
}
```

## 2. 添加按钮 (`.toolbar`)

`.toolbar` 修饰符是向导航栏（以及其他工具栏区域）添加按钮的**唯一正确方式**。你应该避免使用旧的、已被废弃的 `.navigationBarItems`。

在 `.toolbar` 闭包中，你使用 `ToolbarItem` 或 `ToolbarItemGroup` 来定义你的按钮及其位置。

```swift
struct ToolbarItemsExample: View {
    var body: some View {
        NavigationStack {
            Text("内容")
                .navigationTitle("带按钮的导航栏")
                .toolbar {
                    // 在导航栏右侧（主要操作位置）添加一个按钮
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("添加", systemImage: "plus") { }
                    }
                    
                    // 在导航栏左侧添加一组按钮
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        Button("编辑") { }
                        Button("菜单", systemImage: "ellipsis.circle") { }
                    }
                }
        }
    }
}

#Preview {
    ToolbarItemsExample()
}
```

（更多详情请参阅 `Toolbar协议(ap).md`）

## 3. 自定义背景和颜色 (iOS 16+)

从 iOS 16 开始，SwiftUI 引入了一套全新的 API 来定制导航栏的背景和颜色方案，提供了前所未有的灵活性。

*   **`.toolbarBackground(_:for:)`**: 设置导航栏的背景。你可以使用任何 `ShapeStyle`，包括颜色、渐变或材质（Materials）。
*   **`.toolbarBackground(.visible, for:)`**: 确保导航栏的背景**始终可见**。默认情况下，当内容滚动到导航栏下方时，背景可能会变为透明。这个修饰符可以禁用该行为。

```swift
struct ToolbarAppearanceExample: View {
    var body: some View {
        NavigationStack {
            List(0..<50) { i in Text("Row \(i)") }
                .navigationTitle("自定义背景")
                .toolbar {
                    ToolbarItem { Button("Action"){} }
                }
                // 1. 设置背景为紫色
                .toolbarBackground(.purple, for: .navigationBar)
                // 2. 确保背景在滚动时也可见
                .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

#Preview {
    ToolbarAppearanceExample()
}
```

### `.toolbarColorScheme`

当你设置了一个深色的导航栏背景时，默认的黑色标题和蓝色按钮可能会变得难以辨认。`.toolbarColorScheme(_:for:)` 修饰符可以解决这个问题。

将配色方案设置为 `.dark`，会告诉 SwiftUI 应该在这个工具栏中使用适合深色背景的前景颜色（通常是白色或浅灰色）。

```swift
.toolbarBackground(.purple, for: .navigationBar)
.toolbarBackground(.visible, for: .navigationBar)
// 3. 将前景内容（标题、按钮）的颜色方案设为深色模式
.toolbarColorScheme(.dark, for: .navigationBar)
```

## 4. 隐藏导航栏

你可以使用 `.toolbar(.hidden, for: .navigationBar)` 来完全隐藏导航栏。

```swift
NavigationStack {
    MyView()
        .toolbar(.hidden, for: .navigationBar)
}
```

这比旧的 `.navigationBarHidden(true)` 方式更推荐，因为它更灵活，可以分别控制不同工具栏的可见性。

## 5. 自定义返回按钮

SwiftUI 会自动处理返回按钮的显示和行为。虽然不推荐完全替换它（因为这会破坏平台的一致性），但你可以通过自定义 `ToolbarItem` 并使用 `presentationMode` 环境值来创建自定义的返回行为。

```swift
struct CustomBackButton: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        // ...
        .navigationBarBackButtonHidden(true) // 隐藏系统默认的返回按钮
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    // 在这里可以添加自定义逻辑，如弹出确认框
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "chevron.left.circle.fill")
                }
            }
        }
    }
}
```

## 总结

SwiftUI 的现代导航系统提供了一套强大而声明式的 API 来定制导航栏。

*   **标题**: 使用 `.navigationTitle` 和 `.navigationBarTitleDisplayMode`。
*   **按钮**: 使用 `.toolbar` 和 `ToolbarItem` / `ToolbarItemGroup`。
*   **外观 (iOS 16+)**: 使用 `.toolbarBackground` 和 `.toolbarColorScheme` 来完全控制背景和前景颜色。
*   **可见性**: 使用 `.toolbar(.hidden, ...)` 来控制显示和隐藏。

通过组合这些修饰符，你可以轻松地创建出既符合应用品牌风格，又能在所有苹果平台上表现良好的自定义导航栏。
