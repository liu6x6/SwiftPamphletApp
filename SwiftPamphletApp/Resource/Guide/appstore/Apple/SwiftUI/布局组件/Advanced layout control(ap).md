# SwiftUI 中的高级布局控制

虽然 SwiftUI 的 `VStack`, `HStack`, `ZStack` 和 `Grid` 等标准布局容器能够满足大部分日常的布局需求，但有时你需要对布局进行更精细、更动态的控制。SwiftUI 提供了一系列高级工具，让你能够创建出自适应、复杂且高度自定义的布局。

这些工具的核心是让你能够“读取”视图的几何信息，并据此做出布局决策。

## 1. `GeometryReader`

`GeometryReader` 是一个容器视图，它会将其父视图提供的**建议尺寸**捕获，并通过一个 `GeometryProxy` 对象暴露给你。这允许你根据可用的空间来动态地调整子视图的尺寸和位置。

```swift
import SwiftUI

struct GeometryReaderExample: View {
    var body: some View {
        GeometryReader { geometry in
            // geometry 包含了父视图提供的尺寸信息
            let parentSize = geometry.size
            
            VStack {
                Text("父视图尺寸: \(Int(parentSize.width)) x \(Int(parentSize.height))")
                
                Rectangle()
                    .fill(Color.blue)
                    // 子视图的尺寸可以基于父视图的尺寸来计算
                    .frame(width: parentSize.width * 0.8, height: parentSize.height * 0.3)
            }
        }
        .frame(height: 200)
        .border(Color.red)
    }
}

#Preview {
    GeometryReaderExample()
}
```

**`GeometryProxy` 提供了什么？**
*   `size`: 可用区域的尺寸 (`CGSize`)。
*   `frame(in: CoordinateSpace)`: 视图在指定坐标空间中的位置和尺寸 (`CGRect`)。
*   `safeAreaInsets`: 安全区域的边距。

**注意事项**: 
*   `GeometryReader` 具有“贪婪”的行为，它会尽可能地占用所有父视图提供的空间。
*   它会改变布局行为，有时可能会带来非预期的结果。应谨慎使用，仅在确实需要根据父视图尺寸来布局时才使用。

## 2. 坐标空间 (`CoordinateSpace`)

为了精确地获取视图的位置，你需要理解坐标空间。SwiftUI 提供了几种预定义的坐标空间：

*   `.local`: 视图自身的坐标空间，其左上角为 `(0, 0)`。
*   `.global`: 整个屏幕或窗口的坐标空间。
*   `.named(_:)`: 你可以通过 `.coordinateSpace(name: ...)` 修饰符来创建一个自定义的、命名的坐标空间。这在需要计算两个任意视图之间的相对位置时非常有用。

```swift
struct CoordinateSpaceExample: View {
    var body: some View {
        VStack {
            GeometryReader { geo in
                let localFrame = geo.frame(in: .local)
                let globalFrame = geo.frame(in: .global)
                // ...
            }
        }
    }
}
```

## 3. `alignmentGuide()`

`alignmentGuide()` 是一个极其强大的修饰符，它允许你**覆盖**一个视图在 `HStack` 或 `VStack` 中的默认对齐行为。你可以根据视图自身的尺寸或其他逻辑，来精确地控制它应该如何与其他视图对齐。

它接收一个对齐类型（如 `VerticalAlignment.center`）和一个闭包。这个闭包返回一个新的对齐值。

```swift
struct AlignmentGuideExample: View {
    var body: some View {
        HStack(alignment: .bottom, spacing: 20) {
            Text("Hello")
                .font(.largeTitle)
            
            Text("World")
                .font(.body)
                // 自定义“底部”对齐线的位置
                .alignmentGuide(.bottom) { d in
                    // d 是一个 ViewDimensions 对象，包含视图的尺寸
                    // 将此视图的底部向上移动 20 个点
                    d[.bottom] - 20
                }
        }
        .border(Color.gray)
    }
}

#Preview {
    AlignmentGuideExample()
}
```

在这个例子中，尽管 `HStack` 的对齐方式是 `.bottom`，但我们通过 `alignmentGuide` 将第二个 `Text` 的“底部”对齐线向上移动了 20 个点，使其看起来像是悬浮了起来。

## 4. 自定义对齐类型

你甚至可以创建自己的对齐类型，以实现更复杂的、非标准的对齐效果。

1.  **定义对齐 ID**: 创建一个遵循 `AlignmentID` 协议的枚举或结构体，并提供一个 `defaultValue(in:)` 方法。
2.  **创建 `HorizontalAlignment` / `VerticalAlignment`**: 使用你定义的 ID 创建一个新的静态对齐属性。

```swift
// 1. 定义 ID
private enum MyVerticalAlignment: AlignmentID {
    static func defaultValue(in context: ViewDimensions) -> CGFloat {
        return context.height / 2 // 默认居中
    }
}

// 2. 创建对齐类型
extension VerticalAlignment {
    static let myAlignment = VerticalAlignment(MyVerticalAlignment.self)
}

// 3. 在布局容器和子视图中使用
HStack(alignment: .myAlignment) {
    Image(systemName: "swift").alignmentGuide(.myAlignment) { d in d[VerticalAlignment.center] }
    Text("Aligned to custom guide").alignmentGuide(.myAlignment) { d in d[VerticalAlignment.center] }
}
```

## 5. `Layout` 协议 (iOS 16+)

对于终极的布局控制，你可以使用 `Layout` 协议来创建自己的布局容器。这允许你实现任何你能想象到的布局算法，如瀑布流、径向布局、梯形布局等。

（更多详情请参阅 `Layout协议(ap).md`）

## 总结

SwiftUI 的布局系统远比初看起来的 `VStack` 和 `HStack` 要强大得多。通过掌握这些高级布局工具，你可以从简单地排列视图，转向精确地、动态地控制每一个视图的位置和尺寸。

*   **`GeometryReader`**: 当你需要**读取**父视图的尺寸来**决定**子视图的布局时使用。
*   **`alignmentGuide`**: 当你需要**覆盖**标准 `VStack`/`HStack` 的对齐行为，实现自定义对齐时使用。
*   **`Layout` 协议**: 当你需要创建全新的、非标准的布局容器时使用。

合理地运用这些工具，将使你能够构建出真正独特、复杂且能完美适应不同屏幕尺寸和动态内容的 SwiftUI 界面。
