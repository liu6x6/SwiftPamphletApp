# SwiftUI 布局组件：ControlGroup

`ControlGroup` 是 SwiftUI 中一个用于将一组逻辑上相关的控件（如 `Button`, `Toggle`, `Menu`）组合在一起的容器视图。它会根据平台和上下文，自动为这组控件应用一个紧凑的、语义化的分组样式。

`ControlGroup` 特别适合用于创建工具栏、检查器面板或任何需要将多个小操作紧密排列在一起的场景。

## 核心用法

你只需要将一系列控件放置在 `ControlGroup` 的闭包内部即可。`ControlGroup` 会负责处理它们的布局和样式。

```swift
import SwiftUI

struct BasicControlGroupExample: View {
    var body: some View {
        VStack(spacing: 30) {
            // 默认样式的 ControlGroup
            ControlGroup {
                Button { } label: { Image(systemName: "bold") }
                Button { } label: { Image(systemName: "italic") }
                Button { } label: { Image(systemName: "underline") }
            }
            
            // 在 macOS 上，ControlGroup 的效果更明显
            ControlGroup {
                Button("上一封") { }
                Button("下一封") { }
            }
        }
        .padding()
    }
}

#Preview {
    BasicControlGroupExample()
}
```

在这个例子中，`ControlGroup` 会将内部的按钮紧密地排列在一起，并根据平台规范添加合适的分隔线或背景，使其看起来像一个统一的控件单元。

## `ControlGroup` 的样式

你可以通过 `.controlGroupStyle()` 修饰符来改变 `ControlGroup` 的外观。SwiftUI 提供了一些内置的样式：

*   **`.automatic`**: 默认样式。在 iOS 上，它通常表现为一种紧凑的水平排列；在 macOS 上，它会根据上下文选择最合适的样式。
*   **`.navigation`**: 导航样式。在 iOS 16+ 和 macOS 上，当放置在 `Toolbar` 中时，这种样式会使控件组在空间不足时自动折叠成一个弹出菜单。这对于创建响应式的工具栏非常有用。

### 示例：导航样式 (`.navigation`)

```swift
struct NavigationControlGroupExample: View {
    var body: some View {
        NavigationView {
            Text("可折叠的工具栏")
                .navigationTitle("ControlGroup")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        ControlGroup {
                            Button("编辑", systemImage: "pencil") { }
                            Button("分享", systemImage: "square.and.arrow.up") { }
                            Menu {
                                Button("选项 A") {}
                                Button("选项 B") {}
                            } label: {
                                Label("更多", systemImage: "ellipsis.circle")
                            }
                        }
                        // 应用导航样式
                        .controlGroupStyle(.navigation)
                    }
                }
        }
    }
}

#Preview {
    NavigationControlGroupExample()
}
```

在这个例子中：
*   我们将一个 `ControlGroup` 放置在导航栏的 `Toolbar` 中。
*   通过应用 `.controlGroupStyle(.navigation)`，我们告诉 SwiftUI 这个控件组应该具有响应式行为。
*   在较宽的屏幕（如 iPad 或 Mac）上，所有按钮和菜单都会水平展开显示。
*   在较窄的屏幕（如 iPhone）上，如果空间不足，SwiftUI 会自动将这个控件组折叠成一个单一的“更多”按钮（通常是 `...` 图标），点击后会弹出一个包含所有原始控件的菜单。这种行为是完全自动的，极大地简化了响应式布局的实现。

## `ControlGroup` vs. `HStack`

你可能会问，为什么不直接用 `HStack` 来排列这些控件呢？

| 特性 | `ControlGroup` | `HStack` |
| :--- | :--- | :--- |
| **语义** | **语义化**。明确表示这是一组逻辑相关的“控件”。 | **通用化**。只表示一组视图的水平排列，没有特定语义。 |
| **样式** | **平台特定**。会自动应用符合系统规范的分组样式（如分隔线、圆角）。 | **无样式**。只负责布局，你需要手动添加所有样式。 |
| **响应式** | **支持**。通过 `.navigation` 样式，可以实现自动折叠。 | **不支持**。你需要手动编写逻辑来处理不同屏幕尺寸下的布局变化。 |
| **适用场景** | 专门用于组合**功能性控件**，如 `Button`, `Menu`。 | 用于任何通用的水平布局场景。 |

**选择建议**：
*   当你需要将一组**操作按钮或功能控件**组合在一起，并希望它们看起来像一个统一的整体时，应**优先使用 `ControlGroup`**。
*   当你只是需要将任意几个视图（可能包含非控件视图，如 `Text`, `Image`）水平排列时，使用 `HStack`。

## 总结

`ControlGroup` 是一个专门用于对功能性控件进行分组和布局的语义化容器。

*   **核心作用**: 将一组相关的控件组合成一个视觉上和功能上统一的单元。
*   **自动样式**: 它会自动应用符合平台设计规范的样式，减少了手动布局和样式设置的工作量。
*   **响应式布局**: 通过 `.controlGroupStyle(.navigation)`，可以轻松实现工具栏在不同屏幕尺寸下的自动折叠，是构建自适应 UI 的利器。

在设计应用的工具栏、检查器或任何包含多个紧密相关操作的区域时，使用 `ControlGroup` 不仅能让你的代码更简洁、更具语义，还能让你的应用在不同平台和设备上都表现得更加原生和专业。
