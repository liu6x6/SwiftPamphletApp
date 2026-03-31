# SwiftUI 中的视觉效果 (Visual Effects)

SwiftUI 提供了一系列强大的修饰符，用于向视图添加各种视觉效果。这些效果可以极大地丰富你的用户界面，从简单的阴影、圆角，到复杂的模糊、饱和度调整和混合模式，让你能够以声明式的方式轻松实现精美的设计。

本篇将概览 SwiftUI 中最常用的一些视觉效果修饰符。

## 1. 阴影 (`.shadow()`)

`.shadow()` 修饰符用于为视图添加一个投影。你可以控制阴影的颜色、半径（模糊程度）、以及 x 和 y 方向的偏移量。

```swift
import SwiftUI

struct ShadowEffectExample: View {
    var body: some View {
        Text("Hello, Shadow!")
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    ShadowEffectExample()
        .padding()
        .background(Color.gray.opacity(0.2))
}
```

*   `color`: 阴影的颜色。
*   `radius`: 阴影的模糊半径，值越大，阴影越柔和、越分散。
*   `x`, `y`: 阴影相对于视图的水平和垂直偏移量。

## 2. 圆角 (`.cornerRadius()` & `.clipShape()`)

为视图添加圆角是 UI 设计中最常见的需求之一。

*   `.cornerRadius(_:)`: 一个简单的修饰符，用于将视图裁剪成圆角矩形。需要注意修饰符的应用顺序。
*   `.clipShape(_:)`: 一个更通用的修饰符，允许你使用任何 `Shape`（如 `RoundedRectangle`, `Circle`, `Capsule`）来裁剪视图。

```swift
Image("landscape")
    .resizable()
    .scaledToFill()
    .frame(width: 150, height: 150)
    .clipShape(Circle()) // 裁剪成圆形
```

（更多详情请参阅 `修饰符-圆角(ap).md`）

## 3. 模糊 (`.blur()`)

`.blur()` 修饰符可以对视图应用高斯模糊效果。`radius` 参数控制了模糊的强度。

```swift
struct BlurEffectExample: View {
    var body: some View {
        ZStack {
            Image("landscape").resizable().scaledToFill()
            
            Text("Blurred Background")
                .font(.largeTitle)
                .padding()
                .background(.ultraThinMaterial) // 使用材质背景
                .cornerRadius(20)
        }
        .blur(radius: 5) // 对整个 ZStack 应用模糊
        .ignoresSafeArea()
    }
}
```

## 4. 饱和度、对比度和色相旋转

SwiftUI 提供了一系列用于色彩调整的修饰符。

*   `.saturation(_:)`: 调整颜色的饱和度。0.0 为完全去色（黑白），1.0 为原始饱和度。
*   `.contrast(_:)`: 调整对比度。小于 1.0 降低对比度，大于 1.0 增加对比度。
*   `.hueRotation(_:)`: 在色轮上旋转所有颜色。它接受一个 `Angle` 值。

```swift
Image("landscape")
    .resizable()
    .scaledToFit()
    .saturation(0.1) // 几乎变为黑白
    .contrast(1.5)   // 增加对比度
```

## 5. 混合模式 (`.blendMode()`)

混合模式定义了重叠视图的颜色如何相互作用。通过 `.blendMode()`，你可以实现如正片叠底 (`.multiply`)、滤色 (`.screen`) 等多种专业级的图形效果。

```swift
ZStack {
    Image("landscape")
    Rectangle().fill(Color.blue).blendMode(.multiply)
}
```

（更多详情请参阅 `Blend Modes(ap).md`）

## 6. 蒙版 (`.mask()`)

`.mask()` 修饰符允许你使用另一个视图的不透明度来裁剪当前视图。这可以用于创建形状复杂的图片，或者图片填充的文字等效果。

```swift
LinearGradient(colors: [.red, .blue], startPoint: .top, endPoint: .bottom)
    .mask(Image(systemName: "swift").font(.system(size: 200)))
```

（更多详情请参阅 `修饰符-蒙版(ap).md`）

## 7. 几何效果 (`.visualEffect()` - iOS 17+)

这是一个非常强大的新修饰符，它允许你根据视图在特定坐标空间中的几何位置（`GeometryProxy`）来应用各种变换（如偏移、缩放、旋转）。它特别适合用于创建响应滚动的复杂动画，如视差效果。

```swift
ScrollView {
    ForEach(0..<10) { _ in
        Rectangle()
            .frame(height: 100)
            .visualEffect { content, geometryProxy in
                // 根据滚动位置创建动画
                content.offset(x: geometryProxy.frame(in: .global).minY / 10)
            }
    }
}
```

## 8. 合成组 (`.compositingGroup()`)

这个修饰符会强制 SwiftUI 将一个视图及其所有子视图先渲染到一个屏幕外的缓冲区中，形成一个单一的、扁平化的图像。然后，后续的修饰符（如 `.opacity`, `.blendMode`, `.shadow`）将应用于这个合成后的整体图像上。

这在需要对一个复杂的视图层级统一应用某个效果时非常关键。

## 总结

SwiftUI 提供了一个丰富且强大的视觉效果工具箱。通过组合使用这些声明式的修饰符，你可以轻松地为你的应用添加深度、质感和动态效果。

| 效果 | 主要修饰符 |
| :--- | :--- |
| 阴影 | `.shadow()` |
| 圆角/裁剪 | `.cornerRadius()`, `.clipShape()` |
| 模糊 | `.blur()` |
| 颜色调整 | `.saturation()`, `.contrast()`, `.hueRotation()` |
| 颜色混合 | `.blendMode()` |
| 蒙版 | `.mask()` |
| 滚动动画 | `.visualEffect()` |
| 效果分组 | `.compositingGroup()` |

熟练掌握这些视觉效果修饰符，将使你能够将任何 UI 设计稿精确地转化为精美、流畅的 SwiftUI 界面。
