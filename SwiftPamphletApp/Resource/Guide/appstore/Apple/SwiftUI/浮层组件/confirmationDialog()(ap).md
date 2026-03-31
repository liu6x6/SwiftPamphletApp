# SwiftUI 浮层组件：confirmationDialog (iOS 15+)

`.confirmationDialog()` 是 SwiftUI 在 iOS 15 中引入的一个现代化修饰符，用于向用户呈现一组与某个操作相关的选项。它在功能上取代了旧的、在 `UIKit` 中被称为“动作表单”（Action Sheet）的组件。

当用户需要从多个选项中选择一个来完成一个任务时（例如，选择分享方式、选择照片来源、或确认一个危险操作），确认对话框提供了一种符合平台规范的、优雅的交互方式。

## 核心用法

与现代的 `.alert()` 修饰符类似，`.confirmationDialog()` 也是通过绑定一个 `Binding<Bool>` 或一个 `Binding<Identifiable?>` 来触发显示，并使用 `@ViewBuilder` 闭包来定义其内容。

### 1. 基本用法 (基于 `isPresented`)

```swift
import SwiftUI

struct BasicConfirmationDialog: View {
    @State private var showDialog = false

    var body: some View {
        Button("显示选项") {
            showDialog = true
        }
        .confirmationDialog(
            "选择一个操作",
            isPresented: $showDialog,
            titleVisibility: .visible // 确保标题总是可见
        ) {
            // 在这里定义一系列按钮作为选项
            Button("添加收藏") { /* ... */ }
            Button("分享项目") { /* ... */ }
            
            // 使用 .destructive 角色来标记危险操作
            Button("删除", role: .destructive) { /* ... */ }
            
            // 使用 .cancel 角色来提供一个清晰的取消选项
            // 系统会自动处理其外观和位置
            Button("取消", role: .cancel) { }
        }
    }
}

#Preview {
    BasicConfirmationDialog()
}
```

在这个例子中：
*   `showDialog` 状态变量控制对话框的显示。
*   `.confirmationDialog()` 的 `isPresented` 参数与 `$showDialog` 双向绑定。
*   在 `actions` 闭包中，我们提供了一系列 `Button`。`role` 参数 (`.destructive`, `.cancel`) 对于提供正确的语义和视觉样式至关重要。
*   在 iOS 上，这通常会从屏幕底部弹出一个选项列表。在 iPadOS 和 macOS 上，它可能会表现为一个弹出框（Popover）。

### 2. 添加消息

与 `.alert` 类似，你也可以添加一个 `message` 闭包来提供更详细的上下文信息。

```swift
.confirmationDialog(
    "确认删除这篇帖子吗？",
    isPresented: $showDialog,
    titleVisibility: .visible
) {
    Button("删除", role: .destructive) { }
} message: {
    Text("此操作不可撤销，所有相关评论和点赞都将被永久删除。")
}
```

## 平台间的差异与自适应

`confirmationDialog` 的一个巨大优势是它的自适应性。

*   **iPhone**: 默认从屏幕底部滑出一个动作列表（Action Sheet）。
*   **iPad & Mac**: 默认显示为一个指向触发按钮的弹出框（Popover）。

你无需编写任何设备判断代码，SwiftUI 会自动为你处理这种平台差异，确保你的应用在所有设备上都表现得自然、得体。

## `.confirmationDialog` vs. `.alert`

虽然两者都是模态对话框，但它们的语义和适用场景不同。

*   **`.alert` (警告框)**:
    *   **用途**: 用于**通知**用户一个重要的、需要立即关注的事件，或者**确认**一个只有两个选项（通常是“确认”和“取消”）的关键操作。
    *   **特点**: 强调的是“警告”和“确认”。通常包含较少的按钮。
    *   **例子**: “登录失败”、“确认删除？”、“网络连接已断开”。

*   **`.confirmationDialog` (确认对话框 / 动作表单)**:
    *   **用途**: 为一个特定的任务，向用户提供**一组两个或更多的选项**。
    *   **特点**: 强调的是“选择”。它提供了一个操作列表让用户挑选。
    *   **例子**: 点击“分享”按钮后，弹出“信息”、“邮件”、“隔空投送”等选项；点击用户头像后，弹出“拍照”、“从相册选择”等选项。

**经验法则**：如果你需要用户从多个并列的操作中选择一个，使用 `.confirmationDialog`。如果你只是想显示一条信息或让用户对一个简单的“是/否”问题做出决定，使用 `.alert`。

## 总结

`.confirmationDialog()` 是 SwiftUI 中用于呈现一组操作选项的现代化、标准化的方式。

*   **替代 Action Sheet**: 它在功能上取代了 `UIKit` 中的 `UIActionSheet`。
*   **数据驱动**: 通过 `isPresented` 或 `item` 绑定来控制其显示，与 SwiftUI 的状态管理无缝集成。
*   **自适应**: 自动在 iPhone (Action Sheet) 和 iPad/Mac (Popover) 之间切换最佳的呈现样式。
*   **语义化**: 通过 `Button` 的 `role` 参数，可以清晰地定义每个操作的意图（如破坏性操作或取消操作）。

通过在合适的场景下使用 `.confirmationDialog`，你可以为用户提供清晰、符合平台规范的多选项交互体验，而无需处理复杂的视图呈现逻辑。
