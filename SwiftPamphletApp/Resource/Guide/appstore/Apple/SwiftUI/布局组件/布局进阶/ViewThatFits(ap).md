# SwiftUI 布局：ViewThatFits (iOS 16+)

`ViewThatFits` 是苹果在 WWDC 2022 (iOS 16) 中引入的一个非常实用的布局容器。它允许你提供多个备选的视图版本，然后它会自动评估在当前可用的空间下，哪个版本最适合显示，并只渲染那一个版本。

这对于创建需要在有限空间内优雅降级的、具有高度自适应性的组件非常有用。

## 核心问题：空间不足怎么办？

想象一下，你有一个显示用户信息的组件，它包含一个头像、全名和职位。在空间充足时，你希望水平排列它们。但在空间变得非常狭窄时（例如，在分屏模式下或在小组件中），水平排列可能会导致文本被截断，用户体验很差。

在 `ViewThatFits` 出现之前，你可能需要使用 `GeometryReader` 来读取可用宽度，并用 `if-else` 语句来手动切换不同的布局。这种方式代码冗长且难以维护。

## `ViewThatFits` 的解决方案

`ViewThatFits` 完美地解决了这个问题。你只需要在它的闭包中，按照**从最理想（需要空间最多）到最紧凑（需要空间最少）**的顺序列出你的备选视图即可。

`ViewThatFits` 会依次尝试渲染每一个备选视图：
1.  它会先尝试第一个（最理想的）版本。
2.  如果这个版本能够在当前可用空间内**不被截断或压缩**地完全显示，那么 `ViewThatFits` 就会选择它，并停止后续的尝试。
3.  如果第一个版本无法完全容纳，它就会放弃这个版本，然后继续尝试下一个备选视图。
4.  这个过程会一直持续，直到找到一个能够完美适应当前空间的视图，或者最终选择最后一个（通常是最紧凑的）备选方案。

```swift
import SwiftUI

struct ViewThatFitsExample: View {
    var body: some View {
        VStack {
            Text("在一个较宽的容器中:")
            MyAdaptiveView()
                .frame(width: 300)
                .border(Color.red)
            
            Divider().padding()
            
            Text("在一个较窄的容器中:")
            MyAdaptiveView()
                .frame(width: 180)
                .border(Color.blue)
        }
    }
}

struct MyAdaptiveView: View {
    var body: some View {
        // 1. 创建 ViewThatFits 容器
        ViewThatFits {
            // 2. 备选方案 1: 最理想的水平布局
            HStack {
                Image(systemName: "person.crop.circle.fill").font(.largeTitle)
                Text("John Appleseed").font(.headline)
            }
            
            // 3. 备选方案 2: 只显示名字的垂直布局
            VStack {
                Image(systemName: "person.crop.circle.fill").font(.largeTitle)
                Text("John Appleseed").font(.headline)
            }
            
            // 4. 备选方案 3: 最终的、最紧凑的方案
            Image(systemName: "person.crop.circle.fill").font(.largeTitle)
        }
    }
}

#Preview {
    ViewThatFitsExample()
}
```

在这个例子中：
*   在 300 点宽的红色边框容器中，空间充足，`ViewThatFits` 会选择第一个备选方案：`HStack`。
*   在 180 点宽的蓝色边框容器中，`HStack` 无法在不截断文本的情况下完全显示。因此，`ViewThatFits` 会放弃它，并尝试第二个方案 `VStack`。由于 `VStack` 可以被完美容纳，所以它最终被选中并渲染。
*   如果容器宽度被缩得更小，连 `VStack` 都无法容纳时，最终会降级到只显示一个 `Image`。

## 控制尝试的轴向

默认情况下，`ViewThatFits` 会同时在水平和垂直两个轴向上检查视图是否能被容纳。你可以通过 `in` 参数来指定只关心某一个轴向。

```swift
ViewThatFits(in: .horizontal) {
    // 只会检查视图在水平方向上是否会被截断
    HStack { ... }
    VStack { ... }
}
```

## 与 `AnyLayout` 的区别

`ViewThatFits` 和 `AnyLayout` 都是 iOS 16 中引入的、用于创建自适应布局的工具，但它们的用途不同。

*   **`ViewThatFits`**: **选择一个**最合适的视图来显示。它关心的是**内容**能否被完整呈现，并从多个**不同**的备选视图中进行选择。

*   **`AnyLayout`**: 在不同的**布局容器**（如 `VStackLayout` 和 `HStackLayout`）之间进行切换。它内部的**子视图是相同的**，只是它们的排列方式发生了变化。它关心的是**排列**，而不是内容本身。

简单来说，当你需要根据空间**从多个不同的视图中挑选一个**时，使用 `ViewThatFits`。当你需要让**同一组视图**在不同的**排列方式**之间平滑切换时，使用 `AnyLayout`。

## 总结

`ViewThatFits` 是一个优雅而强大的解决方案，用于处理因空间限制而需要改变视图呈现方式的场景。

*   **核心作用**: 从一组备选视图中，自动选择第一个能够在可用空间内完美容纳的视图。
*   **声明式**: 你只需要按优先级顺序列出你的备选方案，而无需编写任何手动计算尺寸或 `if-else` 判断的逻辑。
*   **优雅降级**: 它提供了一种创建“优雅降级” UI 的标准模式，确保你的组件在任何尺寸下都能提供最佳的用户体验。
*   **易于使用**: 相比于 `GeometryReader`，它的意图更清晰，使用更简单，且没有“贪婪”布局的副作用。

当你设计一个需要在多种不同尺寸（例如，在 `List` 的一行中、在一个小组件上、或在一个全屏页面上）都能良好工作的可复用组件时，`ViewThatFits` 是一个非常有用的工具。
