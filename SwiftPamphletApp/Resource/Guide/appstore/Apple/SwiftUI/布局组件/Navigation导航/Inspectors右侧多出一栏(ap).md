# SwiftUI 导航：检查器 (Inspector)

在 macOS 和 iPadOS 应用中，一种常见的 UI 模式是在主内容区域的右侧提供一个“检查器”（Inspector）面板，用于显示和编辑当前选中项目的详细信息。例如，在“访达”中，你可以按 `Cmd+I` 来显示文件或文件夹的详细信息面板；在“快捷指令”或“无边记”中，右侧的检查器面板用于调整选中项目的各种属性。

从 iOS 16 和 macOS 13 开始，SwiftUI 通过 `.inspector()` 修饰符，为实现这种布局模式提供了官方的、标准化的支持。

## 核心用法：`.inspector()`

`.inspector()` 修饰符需要与 `NavigationSplitView` 或 `NavigationStack` 结合使用。你将这个修饰符附加到主内容视图上，并提供两个部分：

1.  **`isPresented`**: 一个 `Binding<Bool>`，用于控制检查器面板当前是否可见。
2.  **`content`**: 一个视图闭包，其中包含了检查器面板本身要显示的内容。

```swift
import SwiftUI

struct InspectorExample: View {
    @State private var selectedItem: String? = "Apple"
    @State private var showInspector = false

    let items = ["Apple", "Banana", "Cherry"]

    var body: some View {
        NavigationSplitView {
            // 侧边栏
            List(items, id: \.self, selection: $selectedItem) { item in
                Text(item)
            }
        } detail: {
            // 主内容区域
            VStack {
                Text("选中的项目: \(selectedItem ?? "无")")
                    .font(.largeTitle)
            }
            .navigationTitle("主内容")
            .toolbar {
                // 用于控制检查器显示的按钮
                ToolbarItem {
                    Button {
                        showInspector.toggle()
                    } label: {
                        Label("显示检查器", systemImage: "sidebar.right")
                    }
                }
            }
            // 1. 附加 .inspector 修饰符
            .inspector(isPresented: $showInspector) {
                // 2. 定义检查器的内容
                InspectorView(item: selectedItem)
            }
        }
    }
}

// 检查器视图
struct InspectorView: View {
    let item: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("检查器")
                .font(.largeTitle)
            
            if let item = item {
                Text("项目详情: \(item)")
                Text("创建日期: \(Date().formatted())")
                Button("执行操作") {}
            } else {
                Text("未选择任何项目")
            }
            Spacer()
        }
        .padding()
    }
}

#Preview {
    InspectorExample()
}
```

在这个例子中：
1.  我们在 `NavigationSplitView` 的 `detail` 视图上附加了 `.inspector()` 修饰符。
2.  `isPresented` 参数绑定到了 `@State private var showInspector`，这意味着我们可以通过改变这个布尔值来控制检查器的显示和隐藏。
3.  工具栏上的按钮通过 `showInspector.toggle()` 来切换检查器的可见性。
4.  `content` 闭包中包含了 `InspectorView`，它会根据当前选中的 `selectedItem` 来显示不同的详细信息。

## 平台行为

`.inspector()` 的行为在不同平台和设备尺寸上是自适应的：

*   **macOS 和 iPadOS (大尺寸)**: 检查器会以一个标准的、可调整大小的侧边栏形式，出现在主内容区域的**右侧**（对于从右到左的语言，则在左侧）。
*   **iOS (紧凑尺寸)**: 在 iPhone 等紧凑设备上，检查器会以一个从底部弹出的 **Sheet** 模态视图的形式呈现。

这种自适应行为是完全自动的，你无需编写任何额外的代码来处理不同平台的 UI 差异。这正是 SwiftUI 跨平台能力的体现。

## 与 `.navigationSplitViewStyle()` 的关系

检查器的行为也受到 `NavigationSplitView` 样式的影响。例如，如果你将样式设置为 `.prominentDetail`，主内容区域会占据更多空间，检查器可能会以浮层（Overlay）的形式出现。

## 总结

`.inspector()` 修饰符为在 iPadOS 和 macOS 应用中实现标准的“检查器”布局提供了一个极其简单、强大且具有平台一致性的解决方案。

*   **标准化**: 它将一种常见的桌面级应用布局模式，以标准 API 的形式引入了 SwiftUI。
*   **自适应**: 它会自动处理在不同平台和尺寸类别下的呈现方式（侧边栏 vs. Sheet），无需手动判断设备类型。
*   **声明式**: 你只需要声明检查器是否显示以及其内容是什么，而无需关心具体的布局和动画细节。

当你正在构建一个需要在 Mac 或 iPad 上提供丰富内容编辑和信息展示功能的应用时，`.inspector()` 是一个能够显著提升你的应用专业度和用户体验的强大工具。它与 `NavigationSplitView` 和 `Toolbar` 结合使用，可以轻松构建出功能完善的、桌面级的应用程序界面。
