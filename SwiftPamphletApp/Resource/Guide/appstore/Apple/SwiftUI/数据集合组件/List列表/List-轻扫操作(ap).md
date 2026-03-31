# SwiftUI List：轻扫操作 (Swipe Actions)

轻扫操作（Swipe Actions）是 iOS 上一种常见且高效的交互模式，允许用户通过在列表行上向左或向右轻扫，来快速执行一些常见的上下文操作，例如删除、标记为已读、收藏等。

从 iOS 15 开始，SwiftUI 提供了 `.swipeActions()` 修饰符，使得为 `List` 或 `ForEach` 中的行添加这种功能变得非常简单。

## 核心用法：`.swipeActions()`

`.swipeActions()` 修饰符可以被附加到 `List` 中的任何视图上（通常是 `ForEach` 内部的行视图）。它接收一个闭包，你可以在其中定义一个或多个 `Button` 作为轻扫时显示的操作。

### 1. 尾随轻扫 (Trailing Swipe)

默认情况下，`.swipeActions()` 添加的是**尾随**操作，即从右向左轻扫时出现的操作。

```swift
import SwiftUI

struct SwipeActionsExample: View {
    @State private var items = ["Apple", "Banana", "Cherry", "Date"]

    var body: some View {
        NavigationView {
            List {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .swipeActions { // 默认是尾随操作
                            Button(role: .destructive) {
                                // 执行删除操作
                                if let index = items.firstIndex(of: item) {
                                    items.remove(at: index)
                                }
                            } label: {
                                Label("删除", systemImage: "trash.fill")
                            }
                            
                            Button {
                                // 执行收藏操作
                            } label: {
                                Label("收藏", systemImage: "star.fill")
                            }
                            .tint(.yellow) // 自定义按钮颜色
                        }
                }
            }
            .navigationTitle("轻扫操作")
        }
    }
}

#Preview {
    SwipeActionsExample()
}
```

在这个例子中：
*   我们为 `Text` 行视图附加了 `.swipeActions`。
*   在闭包中，我们定义了两个 `Button`：“删除”和“收藏”。
*   SwiftUI 会自动处理轻扫手势，并以符合系统规范的方式显示这些按钮。
*   **按钮顺序**: 你在闭包中定义的**第一个**按钮，会成为用户**完全向左轻扫**时触发的“全轻扫”默认操作。在这个例子中，就是“删除”。
*   **样式**: 使用 `.destructive` 角色的按钮会自动显示为红色。对于其他按钮，你可以使用 `.tint()` 来指定背景颜色。

### 2. 前导轻扫 (Leading Swipe)

要添加**前导**操作（从左向右轻扫），你需要为 `.swipeActions` 的 `edge` 参数指定 `.leading`。

```swift
Text(item)
    .swipeActions(edge: .leading) {
        Button {
            // 标记为已读
        } label: {
            Label("已读", systemImage: "envelope.open.fill")
        }
        .tint(.blue)
    }
```

你可以同时为一个视图附加**两个** `.swipeActions` 修饰符，一个用于 `.trailing`（默认），一个用于 `.leading`，从而实现双向轻扫操作。

## 控制全轻扫行为

默认情况下，第一个按钮会自动成为全轻扫操作。你可以通过 `allowsFullSwipe` 参数来禁用这个行为。

```swift
.swipeActions(allowsFullSwipe: false) {
    Button(role: .destructive) { ... } label: { ... }
}
```

当 `allowsFullSwipe` 设置为 `false` 时，即使用户将行完全轻扫，也只会展开操作按钮，而不会直接触发第一个按钮的动作。

## 与 `.onDelete` 的关系

在 iOS 15 之前，实现滑动删除的唯一方式是使用 `.onDelete(perform:)` 修饰符。它仍然可用，可以看作是 `.swipeActions` 的一个简化版本，专门用于删除操作。

```swift
ForEach(items, id: \.self) { item in
    Text(item)
}
.onDelete { indexSet in
    items.remove(atOffsets: indexSet)
}
```

`.onDelete` 会自动创建一个带有“删除”标签的、红色的尾随轻扫操作。

**如何选择？**
*   如果你**只需要一个删除操作**，使用 `.onDelete` 更简洁。
*   如果你需要**多个轻扫操作**，或者需要**自定义按钮**（如不同的文本、图标、颜色），或者需要实现**前导轻扫**，那么必须使用 `.swipeActions`。

你**不能**在同一个 `ForEach` 上同时使用 `.onDelete` 和带有 `.destructive` 按钮的尾随 `.swipeActions`，因为它们的功能是重叠的。

## 总结

`.swipeActions()` 是 SwiftUI 中一个强大而直观的 API，用于为列表行添加上下文相关的快捷操作。

*   **简单易用**: 只需将一个或多个 `Button` 放置在 `.swipeActions` 闭包中即可。
*   **方向控制**: 通过 `edge` 参数可以分别定义尾随（`.trailing`）和前导（`.leading`）操作。
*   **样式化**: 使用 `Button` 的 `role` 和 `.tint()` 修饰符来定制按钮的外观。
*   **全轻扫**: 默认支持全轻扫手势，并可以通过 `allowsFullSwipe` 参数进行控制。

通过使用 `.swipeActions`，你可以轻松地为你的 `List` 添加符合 iOS 设计规范的、用户所熟悉的交互功能，极大地提升应用的操作效率。
