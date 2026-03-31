# SwiftUI 布局基石：Stacks (VStack, HStack, ZStack)

在 SwiftUI 中，**Stacks（堆栈）** 是构建用户界面的最基本、最核心的布局容器。它们允许你以一种简单、声明式的方式来组织和排列视图。SwiftUI 提供了三种主要的堆栈类型，它们共同构成了绝大多数布局的基础。

1.  **`VStack` (Vertical Stack)**: 垂直堆栈，将其子视图从上到下垂直排列。
2.  **`HStack` (Horizontal Stack)**: 水平堆栈，将其子视图从左到右水平排列。
3.  **`ZStack` (Depth Stack)**: 深度堆栈，将其子视图从后到前沿 Z 轴（深度）堆叠，实现覆盖效果。

## `VStack`：垂直排列

`VStack` 用于将视图垂直地、一个接一个地排列。

```swift
import SwiftUI

VStack(alignment: .leading, spacing: 10) {
    Text("用户名")
        .font(.headline)
    TextField("输入用户名", text: .constant(""))
        .textFieldStyle(.roundedBorder)
    Text("密码")
        .font(.headline)
    SecureField("输入密码", text: .constant(""))
        .textFieldStyle(.roundedBorder)
}
.padding()
```

**核心参数**:
*   **`alignment`**: 控制子视图在其**水平**方向上的对齐方式。可选值为 `.leading`, `.center`, `.trailing`。
*   **`spacing`**: 控制子视图之间的**垂直**间距。

## `HStack`：水平排列

`HStack` 用于将视图水平地、并排地排列。

```swift
HStack(alignment: .center, spacing: 15) {
    Image(systemName: "person.crop.circle.fill")
        .font(.largeTitle)
    
    VStack(alignment: .leading) {
        Text("John Appleseed").font(.title2)
        Text("iOS Developer").foregroundColor(.secondary)
    }
    
    Spacer() // 伸缩弹簧，会占据所有可用空间
    
    Button("关注") {}.buttonStyle(.bordered)
}
.padding()
```

**核心参数**:
*   **`alignment`**: 控制子视图在其**垂直**方向上的对齐方式。可选值为 `.top`, `.center`, `.bottom`, `.firstTextBaseline`, `.lastTextBaseline`。
*   **`spacing`**: 控制子视图之间的**水平**间距。

### `Spacer`：灵活的间距

`Spacer` 是一个特殊的、灵活的视图，它会扩展并占据其所在堆栈方向上的所有可用空间。这对于将内容推到屏幕边缘或在两个视图之间创建最大间距非常有用。

## `ZStack`：深度堆叠

`ZStack` 用于将视图一层一层地堆叠在一起，就像扑克牌一样。后添加的视图会显示在先添加的视图之上。

```swift
ZStack(alignment: .bottomTrailing) {
    // 底层：背景图片
    Image("landscape")
        .resizable()
        .scaledToFill()
    
    // 中间层：半透明的渐变，增强文本可读性
    LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .top, endPoint: .bottom)
    
    // 顶层：文本和按钮
    VStack(alignment: .trailing) {
        Text("探索 SwiftUI")
            .font(.largeTitle)
            .fontWeight(.bold)
        Text("发现无限可能")
            .font(.headline)
    }
    .foregroundColor(.white)
    .padding()
}
.frame(height: 300)
.cornerRadius(20)
```

**核心参数**:
*   **`alignment`**: 控制子视图在**两个维度**（水平和垂直）上的对齐方式。你可以使用 `.topLeading`, `.bottom`, `.center` 等九个预设位置。

## 组合 Stacks

SwiftUI 布局的真正威力在于**组合**。你可以通过任意嵌套 `VStack`, `HStack`, 和 `ZStack` 来构建出几乎任何你能想象到的复杂布局。

```swift
VStack {
    HStack { ... }
    ZStack { ... }
    HStack { ... }
}
```

这种组合式的思想是 SwiftUI 声明式布局的核心。

## 性能考量

*   **视图限制**: 在 SwiftUI 的早期版本中，一个堆栈内最多只能直接放置 10 个子视图。如果你需要放置更多，应该使用 `ForEach` 循环，或者将它们分组到另一个堆栈中。尽管这个限制在后来的版本中有所放宽，但这仍然是一个很好的实践，鼓励你将复杂的视图拆分成更小的、逻辑更清晰的组件。
*   **`LazyVStack` & `LazyHStack`**: 对于需要显示大量（成百上千个）子视图的、可滚动的列表，应该使用 `LazyVStack` 或 `LazyHStack`。这些“懒加载”的堆栈只会在子视图即将进入屏幕时才创建和渲染它们，从而极大地提升了性能并降低了内存占用。

## 总结

`VStack`, `HStack`, 和 `ZStack` 是 SwiftUI 布局工具箱中最基础、最重要的三个工具。它们共同定义了视图在屏幕上的空间关系。

*   **`VStack`**: 垂直排列，从上到下。
*   **`HStack`**: 水平排列，从左到右。
*   **`ZStack`**: 深度排列，从后到前。

掌握如何通过 `alignment` 和 `spacing` 来微调它们的行为，如何使用 `Spacer` 来控制空间分配，以及如何通过嵌套组合来构建复杂界面，是每一个 SwiftUI 开发者都必须熟练掌握的基本功。
