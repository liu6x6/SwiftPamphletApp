# SwiftUI 浮层组件：Menu 与 ContextMenu

在 SwiftUI 中，`Menu` 和 `ContextMenu` 都是用于向用户呈现一组操作选项的浮层组件。尽管它们都显示一个选项列表，但它们的触发方式和适用场景有明显的区别。

## `Menu`

`Menu` 是一个**显式**的 UI 控件，它本身表现为一个可点击的按钮或标签。当用户**单击**它时，会弹出一个包含一系列操作（通常是 `Button`）的菜单。

`Menu` 非常适合用于工具栏、导航栏或任何你需要将一组不常用的、或折叠起来的操作放置在一个按钮下的场景。

### 核心用法

创建一个 `Menu` 需要提供两个部分：

1.  **`label`**: 一个视图闭包，定义了菜单按钮本身的外观。
2.  **`content`**: 一个视图闭包，其中包含了一系列作为菜单项的 `Button`、`Toggle` 或子 `Menu`。

```swift
import SwiftUI

struct MenuExample: View {
    var body: some View {
        Menu {
            // 2. 菜单的内容
            Button("打开", systemImage: "folder") { /* ... */ }
            Button("保存", systemImage: "square.and.arrow.down") { /* ... */ }
            
            Divider() // 添加分隔线
            
            // 可以在 Menu 中嵌套子 Menu
            Menu("编辑") {
                Button("复制") { /* ... */ }
                Button("粘贴") { /* ... */ }
            }
            
            Button("删除", role: .destructive, systemImage: "trash") { /* ... */ }
            
        } label: {
            // 1. 菜单按钮的标签
            Label("操作", systemImage: "ellipsis.circle")
                .font(.title)
        }
    }
}

#Preview {
    MenuExample()
}
```

在这个例子中：
*   `Menu` 的 `label` 是一个带有省略号图标的 `Label` 视图。
*   `content` 闭包中包含多个 `Button` 和一个子 `Menu`，它们会被渲染成一个标准的弹出菜单。

## `ContextMenu` (上下文菜单)

`ContextMenu`（上下文菜单）则是一种**隐式**的交互方式。它不是一个可见的按钮，而是通过一个特定的手势——通常是**长按**（在 iOS 上）或**右键单击**（在 macOS 上）——来触发的。

它通过 `.contextMenu()` 修饰符附加到任何视图上，为该视图提供一组与其“上下文”相关的快捷操作。

### 核心用法

你只需要将 `.contextMenu()` 修饰符应用到你希望拥有上下文菜单的视图上，并在其闭包中提供一系列 `Button`。

```swift
struct ContextMenuExample: View {
    var body: some View {
        Image(systemName: "swift")
            .resizable()
            .scaledToFit()
            .frame(width: 200)
            .foregroundColor(.orange)
            // 为 Image 附加一个上下文菜单
            .contextMenu {
                Button("复制", systemImage: "doc.on.doc") {
                    // ...
                }
                Button("分享", systemImage: "square.and.arrow.up") {
                    // ...
                }
                Button("删除", role: .destructive, systemImage: "trash") {
                    // ...
                }
            }
    }
}

#Preview {
    ContextMenuExample()
}
```

在这个例子中，当用户长按 Swift 图标时，一个包含“复制”、“分享”和“删除”选项的菜单会浮现出来。

### 带预览的上下文菜单 (`contextMenu(menuItems:preview:)`)

`ContextMenu` 还有一个更强大的版本，允许你在菜单的顶部显示一个自定义的预览视图。这可以为用户提供更丰富的上下文，让他们清楚地知道他们正在对哪个项目进行操作。

```swift
struct PreviewContextMenuExample: View {
    var body: some View {
        Text("长按我")
            .padding()
            .background(Color.yellow)
            .contextMenu {
                // MenuItems
                Button("操作 1") {}
                Button("操作 2") {}
            } preview: {
                // Preview View
                // 显示一个尺寸更大、更详细的预览版本
                Image(systemName: "swift")
                    .font(.system(size: 200))
                    .foregroundColor(.orange)
            }
    }
}
```

当用户长按“长按我”文本时，系统会首先显示一个放大的 Swift 图标作为预览，菜单选项则会出现在预览的下方。

## `Menu` vs. `ContextMenu`

| 特性 | `Menu` | `ContextMenu` |
| :--- | :--- | :--- |
| **触发方式** | **显式**：用户需要**单击**一个可见的按钮或标签。 | **隐式**：用户需要执行一个特定的手势（**长按**或**右键单击**）。 |
| **可见性** | 作为一个可见的 UI 控件，它本身是可发现的。 | **隐藏的**，没有视觉提示，依赖于用户的习惯或探索。 |
| **实现方式** | 是一个独立的**视图** (`Menu { ... } label: { ... }`)。 | 是一个**修饰符** (`.contextMenu { ... }`)，附加到其他视图上。 |
| **适用场景** | *   折叠不常用的操作（如工具栏中的“更多”）。
*   提供一组与某个按钮相关的选项（如“排序方式”）。
*   创建下拉菜单。 | *   为列表中的每一行提供快捷操作（如“删除”、“标记为已读”）。
*   为图片、文本或其他内容块提供上下文相关的操作（如“复制”、“分享”）。 |

**选择建议**：
*   如果操作是主要的、需要被用户轻易发现的，或者没有一个明确的“上下文”对象，使用 **`Menu`**。
*   如果操作是次要的、针对某个特定内容块的快捷方式，并且你希望保持 UI 的简洁，使用 **`ContextMenu`**。

## 总结

`Menu` 和 `ContextMenu` 都是用于组织和呈现操作选项的重要工具，但它们服务于不同的交互模式。

*   **`Menu`** 是一个**可见的按钮**，通过**单击**触发，用于折叠一组操作。
*   **`ContextMenu`** 是一个**不可见的修饰符**，通过**长按/右键单击**触发，用于提供与特定内容相关的快捷操作。

通过在你的应用中恰当地使用这两种菜单，你可以构建出既功能强大又整洁直观的用户界面。
