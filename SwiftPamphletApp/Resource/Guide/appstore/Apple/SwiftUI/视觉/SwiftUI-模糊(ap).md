# SwiftUI 中的模糊效果

在 SwiftUI 中，为视图添加模糊效果是一种常见的视觉设计技巧，它可以用于创建深度感、突出显示前景内容，或者实现像 iOS 控制中心那样的“毛玻璃”背景。SwiftUI 提供了两种主要的方式来实现模糊效果：`.blur()` 修饰符和背景材质（Materials）。

## 1. `.blur()` 修饰符

`.blur()` 修饰符可以对任何视图应用一个标准的高斯模糊滤镜。它非常直接和易于使用。

核心参数：
*   **`radius`**: 一个 `CGFloat` 值，定义了模糊的半径。值越大，模糊效果越强烈、越分散。
*   **`opaque`**: 一个布尔值，默认为 `false`。如果设置为 `true`，SwiftUI 会将视图渲染到一个不透明的缓冲区中再进行模糊，这可以提升性能，但可能会影响边缘的渲染效果。

```swift
import SwiftUI

struct BlurModifierExample: View {
    @State private var blurRadius: CGFloat = 0

    var body: some View {
        VStack {
            ZStack {
                Image("landscape")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 300)
                
                Text("Hello, SwiftUI!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .blur(radius: blurRadius) // 应用模糊效果
            .clipped()
            
            Slider(value: $blurRadius, in: 0...20)
                .padding()
        }
    }
}

#Preview {
    BlurModifierExample()
}
```

在这个例子中，我们对一个包含图片和文字的 `ZStack` 应用了 `.blur()` 修饰符。通过拖动 `Slider`，你可以实时地看到模糊半径变化带来的效果。

**注意**: `.blur()` 会影响视图的**所有内容**，包括其子视图。如果你只想模糊背景，而保持前景内容清晰，你需要将背景和前景分离开来。

### 示例：只模糊背景

```swift
struct BlurredBackgroundExample: View {
    var body: some View {
        ZStack {
            // 背景图片，被模糊
            Image("landscape")
                .resizable()
                .scaledToFill()
                .blur(radius: 10)
            
            // 前景内容，保持清晰
            VStack {
                Image(systemName: "swift")
                    .font(.system(size: 100))
                Text("SwiftUI")
                    .font(.largeTitle)
            }
            .foregroundColor(.white)
            .shadow(radius: 10)
        }
        .ignoresSafeArea()
    }
}
```

## 2. 背景材质 (Materials)

从 iOS 15 开始，SwiftUI 引入了一个更强大、更具平台一致性的模糊背景实现方式：**材质 (Materials)**。材质不仅是简单的模糊，它是一种动态的、半透明的背景，能够微妙地透出其后方的内容，并自动适应深色和浅色模式。

这正是你在 iOS 系统界面（如控制中心、通知中心、底部标签栏）中看到的“毛玻璃”效果。

你可以通过 `.background()` 修饰符来应用材质。

```swift
struct MaterialExample: View {
    var body: some View {
        ZStack {
            Image("landscape")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack {
                Text("Hello, Materials!")
                    .font(.largeTitle)
            }
            .frame(width: 300, height: 200)
            // 应用背景材质
            .background(.regularMaterial) // 使用常规厚度的材质
            .cornerRadius(20)
        }
    }
}

#Preview {
    MaterialExample()
}
```

### 可用的材质类型

SwiftUI 提供了几种不同厚度和亮度的材质，它们都封装在 `Material` 类型中：

*   **`.ultraThinMaterial`**: 最薄、最透明的材质。
*   **`.thinMaterial`**: 薄材质。
*   **`.regularMaterial`**: 常规厚度，这是最常用的材质。
*   **`.thickMaterial`**: 厚材质。
*   **`.ultraThickMaterial`**: 最厚、最不透明的材质。

你可以根据设计需求，选择合适的材质来平衡背景内容的可见性和前景内容的可读性。

## `.blur()` vs. 背景材质

| 特性 | `.blur()` | 背景材质 (`.background(.material)`) |
| :--- | :--- | :--- |
| **效果** | 纯粹的高斯模糊。 | 动态的、半透明的“毛玻璃”效果。 |
| **平台一致性** | 较低。只是一个通用的滤镜。 | **高**。与 iOS、macOS 系统 UI 风格完全一致。 |
| **性能** | 较高。实时计算模糊可能消耗较多资源。 | **极高**。由系统底层渲染引擎（Render Server）高效处理。 |
| **适应性** | 不会自动适应深色/浅色模式。 | **自动适应**深色/浅色模式，调整亮度和饱和度。 |
| **用途** | 用于对**任何视图**（包括图片、文本）应用模糊滤镜。 | 专门用作**背景**。 |

**选择建议**：
*   当你需要创建一个**模糊背景**，并希望它具有平台原生的“毛玻璃”质感时，**应始终优先使用背景材质**。
*   当你需要对一个**非背景**的视图（例如，一张图片本身）应用模糊效果，或者需要一个与平台风格无关的、纯粹的数学模糊滤镜时，才使用 `.blur()`。

## 总结

SwiftUI 为实现模糊效果提供了两种强大的工具：

*   **`.blur()`**: 一个通用的高斯模糊修饰符，可以应用于任何视图。
*   **背景材质**: 一种高性能、具有平台一致性的“毛玻璃”背景，通过 `.background()` 应用。

理解这两者的区别和适用场景，将帮助你创建出既美观又具有高性能的模糊视觉效果，提升应用的整体质感。
