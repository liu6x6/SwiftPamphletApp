# SwiftUI 中的 Button 视图

`Button` 是 SwiftUI 中用于触发操作的核心交互组件。它将一个可视化的标签（`label`）与一个在用户点击时执行的动作（`action`）关联起来。`Button` 的设计充分体现了 SwiftUI 将功能与外观分离的理念，具有极高的灵活性和可定制性。

## 核心用法

创建一个 `Button` 需要提供两个核心部分：

1.  **`action`**: 一个在按钮被点击时执行的闭包。
2.  **`label`**: 一个描述按钮外观和内容的视图闭包。

```swift
import SwiftUI

struct BasicButtonExample: View {
    var body: some View {
        VStack(spacing: 20) {
            // 1. 创建一个带文本标签的按钮
            Button(action: {
                // 这是按钮被点击时执行的操作
                print("基本按钮被点击")
            }) {
                // 这是按钮的标签视图
                Text("点击我")
            }
            
            // 2. 使用尾随闭包语法的更简洁版本
            Button("更简洁的按钮") {
                print("简洁按钮被点击")
            }
        }
    }
}

#Preview {
    BasicButtonExample()
}
```

在第二个例子中，我们使用了尾随闭包语法，这是 SwiftUI 中更常见、更推荐的写法。

## 自定义按钮的标签

`Button` 的 `label` 不仅仅是文本，它可以是任何 `View`。这允许你创建包含图标、自定义形状和复杂布局的按钮。

```swift
struct CustomLabelButtonExample: View {
    var body: some View {
        Button {
            print("播放按钮被点击")
        } label: {
            // 使用 Label 视图作为按钮标签
            Label("播放", systemImage: "play.fill")
                .font(.largeTitle)
                .foregroundColor(.white)
                .padding()
                .background(Color.red)
                .clipShape(Circle())
        }
    }
}

#Preview {
    CustomLabelButtonExample()
}
```

在这个例子中，我们创建了一个圆形的、带有图标和文字的播放按钮。所有的样式修饰符（`.font`, `.padding`, `.background` 等）都应用于 `label` 闭包内的视图上。

## `Button` 的角色 (`role`)

从 iOS 15 开始，你可以为 `Button` 指定一个“角色”（`role`），以向系统提供关于该按钮意图的更多信息。这可以影响按钮的视觉表现，尤其是在 `List` 的滑动操作或 `confirmationDialog` 中。

*   `.destructive`: 表示一个破坏性的操作，如“删除”或“移除”。系统通常会以红色来渲染它。
*   `.cancel`: 表示一个取消操作。系统可能会以更突出的方式来展示它，例如在对话框中加粗字体。

```swift
struct ButtonRoleExample: View {
    @State private var showDialog = false

    var body: some View {
        Button("删除账户", role: .destructive) {
            showDialog = true
        }
        .confirmationDialog("确认删除", isPresented: $showDialog, titleVisibility: .visible) {
            // 在对话框中，role 的效果更明显
            Button("确认删除", role: .destructive) { }
            Button("取消", role: .cancel) { }
        }
    }
}

#Preview {
    ButtonRoleExample()
}
```

## `Button` 的样式：`.buttonStyle()`

`.buttonStyle()` 修饰符是 `Button` 最强大的特性之一。它允许你将按钮的外观和交互逻辑与按钮的功能完全分离。

### 内置样式

SwiftUI 提供了一些开箱即用的按钮样式：

*   `.automatic`: 默认样式。
*   `.plain`: 没有任何背景或边框的朴素样式。
*   `.bordered`: 带有细微灰色背景和圆角的按钮。
*   `.borderedProminent`: 带有更强背景色（使用应用的 `tint` 色）和圆角的按钮，用于主要操作。
*   `.borderless`: (macOS) 无边框样式。

```swift
struct ButtonStyleExample: View {
    var body: some View {
        VStack(spacing: 20) {
            Button("主要操作") {}.buttonStyle(.borderedProminent)
            Button("次要操作") {}.buttonStyle(.bordered)
            Button("朴素操作") {}.buttonStyle(.plain)
        }
        .tint(.purple) // .tint 会影响 .borderedProminent 的背景色
    }
}

#Preview {
    ButtonStyleExample()
}
```

### 自定义 `ButtonStyle`

你可以通过创建一个遵循 `ButtonStyle` 协议的结构体来定义自己的、可在整个应用中复用的按钮样式。这需要实现 `makeBody(configuration:)` 方法，该方法提供了一个包含 `label` 和 `isPressed` 状态的 `configuration` 对象。（详见 `Style协议(ap).md`）

## `ControlSize` (iOS 15+)

你可以使用 `.controlSize()` 修饰符来改变按钮（以及其他一些控件）的尺寸。

*   `.large`
*   `.regular`
*   `.small`
*   `.mini` (macOS)

```swift
VStack {
    Button("Large Button") {}.controlSize(.large)
    Button("Regular Button") {}.controlSize(.regular)
    Button("Small Button") {}.controlSize(.small)
}
.buttonStyle(.bordered)
```

## 总结

`Button` 是 SwiftUI 中最基础的交互元素。它的设计哲学鼓励开发者将**功能**（`action`）和**外观**（`label` 和 `style`）分离开来。

*   **核心**: 由 `action` 和 `label` 两个闭包构成。
*   **标签**: 可以是任何 `View`，提供了无限的自定义可能性。
*   **角色**: 通过 `role` 参数提供语义信息，影响系统对其的渲染方式。
*   **样式**: `.buttonStyle()` 是实现外观复用和全局样式管理的关键，是 `Button` 最强大的特性。

通过熟练掌握 `Button` 的各种配置和样式化方法，你可以构建出既符合平台规范又具有独特品牌风格的交互体验。
