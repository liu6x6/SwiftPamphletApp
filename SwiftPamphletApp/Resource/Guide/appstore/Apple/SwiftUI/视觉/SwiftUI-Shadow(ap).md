# SwiftUI 中的阴影 (.shadow)

在 SwiftUI 中，`.shadow()` 修饰符是为视图添加深度和层次感的关键工具。它可以在视图下方创建一个投影，模拟光源照射的效果，从而让视图看起来像是浮在背景之上。正确地使用阴影可以极大地提升 UI 的质感和专业度。

## 基本用法

`.shadow()` 修饰符最简单的版本只需要一个 `radius` 参数，它定义了阴影的模糊半径。

```swift
import SwiftUI

struct BasicShadowExample: View {
    var body: some View {
        Circle()
            .fill(Color.blue)
            .frame(width: 100, height: 100)
            .shadow(radius: 10) // 应用一个半径为 10 的默认阴影
    }
}

#Preview {
    BasicShadowExample()
        .padding()
}
```

在这个例子中，一个半径为 10 的黑色、半透明阴影被应用到了蓝色的圆形上。

## 自定义阴影

为了更精细地控制阴影的外观，`.shadow()` 提供了一个更完整的版本，允许你指定颜色、半径和偏移量。

`shadow(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)`

*   **`color`**: 阴影的颜色。你可以通过改变颜色的不透明度来控制阴影的浓度。
*   **`radius`**: 阴影的模糊半径。值越大，阴影边缘越柔和、越分散；值越小，阴影边缘越锐利、越清晰。
*   **`x`**: 阴影在水平方向上的偏移量。正值向右偏移，负值向左偏移。
*   **`y`**: 阴影在垂直方向上的偏移量。正值向下偏移，负值向上偏移。

```swift
struct CustomShadowExample: View {
    var body: some View {
        VStack(spacing: 50) {
            // 柔和、分散的底部阴影
            Text("Soft Bottom Shadow")
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 10)
            
            // 锐利、倾斜的“长阴影”效果
            Text("Hard Angled Shadow")
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: .gray, radius: 1, x: 10, y: 10)
        }
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
    }
}

#Preview {
    CustomShadowExample()
}
```

## 阴影与透明度的关系

`.shadow()` 的一个重要行为是它会**忽略视图本身内容的透明度**，而是根据视图**不透明的轮廓**来生成阴影。

这意味着，即使你的视图内容是半透明的，它的阴影也总是实心的。

```swift
struct ShadowOpacityExample: View {
    var body: some View {
        // 即使圆形是半透明的，它的阴影也是实心的
        Circle()
            .fill(Color.red.opacity(0.5))
            .frame(width: 100, height: 100)
            .shadow(radius: 10)
    }
}
```

## 创建内阴影 (Inner Shadow)

SwiftUI 本身没有提供一个直接的“内阴影”修饰符。但是，我们可以通过巧妙地组合 `overlay` 和 `shadow` 来模拟出内阴影的效果。

其基本思路是：
1.  在原始形状的上方叠加一个稍微小一点的、相同形状的“洞”。
2.  为这个“洞”添加一个反向的阴影，这个阴影会投射到下方的原始形状上，看起来就像是内阴影。

```swift
struct InnerShadowExample: View {
    var body: some View {
        Circle()
            .fill(Color(UIColor.systemBackground))
            .frame(width: 150, height: 150)
            .overlay {
                // 在上方叠加一个反向的阴影
                Circle()
                    .stroke(Color.white, lineWidth: 4) // 增加一个描边以增强效果
                    .shadow(color: .black.opacity(0.5), radius: 4, x: 4, y: 4)
                    .clipShape(Circle()) // 将阴影裁剪到圆形内部
                    .shadow(color: .white, radius: 4, x: -4, y: -4)
                    .clipShape(Circle())
            }
    }
}

#Preview {
    InnerShadowExample()
        .padding(50)
        .background(Color(UIColor.systemBackground))
}
```

这是一个更高级的技巧，展示了如何通过组合基本效果来创建复杂的视觉表现。

## 多层阴影

你可以通过链式调用多个 `.shadow()` 修饰符来创建更复杂、更具层次感的阴影效果。例如，一个近处、清晰的阴影和一个远处、模糊的阴影组合，可以产生更逼真的深度感。

```swift
struct MultiLayerShadowExample: View {
    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 100, height: 100)
            // 第一层：一个近处、较暗的阴影
            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
            // 第二层：一个远处、更模糊的阴影
            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 20)
    }
}
```

## 总结

`.shadow()` 是一个简单但效果显著的修饰符，用于在 SwiftUI 视图中创建深度和层次。

*   **基础**: 通过 `radius` 控制模糊程度。
*   **高级**: 通过 `color`, `radius`, `x`, `y` 参数精确控制阴影的外观和方向。
*   **行为**: 阴影是基于视图的不透明轮廓生成的，不受内容透明度的影响。
*   **组合**: 可以通过叠加多个 `.shadow()` 来创建更复杂的阴影效果，或者通过与其他修饰符（如 `overlay`）组合来模拟内阴影等高级效果。

在设计 UI 时，克制地、有目的地使用阴影，可以有效地引导用户的注意力，并让你的界面看起来更加精致和立体。
