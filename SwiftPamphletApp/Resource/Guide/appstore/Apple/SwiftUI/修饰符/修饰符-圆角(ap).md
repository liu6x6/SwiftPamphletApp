# SwiftUI 中的圆角处理

在 SwiftUI 中，为视图添加圆角是界面设计中非常常见的需求。SwiftUI 提供了多种灵活的方式来实现圆角效果，从简单的修饰符到复杂的形状裁剪，可以满足不同的设计要求。

## 1. `.cornerRadius()` 修饰符

这是实现圆角最直接、最简单的方式。`.cornerRadius()` 修饰符可以应用于任何视图，它会将视图的矩形边界裁剪成指定的圆角半径。

```swift
import SwiftUI

struct CornerRadiusExample: View {
    var body: some View {
        Text("Hello, Rounded World!")
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(15)
    }
}

#Preview {
    CornerRadiusExample()
}
```

**需要注意的重要细节**：修饰符的顺序至关重要。

`.cornerRadius()` 只会影响它**之前**的视图层级。在上面的例子中，它裁剪了 `background`，但如果你改变顺序，结果会大不相同：

```swift
struct CornerRadiusOrderExample: View {
    var body: some View {
        Text("Incorrect Order")
            .padding()
            .cornerRadius(15) // 先对 Text 应用圆角（虽然看不出效果）
            .background(Color.red) // 然后添加一个矩形的背景
            .foregroundColor(.white)
    }
}
```

在这个错误的例子中，背景是最后添加的，它并不知道前面有圆角裁剪，所以它会保持自己的矩形形状，导致圆角效果丢失。

**正确的做法**是始终在设置背景和边框**之后**再调用 `.cornerRadius()`。

## 2. `.clipShape()` 修饰符

`.clipShape()` 是一个更通用、更强大的裁剪工具。它允许你使用任何遵循 `Shape` 协议的类型来裁剪视图。对于圆角，我们最常使用 `RoundedRectangle`。

```swift
struct ClipShapeExample: View {
    var body: some View {
        Text("Clipped with Shape")
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

#Preview {
    ClipShapeExample()
}
```

### `.cornerRadius()` vs. `.clipShape(RoundedRectangle(...))`

虽然两者都能实现圆角，但 `.clipShape()` 提供了更多的控制：

*   **边框（Stroke）**: 如果你想在添加圆角的同时添加一个边框，使用 `RoundedRectangle` 作为 `.overlay()` 或 `.background()` 的一部分会更自然。
*   **形状样式**: `RoundedRectangle` 允许你指定 `style`，如 `.circular`（标准圆角）或 `.continuous`（平滑圆角，与苹果硬件和系统UI风格更一致）。`.cornerRadius()` 默认使用的是 `.circular`。
*   **更复杂的形状**: `.clipShape()` 不仅限于圆角矩形，你还可以使用 `Capsule()`（胶囊形状）、`Circle()`（圆形）、`Ellipse()`（椭圆形）或自定义的 `Shape`。

### 示例：带边框的圆角

实现带边框的圆角，最佳实践是使用两个 `RoundedRectangle`，一个用于填充背景，一个用于描边。

```swift
struct RoundedBorderExample: View {
    var body: some View {
        Text("Rounded Border")
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.purple.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.purple, lineWidth: 2)
            )
    }
}

#Preview {
    RoundedBorderExample()
}
```

在这个例子中，我们没有使用 `.clipShape()`，而是通过 `.background()` 和 `.overlay()` 巧妙地构建了效果。这样做的好处是，文本内容本身没有被裁剪，只是被放置在了具有圆角背景和边框的“容器”中。

## 3. 特定角的圆角

在某些设计中，你可能只想为视图的某几个角设置圆角。SwiftUI 本身没有直接提供一个修饰符来做这件事，但我们可以通过创建一个自定义的 `Shape` 来轻松实现。

```swift
// 一个可以指定任意角的圆角矩形 Shape
struct SelectiveRoundedRectangle: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct SelectiveCornersExample: View {
    var body: some View {
        Text("Top Corners Rounded")
            .padding()
            .background(Color.orange)
            .clipShape(SelectiveRoundedRectangle(radius: 25, corners: [.topLeft, .topRight]))
    }
}

#Preview {
    SelectiveCornersExample()
}
```

在这个例子中：
1.  我们定义了一个 `SelectiveRoundedRectangle` 结构体，它遵循 `Shape` 协议。
2.  它的 `path(in:)` 方法使用了 `UIBezierPath` 来创建一个只在指定角（通过 `corners` 参数）有圆角的路径。
3.  然后，我们就可以像使用系统内置形状一样，在 `.clipShape()` 中使用它，从而实现了只对顶部两个角进行圆角处理的效果。

## 总结

| 方法 | 优点 | 缺点 | 最佳用途 |
| :--- | :--- | :--- | :--- |
| `.cornerRadius()` | 简单、直接。 | 功能有限，对修饰符顺序敏感。 | 快速实现简单的四角圆角效果。 |
| `.clipShape()` | 灵活、强大，可使用任何形状。 | 比 `.cornerRadius()` 稍显啰嗦。 | 实现平滑圆角、胶囊/圆形裁剪，或与自定义形状结合。 |
| `background/overlay` with `Shape` | 控制力最强，轻松实现带边框的圆角。 | 需要同时使用 `.background` 和/或 `.overlay`。 | 创建带填充背景和描边边框的圆角视图。 |

掌握这些不同的圆角处理技巧，将使你能够更精确地实现各种复杂的 UI 设计，并写出更清晰、更具可维护性的 SwiftUI 代码。
