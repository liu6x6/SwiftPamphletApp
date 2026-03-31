# SwiftUI 布局：alignmentGuide

`.alignmentGuide()` 是 SwiftUI 布局系统中一个极其强大的修饰符，它允许你为单个视图**覆盖**其在 `HStack`, `VStack` 或 `ZStack` 中的默认对齐行为。通过它，你可以创建出标准对齐方式无法实现的、高度自定义的、像素级精确的对齐效果。

## 核心用法

`.alignmentGuide()` 修饰符接收两个参数：

1.  **`g`**: 你想要修改的对齐类型。例如，对于 `HStack`，你可以修改 `.top`, `.center`, `.bottom` 或 `.firstTextBaseline` 等 `VerticalAlignment`；对于 `VStack`，你可以修改 `.leading`, `.center`, `.trailing` 等 `HorizontalAlignment`。
2.  **`computeValue`**: 一个闭包，它接收一个 `ViewDimensions` 对象作为参数，并必须返回一个 `CGFloat` 值。这个返回值就是该视图在这条对齐线上的**新位置**。

### `ViewDimensions` 对象

`ViewDimensions` 对象就像一个“尺寸探测器”，你可以通过它来获取视图的尺寸信息。

*   `d.width`: 视图的宽度。
*   `d.height`: 视图的高度。
*   `d[explicit:]`: 你还可以通过下标来获取视图在**其他对齐线上**的位置。例如，`d[VerticalAlignment.bottom]` 会返回视图底部边缘的位置，`d[HorizontalAlignment.center]` 会返回视图水平中心的位置。

## 示例：在 `HStack` 中创建非标准垂直对齐

假设我们想让一个 `HStack` 中的几个视图，它们的中心线不是对齐的，而是呈阶梯状排列。

```swift
import SwiftUI

struct AlignmentGuideExample: View {
    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            VStack {
                Text("视图 A")
                Rectangle().fill(Color.red).frame(width: 50, height: 50)
            }
            
            VStack {
                Text("视图 B")
                Rectangle().fill(Color.green).frame(width: 50, height: 50)
            }
            // 覆盖视图 B 的 .center 对齐行为
            .alignmentGuide(.center) { d in
                // 将 B 的中心线向下移动 20 点
                d[VerticalAlignment.center] + 20
            }
            
            VStack {
                Text("视图 C")
                Rectangle().fill(Color.blue).frame(width: 50, height: 50)
            }
            // 覆盖视图 C 的 .center 对齐行为
            .alignmentGuide(.center) { d in
                // 将 C 的中心线向上移动 20 点
                d[VerticalAlignment.center] - 20
            }
        }
        .border(Color.gray)
    }
}

#Preview {
    AlignmentGuideExample()
}
```

在这个例子中：
*   `HStack` 的整体对齐方式是 `.center`。
*   对于视图 B 和 C，我们使用 `.alignmentGuide(.center)` 来“拦截”并修改它们的中心对齐线。我们通过在默认中心线位置 `d[VerticalAlignment.center]` 的基础上进行加减，来改变它们的最终垂直位置。

## 示例：对齐不同视图的特定部分

`.alignmentGuide` 最强大的功能之一是能够读取一个视图在**其他对齐线上**的位置，并用它来设置**当前对齐线**的位置。这使得在不同视图的任意部分之间创建对齐关系成为可能。

假设我们想让一个 `Image` 的垂直中心，与旁边一段多行文本的**第一行文本的基线**对齐。

```swift
struct CrossViewAlignmentExample: View {
    var body: some View {
        HStack(alignment: .firstTextBaseline) { // 1. HStack 使用基线对齐
            Image(systemName: "person.crop.circle.fill")
                .font(.largeTitle)
                // 2. 告诉 Image，它的 .firstTextBaseline 在哪里
                .alignmentGuide(.firstTextBaseline) { d in
                    // 3. 将其基线位置设置为其垂直中心
                    d[VerticalAlignment.center]
                }
            
            VStack(alignment: .leading) {
                Text("John Appleseed")
                    .font(.headline)
                Text("iOS Developer and SwiftUI Enthusiast")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

#Preview {
    CrossViewAlignmentExample()
}
```

在这个例子中：
1.  `HStack` 的对齐方式被设置为 `.firstTextBaseline`。
2.  对于 `VStack` 中的文本，SwiftUI 自动知道它们的第一行文本基线在哪里。
3.  对于 `Image`，它本身没有文本基线。因此，我们使用 `.alignmentGuide(.firstTextBaseline)` 来为它“伪造”一个基线。我们告诉 `HStack`：“请将我的‘第一行文本基线’，看作是我的‘垂直中心线’（`d[VerticalAlignment.center]`）。”
4.  最终，`HStack` 会将 `Image` 的垂直中心与右侧 `Text` 的第一行基线对齐，实现了我们想要的视觉效果。

## 自定义对齐类型

通过创建自定义的 `AlignmentID`，你可以定义全新的对齐线，并在完全不相关的视图之间建立对齐关系，实现更高级、更灵活的布局。

（更多详情请参阅 `布局-对齐(ap).md`）

## 总结

`.alignmentGuide()` 是 SwiftUI 布局系统中一个用于精细控制和覆盖默认对齐行为的高级工具。

*   **作用**: 为单个视图在特定对齐类型（如 `.center`, `.bottom`, `.firstTextBaseline`）上提供一个自定义的位置值。
*   **核心**: 闭包接收一个 `ViewDimensions` 对象，允许你读取视图的尺寸和其他对齐线的位置，并返回一个新的 `CGFloat` 值作为对齐位置。
*   **强大之处**: 能够在一个视图的 `alignmentGuide` 中，引用**另一个对齐线**的位置（如 `d[VerticalAlignment.center]`），从而在不同视图的不同部分之间创建对齐关系。

当你发现标准的 `VStack`/`HStack` 对齐方式无法满足你精细的布局需求时，`.alignmentGuide()` 就是你实现像素级完美对齐的终极武器。它是从“让视图排列”到“让视图**精确地**排列”的关键一步。
