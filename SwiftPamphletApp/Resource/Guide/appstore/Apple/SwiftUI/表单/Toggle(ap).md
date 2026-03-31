# SwiftUI 中的 Toggle 开关

`Toggle` 是 SwiftUI 中一个用于表示两种互斥状态（开/关、真/假、是/否）的控件。它通常表现为一个开关按钮，用户可以通过点击来切换其状态。`Toggle` 是构建设置页面、表单和任何需要布尔值输入的界面的基本组件。

## 核心用法：绑定布尔值

`Toggle` 的核心是通过双向绑定 (`Binding`) 连接到一个布尔（`Bool`）类型的 `@State` 变量。

1.  **`isOn`**: 一个到布尔值状态变量的双向绑定。当开关状态改变时，这个变量的值会同步更新。
2.  **`label`**: 一个描述 `Toggle` 用途的视图，通常是 `Text` 或 `Label`。

```swift
import SwiftUI

struct BasicToggleExample: View {
    // 1. 状态变量存储开关的状态
    @State private var showAdvancedSettings: Bool = false

    var body: some View {
        VStack {
            // 2. 创建 Toggle
            Toggle(isOn: $showAdvancedSettings) {
                Text("显示高级设置")
            }
            .padding()
            
            // 3. 根据状态显示或隐藏内容
            if showAdvancedSettings {
                Form {
                    Text("高级设置项 1")
                    Text("高级设置项 2")
                }
            }
        }
    }
}

#Preview {
    BasicToggleExample()
}
```

在这个例子中：
*   `showAdvancedSettings` 状态变量决定了高级设置是否可见。
*   `Toggle` 通过 `$showAdvancedSettings` 与该状态双向绑定。当用户点击开关时，`showAdvancedSettings` 的值会在 `true` 和 `false` 之间切换。
*   `if showAdvancedSettings` 条件语句会根据 `Toggle` 的状态，动态地在界面上添加或移除 `Form` 视图。

## 自定义 `Toggle` 的样式

与 `Button` 和 `Label` 类似，`Toggle` 也支持通过 `.toggleStyle()` 修饰符来改变其外观。SwiftUI 提供了一些内置的样式，并且允许你创建自定义样式。

### 内置样式

*   `.automatic`: 默认样式，由上下文决定。
*   `.switch`: 经典的开关滑块样式（在 iOS 上是默认样式）。
*   `.button`: 表现为一个可点击的按钮，选中时有明显的高亮或背景变化。
*   `.checkbox` (macOS): 在 macOS 上表现为一个复选框。

```swift
struct ToggleStyleExample: View {
    @State private var isSubscribed: Bool = true

    var body: some View {
        VStack(spacing: 30) {
            Toggle("订阅邮件", isOn: $isSubscribed)
                .toggleStyle(.switch) // 开关样式
            
            Toggle("订阅邮件", isOn: $isSubscribed)
                .toggleStyle(.button) // 按钮样式
        }
        .padding()
    }
}

#Preview {
    ToggleStyleExample()
}
```

`.button` 样式在需要将开关无缝集成到一排按钮中时非常有用。

### 自定义 `ToggleStyle`

如果你需要完全自定义 `Toggle` 的外观和交互，你可以创建一个遵循 `ToggleStyle` 协议的结构体。

你需要实现 `makeBody(configuration:)` 方法，该方法提供了一个 `configuration` 对象，其中包含：

*   `configuration.isOn`: 一个布尔值，表示当前开关是否处于“开”的状态。
*   `configuration.label`: 描述开关用途的标签视图。
*   `configuration.$isOn`: 一个到原始布尔值的**绑定**。你可以通过改变这个绑定的值来切换开关的状态。

#### 示例：创建一个胶囊开关样式

```swift
struct CapsuleToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            // 显示标签
            configuration.label
            
            Spacer()
            
            // 自定义开关外观
            ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                Capsule()
                    .frame(width: 50, height: 30)
                    .foregroundColor(configuration.isOn ? .green : .gray)
                
                Circle()
                    .frame(width: 26, height: 26)
                    .foregroundColor(.white)
                    .padding(2)
            }
            .onTapGesture {
                // 通过点击来切换状态
                withAnimation {
                    configuration.isOn.toggle()
                }
            }
        }
    }
}

struct CustomToggleStyleExample: View {
    @State private var isEnabled = false
    
    var body: some View {
        Toggle("启用飞行模式", isOn: $isEnabled)
            .toggleStyle(CapsuleToggleStyle())
            .padding()
    }
}

#Preview {
    CustomToggleStyleExample()
}
```

在这个例子中：
1.  我们创建了 `CapsuleToggleStyle`。
2.  在 `makeBody` 中，我们使用 `ZStack` 和 `Capsule`/`Circle` 形状来构建一个自定义的开关滑块。
3.  开关的颜色和滑块的位置都取决于 `configuration.isOn`。
4.  最关键的是 `onTapGesture` 中的 `configuration.isOn.toggle()`。我们通过直接操作 `configuration` 提供的绑定来改变开关的实际状态，从而触发 UI 更新。

## 改变 `Toggle` 的颜色

对于标准的 `.switch` 样式，你可以使用 `.tint()` 修饰符来改变其“开”状态下的背景颜色。

```swift
Toggle("接收通知", isOn: $isNotifying)
    .tint(.purple) // 当开关打开时，背景将是紫色而不是默认的绿色
```

## 总结

`Toggle` 是 SwiftUI 中用于处理布尔状态输入的标准控件。

*   **核心**: 通过与 `@State` 布尔变量的双向绑定来工作。
*   **样式**: 使用 `.toggleStyle()` 可以轻松切换为开关、按钮等不同外观。
*   **自定义**: 通过创建自定义的 `ToggleStyle`，可以实现任何你想要的外观和交互，具有极高的灵活性。
*   **颜色**: 使用 `.tint()` 可以快速改变标准开关样式的主题色。

在任何需要用户做出“是/否”选择的场景下，`Toggle` 都是一个必不可少的工具。
