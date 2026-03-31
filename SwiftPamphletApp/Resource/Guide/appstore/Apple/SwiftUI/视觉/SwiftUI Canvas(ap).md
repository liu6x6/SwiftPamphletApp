# SwiftUI 中的 Canvas 视图

`Canvas` 是 SwiftUI 中一个用于高性能、即时模式（immediate mode）绘图的视图。它为你提供了一个底层的绘图环境，让你能够使用类似于 Core Graphics 的 API 来绘制自定义的 2D 图形、文本和图像。`Canvas` 非常适合用于创建需要频繁重绘、动态变化的复杂图形，如图表、游戏界面、或自定义的绘图应用。

## 核心概念：即时模式绘图

与 SwiftUI 的声明式 `Shape` 协议不同，`Canvas` 采用的是“即时模式”绘图。这意味着：

*   **`Shape`**: 你**声明**一个形状的路径，然后 SwiftUI 负责在需要时渲染它。你描述的是“什么”，而不是“如何”。
*   **`Canvas`**: 你在一个闭包中，使用一系列**命令式**的绘图指令（如“画一条线”、“填充一个圆”）来**立即**绘制图形。你描述的是“如何”画。

`Canvas` 的性能通常比组合大量的 `Shape` 视图要高，因为它将所有的绘图操作都优化在了一个单一的视图层级中。

## 基本用法

创建一个 `Canvas` 需要提供一个 `renderer` 闭包。这个闭包接收两个参数：

1.  **`context`**: 一个 `GraphicsContext` 对象。这是你的“画笔”，包含了所有绘图操作的方法。
2.  **`size`**: 一个 `CGSize` 对象，表示当前 `Canvas` 的可用绘图区域大小。

```swift
import SwiftUI

struct BasicCanvasExample: View {
    var body: some View {
        Canvas { context, size in
            // 在这里使用 context 进行绘图
            
            // 绘制一个红色的圆形
            let circlePath = Path(ellipseIn: CGRect(origin: .zero, size: size))
            context.fill(circlePath, with: .color(.red))
            
            // 绘制一段居中的文本
            context.draw(Text("Hello, Canvas!").font(.largeTitle), at: CGPoint(x: size.width / 2, y: size.height / 2))
            
            // 绘制一张图片
            if let swiftImage = context.resolveSymbol(id: 1) {
                context.draw(swiftImage, in: CGRect(x: 0, y: 0, width: 64, height: 64))
            }
        }
        // 为 Canvas 提供一个初始框架
        .frame(width: 300, height: 200)
        .border(Color.blue)
        // 使用 symbols 闭包来预加载图片，以提高性能
        .symbols {
            Image(systemName: "swift").tag(1)
        }
    }
}

#Preview {
    BasicCanvasExample()
}
```

在这个例子中：
*   我们使用 `context.fill` 来填充一个路径。
*   我们使用 `context.draw` 来绘制 `Text` 和 `Image`。
*   `.symbols` 修饰符是一个性能优化技巧。它允许 `Canvas` 预先解析和缓存 `Image` 视图，然后在 `renderer` 闭包中通过 `context.resolveSymbol(id:)` 来高效地引用它们。

## `GraphicsContext` 绘图上下文

`GraphicsContext` 是你在 `Canvas` 中进行所有绘图操作的接口。它提供了丰富的 API：

### 绘制路径

*   `fill(_:with:)`: 使用指定的着色器（`Shading`）填充一个路径。
*   `stroke(_:with:lineWidth:)`: 使用指定的着色器和线宽来描边一个路径。

```swift
let path = Path(roundedRect: rect, cornerRadius: 10)
context.fill(path, with: .color(.blue))
context.stroke(path, with: .color(.black), lineWidth: 2)
```

### 绘制 `Text` 和 `Image`

*   `draw(_:at:anchor:)`: 在指定点绘制文本。
*   `draw(_:in:)`: 在指定的矩形区域内绘制图像。

### 变换 (Transforms)

你可以对 `GraphicsContext` 应用变换，这些变换会影响后续的所有绘图操作。

*   `translateBy(x:y:)`: 移动坐标系的原点。
*   `rotate(by:)`: 旋转坐标系。
*   `scaleBy(x:y:)`: 缩放坐标系。

```swift
context.translateBy(x: size.width / 2, y: size.height / 2)
for i in 0..<12 {
    context.rotate(by: .degrees(30))
    // 绘制时钟的刻度线
}
```

### 滤镜和效果

`GraphicsContext` 也支持应用滤镜，如模糊、颜色混合等。

*   `addFilter(_:)`: 添加一个滤镜，如 `.blur()`。
*   `beginTransparencyLayer()` / `endTransparencyLayer()`: 创建一个透明度图层，可以让你将一组绘图操作作为一个整体来应用效果。

## 动画化的 `Canvas`

要让 `Canvas` 动起来，你需要将它与能够驱动视图重绘的机制结合起来，例如 `TimelineView` 或一个变化的 `@State` 属性。

```swift
struct AnimatedCanvasExample: View {
    let startDate = Date()

    var body: some View {
        TimelineView(.animation) { timelineContext in
            let time = timelineContext.date.timeIntervalSince1970 - startDate.timeIntervalSince1970
            
            Canvas { context, size in
                let angle = Angle.degrees(time * 60)
                let radius = min(size.width, size.height) / 4
                
                let x = size.width / 2 + radius * cos(angle.radians)
                let y = size.height / 2 + radius * sin(angle.radians)
                
                context.fill(Path(ellipseIn: CGRect(x: x - 10, y: y - 10, width: 20, height: 20)), with: .color(.red))
            }
        }
        .frame(width: 200, height: 200)
        .border(Color.gray)
    }
}
```

在这个例子中，`TimelineView` 会以屏幕刷新率不断地重绘 `Canvas`。在每次重绘时，我们都根据当前时间计算出一个新的角度，并绘制一个在圆周上移动的小圆，从而创建出动画效果。

## `Canvas` vs. `Shape`

| 特性 | `Canvas` | `Shape` |
| :--- | :--- | :--- |
| **编程范式** | 命令式 (Immediate Mode) | 声明式 (Declarative) |
| **性能** | **高**。所有绘图在一个视图中完成，开销小。 | **中等**。每个 `Shape` 都是一个独立的视图，组合过多会增加视图层级开销。 |
| **易用性** | 较低。需要手动管理绘图状态和坐标。 | **高**。与 SwiftUI 的声明式语法完美融合。 |
| **布局** | 不参与 SwiftUI 布局。你只能在给定的 `size` 内绘制。 | 完全参与 SwiftUI 布局，可以影响其他视图的位置。 |
| **动画** | 需要手动驱动重绘。 | 自动获得 `Animatable` 特性，与 `withAnimation` 无缝集成。 |

**选择建议**：
*   对于静态的、可复用的、需要参与布局的自定义图形，优先使用 **`Shape`**。
*   对于需要频繁重绘的、动态的、性能敏感的复杂图形（如图表、游戏、实时数据可视化），或者需要使用底层绘图 API 进行精细控制的场景，**`Canvas`** 是更好的选择。

## 总结

`Canvas` 为 SwiftUI 开发者打开了一扇通往底层、高性能 2D 绘图世界的大门。它提供了一个命令式的 `GraphicsContext`，让你能够精确地控制每一个绘图操作。

虽然它的使用方式与 SwiftUI 主流的声明式范式有所不同，但在处理动态图形和性能敏感的绘图任务时，`Canvas` 是一个不可或缺的强大工具。通过与 `TimelineView` 等机制结合，你可以用它来创造出令人惊叹的实时动画和数据可视化效果。
