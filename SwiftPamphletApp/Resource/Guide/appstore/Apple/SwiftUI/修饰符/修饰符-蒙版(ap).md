# SwiftUI 修饰符：.mask() 蒙版

`.mask()` 是 SwiftUI 中一个极具创造力的修饰符，它允许你使用另一个视图来作为当前视图的“蒙版”。最终的显示效果是，原始视图只会在蒙版视图不透明的区域显示出来。

## 核心概念

蒙版的工作原理很简单：

1.  **原始视图**：你想要应用蒙版效果的视图（例如一张图片、一个渐变色等）。
2.  **蒙版视图**：一个独立的视图，它的形状和不透明度将决定原始视图的哪些部分是可见的。

*   蒙版视图**完全不透明**（如纯黑色）的区域，原始视图会**完全显示**。
*   蒙版视图**完全透明**的区域，原始视图会**完全隐藏**。
*   蒙版视图**半透明**的区域，原始视图会以相应的**半透明**效果显示。

重要的是，蒙版视图的**颜色本身不重要**，只有它的**Alpha（不透明度）通道**在起作用。

## 基本用法

最常见的用法是使用一个 `Text` 或 `Image` (尤其是 SF Symbol) 作为蒙版，来创建有趣的文本或形状效果。

### 示例：用文本作为蒙版

我们可以用一段文字来裁剪一个渐变背景，从而创建出彩虹色的文字效果。

```swift
import SwiftUI

struct TextMaskExample: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [.red, .orange, .yellow, .green, .blue, .purple]),
            startPoint: .leading,
            endPoint: .trailing
        )
        .mask(
            Text("Hello, SwiftUI!")
                .font(.system(size: 50, weight: .black))
        )
    }
}

#Preview {
    TextMaskExample()
}
```

在这个例子中：
1.  原始视图是一个从左到右的彩虹色 `LinearGradient`。
2.  蒙版视图是一个大号的、粗体的 `Text`。
3.  `.mask()` 修饰符使得渐变色只在文字笔画的区域内显示，而文字周围的区域则被隐藏，最终形成了彩虹字体的效果。

### 示例：用 SF Symbol 作为蒙版

同样地，我们也可以使用 SF Symbol 的形状来裁剪一个视图。

```swift
struct ImageMaskExample: View {
    var body: some View {
        Image("landscape") // 假设你有一张风景图片
            .resizable()
            .scaledToFill()
            .frame(width: 300, height: 300)
            .mask(
                Image(systemName: "heart.fill")
                    .resizable()
                    .scaledToFit()
            )
    }
}

#Preview {
    ImageMaskExample()
}
```

这里，风景图片 (`Image("landscape")`) 只会在心形 SF Symbol (`heart.fill`) 的形状内部显示出来，创建了一个心形的图片视图。

## 进阶用法

`.mask()` 的强大之处在于，任何 `View` 都可以作为蒙版，这意味着你可以组合多个视图来创建复杂的蒙版形状。

### 示例：创建渐隐效果

我们可以使用一个从不透明到透明的 `LinearGradient` 作为蒙版，来实现视图的渐隐效果。

```swift
struct FadeEffectExample: View {
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<15) { i in
                Text("Row number \(i)")
                    .padding()
            }
        }
        .mask(
            // 顶部的 80% 是不透明的，底部的 20% 渐变到透明
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .black, location: 0.8),
                    .init(color: .clear, location: 1.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

#Preview {
    FadeEffectExample()
}
```

在这个例子中：
1.  我们创建了一个包含多行文本的 `VStack`。
2.  蒙版是一个垂直的 `LinearGradient`。这个渐变从上到下，前 80% 的区域是完全不透明的（`.black`），后 20% 的区域则从不透明平滑过渡到完全透明（`.clear`）。
3.  结果是，列表的底部看起来像是逐渐消失或“淡出”了，这在 UI 设计中常用于暗示内容是可滚动的。

## `.mask()` vs. `.clipShape()`

虽然两者都用于改变视图的可见区域，但它们有本质的区别：

*   **`.clipShape()`**: 使用一个遵循 `Shape` 协议的**形状**来裁剪视图。它是一个布尔操作：要么在形状内（可见），要么在形状外（不可见）。它不关心 Alpha 通道。
*   **`.mask()`**: 使用另一个**视图**的不透明度来决定原始视图的可见性。它可以实现半透明和渐变效果。

简单来说，当你需要硬边缘的、基于几何形状的裁剪时，使用 `.clipShape()`。当你需要基于 Alpha 通道的、可以有平滑过渡的裁剪效果时，使用 `.mask()`。

## 总结

`.mask()` 是一个功能强大且富有表现力的工具，它为你打开了通往各种创意视觉效果的大门。通过将任何视图用作蒙版，你可以实现：

*   **图片填充的文字**
*   **不规则形状的图片**
*   **视图的渐隐和羽化效果**
*   **复杂的组合蒙版**

掌握 `.mask()` 将极大地丰富你的 SwiftUI 设计能力，让你能够构建出更具吸引力和独特性的用户界面。
