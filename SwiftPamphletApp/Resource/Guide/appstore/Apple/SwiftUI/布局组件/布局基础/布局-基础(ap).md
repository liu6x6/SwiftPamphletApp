# SwiftUI 布局基础

SwiftUI 的布局系统是其最强大、最具革命性的特性之一。它采用了一种**声明式**的方法，让你能够通过描述视图之间的关系来构建复杂的用户界面，而无需像在 `UIKit` 或 `AppKit` 中那样手动计算 `frame` 或设置繁琐的约束（Constraints）。

理解 SwiftUI 布局的三个核心概念——**视图、修饰符和容器**——是掌握其布局能力的基础。

## 1. 视图 (Views) 作为布局的基本单位

在 SwiftUI 中，一切皆为视图。每个视图都负责在屏幕上绘制自己，并向其父视图报告自己的**理想尺寸**。

*   **尺寸提议 (Size Proposal)**: 布局过程是一个自上而下的协商过程。父视图会向其子视图“提议”一个可用的空间尺寸。
*   **理想尺寸 (Ideal Size)**: 子视图根据自身的内容（例如，`Text` 的文本长度，`Image` 的原始尺寸）计算出一个它认为最合适的“理想尺寸”，并向父视图报告。
*   **最终尺寸**: 父视图接收到子视图的尺寸信息后，结合自身的布局逻辑（如 `VStack` 的对齐方式），最终决定每个子视图的实际位置和尺寸。

## 2. 布局容器 (Layout Containers)

布局容器是用于组织和排列其内部子视图的特殊视图。它们是 SwiftUI 布局的骨架。

*   **`VStack`**: 垂直堆栈，将子视图从上到下垂直排列。
*   **`HStack`**: 水平堆栈，将子视图从左到右水平排列。
*   **`ZStack`**: 深度堆栈，将子视图从后到前沿 Z 轴（深度）堆叠，实现覆盖效果。

通过任意嵌套这三种堆栈，你就可以构建出绝大多数的二维布局。

```swift
import SwiftUI

VStack {
    // 顶部标题
    Text("欢迎").font(.largeTitle)
    
    // 中间内容
    HStack {
        Image(systemName: "star.fill")
        Text("评分")
    }
    
    // 底部按钮
    Button("继续") { }
}
```

## 3. 布局修饰符 (Layout Modifiers)

修饰符是用于调整视图外观和布局的函数。在布局方面，它们允许你微调视图的尺寸、位置、间距和对齐方式。

### 尺寸修饰符

*   **`.frame(width:height:alignment:)`**: 为视图建议一个特定的宽度或高度。这是最常用的尺寸控制修饰符。你可以提供固定的值，也可以提供 `minWidth`, `maxWidth`, `minHeight`, `maxHeight` 来定义一个灵活的范围。

    ```swift
    Text("Hello")
        .frame(width: 200, height: 50)
        .background(Color.blue)
    ```

### 间距与偏移

*   **`.padding()`**: 在视图的边缘周围添加内边距（留白）。这会增加视图的整体尺寸，并将其他视图“推开”。

    ```swift
    Text("Padded Text").padding().background(Color.yellow)
    ```

*   **`.offset(x:y:)`**: 将视图从其原始布局位置进行平移。**重要的是，这不会改变视图的布局占位**，可能会导致它与其他视图重叠。

    ```swift
    Text("Offset Text").offset(y: -20)
    ```

### 空间与对齐

*   **`Spacer()`**: 一个灵活的视图，它会占据其所在堆栈方向上的所有可用空间。常用于将内容推到屏幕边缘。

    ```swift
    HStack {
        Text("左侧")
        Spacer() // 将“右侧”推到最右边
        Text("右侧")
    }
    ```

*   **对齐参数**: `VStack` 和 `HStack` 的 `alignment` 参数控制了其子视图的对齐方式。

    ```swift
    VStack(alignment: .leading) { ... } // 所有子视图向左对齐
    HStack(alignment: .bottom) { ... } // 所有子视图底部对齐
    ```

## 修饰符的顺序至关重要

在 SwiftUI 中，修饰符的应用顺序会极大地影响最终结果。每个修饰符都会接收前一个修饰符返回的视图，并对其进行包装，然后返回一个新的视图。

```swift
struct ModifierOrderExample: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("示例 1")
                .padding() // 1. 先加内边距
                .background(Color.red) // 2. 再为带内边距的视图添加背景
            
            Text("示例 2")
                .background(Color.red) // 1. 先为文本添加背景
                .padding() // 2. 再为带背景的视图添加内边距
        }
    }
}
```

**结果**: 
*   在**示例 1** 中，红色背景会填充整个带内边距的区域。
*   在**示例 2** 中，红色背景只会紧紧包裹住文本，而内边距则是在红色背景的**外部**添加的。

## 总结

SwiftUI 的布局系统是一个优雅而强大的声明式系统。

*   **三大基石**: **视图**（报告理想尺寸）、**容器**（排列子视图）、**修饰符**（调整布局）。
*   **协商过程**: 布局是一个从父视图到子视图的“提议-响应”过程。
*   **核心容器**: `VStack`, `HStack`, `ZStack` 是构建所有布局的基础。
*   **常用修饰符**: `.frame`, `.padding`, `.offset` 和 `Spacer` 是你日常布局的得力助手。
*   **顺序是关键**: 务必注意修饰符的应用顺序，因为它直接决定了最终的视觉效果。

通过组合这些基础概念，你可以构建出从简单到复杂的各种用户界面，并且你的布局代码将具有前所未有的可读性和可维护性。
