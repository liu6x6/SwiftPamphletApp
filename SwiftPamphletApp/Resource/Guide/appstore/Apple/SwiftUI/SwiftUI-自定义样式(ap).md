# SwiftUI 自定义样式

在 SwiftUI 中，我们可以通过创建遵循特定样式协议的自定义类型来封装视图修饰符，从而实现视图样式的复用和统一管理。这种方式不仅能让我们的代码更加清晰、模块化，还有助于在整个应用中保持设计语言的一致性。

## 核心概念

SwiftUI 为多种视图提供了样式协议，例如 `ButtonStyle`、`ToggleStyle`、`ProgressViewStyle` 等。通过实现这些协议，我们可以精确控制对应视图的外观和交互行为。

创建一个自定义样式的基本步骤如下：

1.  **定义一个结构体**，并让它遵循相应的样式协议（例如 `ButtonStyle`）。
2.  **实现 `makeBody(configuration:)` 方法**。这是协议的核心要求，你需要在这个方法中返回一个 `some View`。
3.  **利用 `configuration` 参数**。该参数提供了视图的状态信息（例如，按钮是否被按下），让你可以根据不同状态应用不同的样式。

## 示例：自定义按钮样式

让我们通过一个例子来理解如何创建一个胶囊形状的按钮样式。

### 1. 定义样式

我们首先创建一个名为 `CapsuleButtonStyle` 的结构体，并遵循 `ButtonStyle` 协议。

```swift
import SwiftUI

struct CapsuleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut, value: configuration.isPressed)
    }
}
```

在这个例子中：
*   `configuration.label` 代表了按钮的标签内容（通常是文本或图标）。
*   我们通过 `padding`、`background`、`foregroundColor` 和 `clipShape` 等修饰符来定义按钮的基本外观。
*   `configuration.isPressed` 是一个布尔值，当按钮被按下时为 `true`。我们利用它来实现一个简单的缩放动画，提升交互的反馈感。

### 2. 应用样式

创建好自定义样式后，我们可以通过 `.buttonStyle()` 修饰符将其应用到任何 `Button` 上。

```swift
struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Button("登录") {
                // 登录逻辑
            }
            .buttonStyle(CapsuleButtonStyle())

            Button("注册") {
                // 注册逻辑
            }
            .buttonStyle(CapsuleButtonStyle())
        }
    }
}
```

### 3. 扩展 `ButtonStyle` (可选)

为了让样式的应用更加便捷和具有可读性，我们可以为 `ButtonStyle` 创建一个静态扩展。

```swift
extension ButtonStyle where Self == CapsuleButtonStyle {
    static var capsule: CapsuleButtonStyle {
        CapsuleButtonStyle()
    }
}
```

这样，我们就可以像使用系统内置样式一样，用更简洁的语法来应用自定义样式：

```swift
Button("登录") {
    // 登录逻辑
}
.buttonStyle(.capsule)
```

## 总结

通过自定义样式，我们可以将视图的外观逻辑与业务逻辑分离，极大地提高了代码的可维护性和复用性。除了 `ButtonStyle`，你还可以探索 `ToggleStyle`、`LabelStyle`、`ProgressViewStyle` 等，为你的 App 打造一套统一、美观的视觉风格。
