# SwiftUI 中的渐变 (Gradients)

渐变是 UI 设计中一种强大而常见的视觉元素，它通过在颜色之间创建平滑的过渡，为界面增添深度、质感和活力。SwiftUI 提供了多种类型的渐变，它们都遵循 `ShapeStyle` 协议，这意味着你可以像使用纯色一样，将它们用作视图的背景、前景、描边或蒙版。

## 1. 线性渐变 (`LinearGradient`)

线性渐变是在一条直线上混合颜色。你需要定义：

*   **`colors`** 或 **`gradient`**: 一个颜色数组，或者一个包含颜色和位置（`Gradient.Stop`）的 `Gradient` 对象。
*   **`startPoint`**: 渐变的起始点，使用 `UnitPoint` 定义（如 `.leading`, `.top`, `.bottomTrailing`）。
*   **`endPoint`**: 渐变的结束点。

```swift
import SwiftUI

struct LinearGradientExample: View {
    var body: some View {
        VStack(spacing: 20) {
            // 简单的从上到下渐变
            Rectangle()
                .fill(LinearGradient(
                    colors: [.blue, .white],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .frame(height: 100)
            
            // 对角线渐变
            Circle()
                .fill(LinearGradient(
                    colors: [.purple, .orange],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(height: 100)
        }
        .padding()
    }
}

#Preview {
    LinearGradientExample()
}
```

## 2. 径向渐变 (`RadialGradient`)

径向渐变是从一个中心点向外呈圆形或椭圆形混合颜色。

*   **`colors`** / **`gradient`**: 颜色数组或 `Gradient` 对象。
*   **`center`**: 渐变的中心点 (`UnitPoint`)。
*   **`startRadius`**: 起始圆的半径。
*   **`endRadius`**: 结束圆的半径。

```swift
struct RadialGradientExample: View {
    var body: some View {
        Rectangle()
            .fill(RadialGradient(
                colors: [.yellow, .red],
                center: .center, // 从中心开始
                startRadius: 20,  // 起始半径
                endRadius: 150  // 结束半径
            ))
            .frame(width: 300, height: 200)
    }
}

#Preview {
    RadialGradientExample()
}
```

## 3. 角度渐变 / 圆锥渐变 (`AngularGradient`)

角度渐变（也称圆锥渐变）是围绕一个中心点，按角度扫过一圈来混合颜色。

*   **`colors`** / **`gradient`**: 颜色数组或 `Gradient` 对象。
*   **`center`**: 渐变的中心点 (`UnitPoint`)。
*   **`startAngle`** (可选): 渐变的起始角度，默认为 0 度（正右方）。
*   **`endAngle`** (可选): 渐变的结束角度，默认为 360 度。

```swift
struct AngularGradientExample: View {
    var body: some View {
        // 创建一个彩虹圆环
        Circle()
            .strokeBorder(
                AngularGradient(
                    colors: [.red, .yellow, .green, .blue, .purple, .red],
                    center: .center
                ),
                lineWidth: 20
            )
            .frame(width: 200, height: 200)
    }
}

#Preview {
    AngularGradientExample()
}
```

## `Gradient` 对象与 `Gradient.Stop`

对于所有类型的渐变，你都可以使用一个 `Gradient` 对象来代替简单的颜色数组，以更精确地控制颜色在渐变中的位置。

`Gradient` 对象由一个 `Gradient.Stop` 数组初始化。每个 `Stop` 都包含：
*   **`color`**: 该点的颜色。
*   **`location`**: 该点在渐变中的位置，是一个从 0.0 (起点) 到 1.0 (终点) 的值。

```swift
struct GradientStopExample: View {
    let myGradient = Gradient(stops: [
        .init(color: .blue, location: 0.0),
        .init(color: .cyan, location: 0.3),
        .init(color: .green, location: 0.6),
        .init(color: .yellow, location: 1.0),
    ])

    var body: some View {
        Rectangle()
            .fill(LinearGradient(
                gradient: myGradient,
                startPoint: .leading,
                endPoint: .trailing
            ))
            .frame(height: 100)
    }
}

#Preview {
    GradientStopExample()
}
```

使用 `Gradient.Stop` 可以让你创建出不均匀分布的、更复杂的渐变效果。

## 作为 `ShapeStyle` 使用

因为所有渐变类型都遵循 `ShapeStyle` 协议，所以它们的应用场景非常广泛。

### 作为背景

这是最常见的用法，使用 `.background()` 修饰符。

```swift
Text("Hello")
    .padding()
    .background(LinearGradient(...))
```

### 作为前景 (填充形状或文本)

你可以直接将渐变作为 `Text` 的 `.foregroundStyle()` 或 `Shape` 的 `.fill()`/`.stroke()` 的参数。

```swift
VStack {
    // 渐变填充的文本
    Text("Gradient Text")
        .font(.system(size: 48, weight: .bold))
        .foregroundStyle(AngularGradient(...))
    
    // 渐变描边的形状
    Circle()
        .stroke(RadialGradient(...), lineWidth: 10)
}
```

### 作为蒙版内容

你也可以将渐变作为 `.mask()` 修饰符的内容，来创建有趣的视觉效果。

```swift
Image(systemName: "swift")
    .font(.system(size: 200))
    .mask(LinearGradient(...))
```

## 总结

渐变是 SwiftUI 中一个强大而灵活的视觉工具，用于创建平滑的颜色过渡。

*   **`LinearGradient`**: 沿直线混合颜色。
*   **`RadialGradient`**: 从中心点向外呈圆形混合颜色。
*   **`AngularGradient`**: 围绕中心点按角度混合颜色。
*   **`Gradient.Stop`**: 用于精确控制渐变中颜色的位置。
*   **`ShapeStyle`**: 由于渐变遵循此协议，它们可以被广泛地应用于背景、前景、描边和蒙版等多种场景。

通过组合不同的渐变类型和应用场景，你可以为你的 SwiftUI 应用增添丰富的视觉层次和动态美感。
