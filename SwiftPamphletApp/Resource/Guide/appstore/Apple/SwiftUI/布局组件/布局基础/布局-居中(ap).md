# SwiftUI 布局：实现居中

在 UI 设计中，将视图居中（水平、垂直或两者兼有）是最常见的布局需求之一。SwiftUI 提供了多种简单而直观的方式来实现居中对齐，具体选择哪种方式取决于你的布局上下文。

## 1. 在 `VStack` 和 `HStack` 中居中

`VStack` 和 `HStack` 的默认对齐方式就是居中，这使得在单个维度上实现居中非常简单。

*   **`VStack`**: 默认将其子视图**水平居中** (`alignment: .center`)。
*   **`HStack`**: 默认将其子视图**垂直居中** (`alignment: .center`)。

```swift
import SwiftUI

VStack {
    // 这个 HStack 默认在 VStack 中水平居中
    HStack {
        // 这两个 Text 默认在 HStack 中垂直居中
        Image(systemName: "star.fill")
        Text("居中对齐")
    }
}
```

## 2. 使用 `Spacer` 实现居中

`Spacer` 是一个灵活的视图，它会占据其所在堆栈方向上的所有可用空间。通过在视图的两侧放置 `Spacer`，你可以轻松地将其推到容器的中心。

### 水平居中

在一个 `HStack` 中，将一个视图包裹在两个 `Spacer` 之间，可以实现水平居中。

```swift
HStack {
    Spacer() // 左侧弹簧
    Text("水平居中")
    Spacer() // 右侧弹簧
}
```

### 垂直居中

在一个 `VStack` 中，将一个视图包裹在两个 `Spacer` 之间，可以实现垂直居中。

```swift
VStack {
    Spacer() // 顶部弹簧
    Text("垂直居中")
    Spacer() // 底部弹簧
}
```

## 3. 在 `ZStack` 中居中

`ZStack` 的默认对齐方式就是 `.center`，它会将其所有子视图在两个维度上都居中对齐。这使得在父视图中将一个子视图完全居中变得异常简单。

```swift
ZStack {
    // 背景
    Rectangle()
        .fill(Color.mint)
        .frame(width: 200, height: 100)
    
    // 这个 Text 会自动在 Rectangle 的中心
    Text("完全居中")
}
```

这是将一个视图覆盖在另一个视图之上并居中的最常用方法。

## 4. 使用 `.frame` 修饰符实现居中

`.frame` 修饰符不仅可以设置尺寸，还可以控制视图在其分配的框架（frame）内的对齐方式。通过将 `maxWidth` 或 `maxHeight` 设置为 `.infinity`，你可以让框架占据所有可用空间，然后使用 `alignment` 参数来将视图放置在该框架的中心。

```swift
struct FrameCenterExample: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("左对齐的文本")
            
            // 这个视图会在 VStack 的可用宽度内水平居中
            Text("居中的文本")
                .frame(maxWidth: .infinity, alignment: .center)
                .background(Color.yellow)
            
            Text("另一段左对齐的文本")
        }
        .border(Color.gray)
    }
}

#Preview {
    FrameCenterExample()
}
```

在这个例子中：
1.  `VStack` 的整体对齐方式是 `.leading`。
2.  对于中间的 `Text`，我们给它一个 `maxWidth: .infinity` 的框架，使其背景（黄色部分）填满整个 `VStack` 的宽度。
3.  然后，`alignment: .center` 参数告诉 SwiftUI，应该将 `Text` 本身放置在这个无限宽的黄色框架的**中心**。

这种方法非常强大，因为它允许你在一个具有特定对齐方式的父容器中，对单个子视图应用不同的对齐规则。

### 完全居中

结合 `VStack` 和 `HStack`，或者在单个视图上应用 `.frame(maxWidth: .infinity, maxHeight: .infinity)`，可以实现完全居中。

```swift
struct FullScreenCenter: View {
    var body: some View {
        // 方法 1: 使用 Spacers
        VStack {
            Spacer()
            HStack {
                Spacer()
                Text("Hello, Center!")
                Spacer()
            }
            Spacer()
        }
        
        // 方法 2: 使用 .frame
        Text("Hello, Center!")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray.opacity(0.2))
    }
}
```

方法 2 更简洁，它创建了一个占据整个屏幕的背景，并将文本放置在其中心。

## 总结

SwiftUI 提供了多种实现居中布局的方式，你可以根据上下文选择最简洁、最语义化的一种。

| 方法 | 适用场景 | 优点 |
| :--- | :--- | :--- |
| **`VStack`/`HStack` 默认行为** | 在单个轴向上对齐一组视图。 | 简单，无需额外代码。 |
| **`Spacer`** | 在一个堆栈中，将一个或多个视图推到中心。 | 直观，易于理解。 |
| **`ZStack`** | 将一个视图覆盖在另一个视图之上并居中。 | 创建覆盖和居中效果的最直接方式。 |
| **`.frame(maxWidth/Height: .infinity)`** | 在一个更大的布局容器中，对单个视图进行居中。 | 灵活，可以在不改变父容器对齐方式的情况下实现局部居中。 |

掌握这些基本的居中技巧，是构建平衡、和谐的 SwiftUI 界面的第一步。
