# SwiftUI 浮层组件：全屏模态视图 (Full-Screen Modal)

在 SwiftUI 中，呈现一个全屏的模态视图（Full-Screen Modal View）是一种常见的交互模式，用于将用户的注意力完全集中在一个独立的任务上，例如创建新项目、编辑详细信息或展示一个引导流程。当一个视图以全屏模态的形式呈现时，它会完全覆盖下方的视图。

SwiftUI 提供了 `.fullScreenCover()` 修饰符来实现这一功能。

## 核心用法：`.fullScreenCover()`

`.fullScreenCover()` 的 API 与 `.sheet()` 非常相似。它也是通过绑定一个 `Binding<Bool>` 或一个 `Binding<Identifiable?>` 来控制显示。

### 1. 基于 `isPresented`

这是最直接的用法，通过一个布尔状态来控制全屏视图的显示和隐藏。

```swift
import SwiftUI

struct FullScreenCoverExample: View {
    @State private var showFullScreen = false

    var body: some View {
        Button("展示全屏视图") {
            showFullScreen = true
        }
        .fullScreenCover(isPresented: $showFullScreen) {
            // 这是当 showFullScreen 为 true 时要显示的全屏内容
            FullScreenView(isPresented: $showFullScreen)
        }
    }
}

// 一个简单的全屏视图示例
struct FullScreenView: View {
    // 接收一个绑定来关闭自己
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.mint.ignoresSafeArea()
            
            VStack {
                Text("这是一个全屏模态视图")
                    .font(.largeTitle)
                
                Button("关闭") {
                    isPresented = false // 将绑定值设为 false 来关闭视图
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
            }
        }
    }
}

#Preview {
    FullScreenCoverExample()
}
```

在这个例子中：
*   `showFullScreen` 状态变量控制着模态视图的生命周期。
*   当按钮被点击，`showFullScreen` 变为 `true`，`.fullScreenCover` 的 `content` 闭包被执行，`FullScreenView` 被呈现出来。
*   在 `FullScreenView` 内部，我们通过一个 `@Binding` 接收了 `isPresented` 的绑定。当“关闭”按钮被点击时，它将这个绑定值设置回 `false`，从而关闭了全屏视图。

### 2. 基于 `item`

当全屏视图的内容依赖于某个特定的数据项时，使用 `.fullScreenCover(item: ...)` 是一个更强大、更具 SwiftUI 风格的方式。

```swift
struct ItemBasedFullScreenCover: View {
    struct ItemDetail: Identifiable {
        let id = UUID()
        let title: String
    }
    
    @State private var selectedItem: ItemDetail?

    var body: some View {
        Button("查看详情") {
            selectedItem = ItemDetail(title: "我的项目详情")
        }
        .fullScreenCover(item: $selectedItem) { item in
            // SwiftUI 会自动解包 selectedItem 并将其传递给 content 闭包
            DetailView(item: item)
        }
    }
}

struct DetailView: View {
    // 使用 @Environment 来关闭视图
    @Environment(\.dismiss) var dismiss
    let item: ItemBasedFullScreenCover.ItemDetail

    var body: some View {
        VStack {
            Text(item.title).font(.largeTitle)
            Button("完成") {
                dismiss() // 调用 dismiss 来关闭视图
            }
        }
    }
}
```

在这个例子中：
*   `selectedItem` 是一个可选的 `ItemDetail` 对象。当它不为 `nil` 时，`.fullScreenCover` 会被触发。
*   `content` 闭包接收一个解包后的 `item`，并用它来创建 `DetailView`。
*   在 `DetailView` 中，我们使用了 `@Environment(\.dismiss)`。这是一个在 iOS 15+ 中引入的、用于关闭任何模态呈现的视图（包括 `sheet`, `fullScreenCover`, `popover`）的**标准方式**。调用 `dismiss()` 会自动将父视图中的 `@State` 变量（无论是 `isPresented` 还是 `item`）设置回 `false` 或 `nil`。这种方式比手动传递 `Binding<Bool>` 更推荐，因为它更解耦。

## `.fullScreenCover` vs. `.sheet`

虽然两者都用于呈现模态视图，但它们在外观和用户体验上有明显的区别。

| 特性 | `.fullScreenCover` | `.sheet` |
| :--- | :--- | :--- |
| **外观** | **完全覆盖**整个屏幕。 | 在 iOS 上，默认表现为一个从底部弹出的**卡片式**视图，背景内容仍然部分可见（并带有模糊效果）。 |
| **交互** | 用户**不能**通过向下滑动手势来关闭它。必须通过一个明确的按钮（如“完成”或“关闭”）来关闭。 | 用户可以**通过向下滑动手势**来关闭它（除非被禁用）。 |
| **用途** | 用于需要用户**完全沉浸**、不被干扰的任务。例如：
*   照片或视频编辑器
*   游戏界面
*   应用的引导流程 (Onboarding)
*   创建一个新项目（如新邮件、新文档） | 用于呈现与当前上下文相关的、**补充性**的任务或信息。例如：
*   显示一个设置表单
*   从列表中选择一个项目
*   显示一个分享界面 |

**选择建议**：
*   如果任务是短暂的、补充性的，并且你希望用户可以轻松地返回到上一个界面，使用 **`.sheet`**。
*   如果任务是独立的、沉浸式的，需要用户集中全部注意力，并且需要一个明确的完成或取消操作来退出，使用 **`.fullScreenCover`**。

## 总结

`.fullScreenCover()` 是 SwiftUI 中用于呈现全屏模态视图的标准工具。

*   **核心用法**: 通过 `isPresented` (布尔值绑定) 或 `item` (可选的 `Identifiable` 对象绑定) 来触发。
*   **关闭方式**: 必须提供一个明确的关闭按钮。在被呈现的视图中，调用 `@Environment(\.dismiss)` 是最现代、最推荐的关闭方式。
*   **与 `.sheet` 的区别**: `.fullScreenCover` 是完全沉浸式的，不可通过手势关闭；而 `.sheet` 是卡片式的，可以通过手势关闭。

通过在合适的场景下使用 `.fullScreenCover`，你可以创建出能够让用户完全聚焦于当前任务的、无干扰的交互体验。
