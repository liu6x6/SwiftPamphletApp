# SwiftUI 布局：对齐 (Alignment)

在 SwiftUI 中，对齐（Alignment）是控制子视图在布局容器（如 `VStack`, `HStack`, `ZStack`）中如何排列的关键机制。SwiftUI 提供了一套强大而灵活的对齐系统，让你能够精确地控制视图的相对位置。

## Stacks 中的对齐

`VStack` 和 `HStack` 在初始化时都可以接受一个 `alignment` 参数。

### `VStack` 的水平对齐

在 `VStack` 中，`alignment` 参数控制其所有子视图在**水平方向**上的对齐方式。它是一个 `HorizontalAlignment` 类型的值。

*   `.leading`: 所有子视图的左边缘对齐。
*   `.center`: 所有子视图的中心线对齐（默认值）。
*   `.trailing`: 所有子视图的右边缘对齐。

```swift
import SwiftUI

VStack(alignment: .leading, spacing: 10) {
    Text("左对齐")
        .font(.largeTitle)
    Text("这是一段较长的文本")
        .font(.body)
    Rectangle()
        .frame(width: 100, height: 20)
}
.padding()
.border(Color.gray)
```

### `HStack` 的垂直对齐

在 `HStack` 中，`alignment` 参数控制其所有子视图在**垂直方向**上的对齐方式。它是一个 `VerticalAlignment` 类型的值。

*   `.top`: 所有子视图的上边缘对齐。
*   `.center`: 所有子视图的中心线对齐（默认值）。
*   `.bottom`: 所有子视图的下边缘对齐。
*   `.firstTextBaseline`: 所有子视图的第一行文本的**基线**对齐。
*   `.lastTextBaseline`: 所有子视图的最后一行文本的**基线**对齐。

```swift
HStack(alignment: .firstTextBaseline, spacing: 20) {
    Text("价格")
        .font(.headline)
    
    Text("$99.99")
        .font(.system(size: 48, weight: .bold))
    
    Text("含税")
        .font(.caption)
}
```

使用**基线对齐**（`.firstTextBaseline` 或 `.lastTextBaseline`）对于对齐包含不同字体大小的文本非常有用，它能创造出比简单的 `.top` 或 `.center` 对齐更和谐的视觉效果。

## `ZStack` 中的对齐

`ZStack` 的 `alignment` 参数控制其子视图在**两个维度**上的对齐方式。它是一个 `Alignment` 类型的值，你可以使用 `.topLeading`, `.bottom`, `.center` 等九个预设的组合位置。

```swift
ZStack(alignment: .topTrailing) {
    // 背景
    Color.mint.frame(width: 200, height: 100)
    
    // 这个按钮会出现在 ZStack 的右上角
    Button { } label: {
        Image(systemName: "xmark.circle.fill")
            .font(.title)
            .foregroundColor(.gray)
    }
    .padding(5)
}
```

## `alignmentGuide()`：精细控制对齐

当标准的对齐方式无法满足你的需求时，`.alignmentGuide()` 修饰符允许你为单个视图**覆盖**其默认的对齐行为。你可以提供一个闭包，该闭包计算并返回一个自定义的对齐偏移量。

```swift
struct AlignmentGuideExample: View {
    var body: some View {
        HStack(alignment: .bottom) {
            Rectangle().fill(Color.red).frame(width: 50, height: 50)
            
            Rectangle().fill(Color.green).frame(width: 50, height: 50)
                // 自定义这个视图的 .bottom 对齐线
                .alignmentGuide(.bottom) { d in
                    // d 是一个 ViewDimensions 对象
                    // 将此视图的底部对齐线向上移动 25 个点
                    d[.bottom] - 25
                }
            
            Rectangle().fill(Color.blue).frame(width: 50, height: 50)
        }
    }
}
```

在这个例子中，中间的绿色矩形相对于其他两个矩形向上偏移了，因为它告诉 `HStack` 它的“底部”在一个不同的位置。

## 自定义对齐类型

对于更复杂的布局，你甚至可以创建自己的对齐类型。这允许你在两个不直接相关的视图之间创建对齐关系。

1.  **定义 `AlignmentID`**: 创建一个遵循 `AlignmentID` 协议的类型，并提供一个默认值。
2.  **扩展 `VerticalAlignment` 或 `HorizontalAlignment`**: 创建一个新的静态对齐属性。
3.  **应用对齐**: 在布局容器中使用新的对齐类型，并在子视图上使用 `.alignmentGuide()` 来指定它们如何参与这个自定义对齐。

```swift
// 1. 定义 ID
private struct MidAccountName: AlignmentID {
    static func defaultValue(in d: ViewDimensions) -> CGFloat {
        d[.bottom]
    }
}

// 2. 创建对齐类型
extension VerticalAlignment {
    static let midAccountName = VerticalAlignment(MidAccountName.self)
}

// 3. 应用
HStack(alignment: .midAccountName) {
    Image(systemName: "person.crop.circle").font(.largeTitle)
    
    VStack(alignment: .leading) {
        Text("John Appleseed")
            .font(.headline)
            // 将 VStack 的 .midAccountName 对齐线设置为这段文本的中心
            .alignmentGuide(.midAccountName) { d in d[VerticalAlignment.center] }
        Text("Editor")
            .font(.caption)
    }
}
```

在这个例子中，我们创建了一个名为 `.midAccountName` 的自定义垂直对齐。我们让 `HStack` 使用这个对齐方式，然后告诉 `VStack`，它的 `.midAccountName` 对齐线应该位于其内部第一个 `Text` 的垂直中心。最终的效果是，左侧的 `Image` 会与右侧的“John Appleseed”文本垂直对齐，而不是与整个 `VStack` 对齐。

## 总结

对齐是 SwiftUI 布局系统中一个深刻而强大的概念。

*   **容器对齐**: `VStack`, `HStack`, `ZStack` 的 `alignment` 参数为布局设定了基本规则。
*   **基线对齐**: 对于包含文本的 `HStack`，使用 `.firstTextBaseline` 或 `.lastTextBaseline` 通常能获得最佳的视觉效果。
*   **精细控制**: `.alignmentGuide()` 是一个强大的工具，用于微调或完全覆盖单个视图的对齐行为。
*   **自定义对齐**: 创建自己的 `AlignmentID` 可以让你实现跨越多个视图的、复杂的自定义对齐逻辑。

通过熟练地运用这些对齐工具，你可以从简单的堆叠布局，转向构建出像素级精确、视觉和谐且高度自适应的复杂界面。
