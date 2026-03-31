# SwiftUI 布局：间距与留白

在 UI 设计中，留白（White Space）或负空间（Negative Space）是与内容本身同等重要的元素。它有助于组织信息、降低视觉噪音、引导用户注意力，并创造出更美观、更易于阅读的界面。SwiftUI 提供了多种工具来精确地控制视图之间的间距和留白。

## 1. `padding()` 修饰符

`.padding()` 是在视图周围添加内边距（即留白）最常用、最直接的方式。它会增加视图的布局边界，从而将其他视图“推开”。

### 基本用法

不带任何参数的 `.padding()` 会在视图的所有边缘（上、下、左、右）添加一个由系统决定的、符合平台规范的默认间距。

```swift
import SwiftUI

Text("Hello, World!")
    .padding() // 在所有边缘添加默认间距
    .background(Color.blue)
```

### 指定边缘和长度

你可以更精确地控制 `padding` 的方向和大小。

```swift
VStack {
    Text("只在水平方向添加 padding")
        .padding(.horizontal, 20) // 水平方向各添加 20 点
        .background(Color.yellow)
    
    Text("只在底部添加 padding")
        .padding(.bottom, 40) // 底部添加 40 点
        .background(Color.mint)
        
    Text("在多个边缘添加不同 padding")
        .padding([.top, .leading], 10)
        .padding(.bottom, 30)
        .background(Color.purple)
}
```

*   你可以使用 `.horizontal`, `.vertical`, `.top`, `.bottom`, `.leading`, `.trailing` 来指定边缘。
*   你可以通过一个 `Edge.Set` 数组（如 `[.top, .bottom]`）来同时指定多个边缘。
*   你可以链式调用多个 `.padding()` 来为不同边缘应用不同大小的间距。

## 2. `Spacer` 视图

`Spacer` 是一个特殊的、灵活的视图，它会扩展并占据其所在堆栈（`VStack` 或 `HStack`）方向上的**所有可用空间**。它本身是不可见的，其作用就是创建灵活的、可伸缩的留白。

```swift
VStack {
    Text("顶部内容")
    
    Spacer() // 占据中间的所有垂直空间
    
    Text("底部内容")
}
.frame(height: 200)
.border(Color.gray)
```

在这个例子中，`Spacer` 将“顶部内容”和“底部内容”分别推到了 `VStack` 的两端。

### `minLength`

你可以为 `Spacer` 指定一个 `minLength`，以确保它创建的留白空间不会小于某个值。

```swift
HStack {
    Text("Left")
    Spacer(minLength: 50) // 保证至少有 50 点的间距
    Text("Right")
}
```

## 3. Stacks 中的 `spacing` 参数

`VStack`, `HStack` 和 `LazyVGrid`/`LazyHGrid` 等布局容器，在初始化时都可以接受一个 `spacing` 参数。这个参数定义了容器内**所有子视图之间**的统一间距。

```swift
VStack(spacing: 20) { // 所有子视图之间都有 20 点的垂直间距
    Text("Item 1")
    Text("Item 2")
    Text("Item 3")
}
```

这是创建均匀间隔列表或网格的最简单方法。如果你将 `spacing` 设置为 0，子视图之间将不会有任何间距。

## 4. `.offset()` 修饰符

`.offset()` 用于将视图从其原始布局位置进行平移。**它只移动视图的渲染结果，而不会改变其布局占位**，因此它**不会**创建真正的“留白”来推开其他视图，反而可能导致视图重叠。

`.offset()` 不应该被用作常规的间距工具。它的主要用途是创建视觉上的微调或装饰性的重叠效果。

（更多详情请参阅 `布局-offset偏移(ap).md`）

## 如何选择？

| 工具 | 作用 | 效果 | 适用场景 |
| :--- | :--- | :--- | :--- |
| **`.padding()`** | 在视图**内部**边缘添加空间。 | **推开**其他视图，增加视图的总尺寸。 | 为单个组件（如按钮、文本框）添加呼吸空间。 |
| **`Spacer()`** | 在堆栈中**占据**所有可用空间。 | **推开**视图到容器的两端，创建灵活的、可伸缩的间距。 | 在 `HStack` 或 `VStack` 中实现对齐和分布。 |
| **`spacing`** | 定义堆栈中**子视图之间**的统一间距。 | 在所有子视图之间创建**均匀**的间隔。 | 创建均匀分布的列表或网格。 |
| **`.offset()`** | **平移**视图的渲染位置。 | **不影响**其他视图的布局，可能导致重叠。 | 创建视觉上的重叠效果或动画。 |

## 总结

在 SwiftUI 中，控制间距和留白是构建清晰、美观布局的关键。

*   使用 **`.padding()`** 为单个元素添加“呼吸空间”。
*   使用 **`spacing`** 参数来创建一组元素的统一间隔。
*   使用 **`Spacer()`** 来填充灵活的空间，实现两端对齐或居中等布局。

通过组合使用这些工具，你可以精确地控制界面中的每一个像素，创造出既有条理又富有美感的视觉设计。
