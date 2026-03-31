# SwiftUI 布局：GeometryReader

`GeometryReader` 是 SwiftUI 中一个用于读取父视图几何信息（尺寸和位置）的容器视图。它允许你创建依赖于其所在环境尺寸的、具有高度自适应性的布局。当你需要根据可用的空间来动态地决定子视图的大小或位置时，`GeometryReader` 是一个必不可少的工具。

## 核心用法

`GeometryReader` 是一个视图，它的 `content` 闭包会接收一个 `GeometryProxy` 对象作为参数。你可以从这个 `proxy` 对象中查询到父视图提供的可用空间信息。

```swift
import SwiftUI

struct GeometryReaderExample: View {
    var body: some View {
        // 将 GeometryReader 放置在一个有确定尺寸的父视图中
        VStack {
            Text("父视图提供了一个 300x200 的空间")
            
            GeometryReader { geometry in
                // `geometry` 参数是一个 GeometryProxy
                let parentSize = geometry.size
                
                ZStack(alignment: .topLeading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                    
                    Text("可用宽度: \(Int(parentSize.width))")
                        .padding()
                    
                    // 子视图的尺寸可以基于父视图的尺寸来计算
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: parentSize.width / 2, height: parentSize.height / 2)
                }
            }
            .frame(width: 300, height: 200)
            .border(Color.red)
        }
    }
}

#Preview {
    GeometryReaderExample()
}
```

在这个例子中：
1.  `GeometryReader` 被放置在一个 300x200 的 `frame` 内。
2.  在其闭包内部，`geometry.size` 的值就是 `CGSize(width: 300, height: 200)`。
3.  我们可以使用 `parentSize.width` 和 `parentSize.height` 来动态地设置蓝色 `Rectangle` 的尺寸，使其始终为父容器的一半。

## `GeometryProxy` 提供的关键信息

`GeometryProxy` 是你与布局系统沟通的桥梁，它提供了三个关键信息：

1.  **`size: CGSize`**: 父视图提供的可用空间大小。

2.  **`safeAreaInsets: EdgeInsets`**: 描述了安全区域在视图边缘的内边距。你可以读取 `.top`, `.bottom`, `.leading`, `.trailing`。

3.  **`frame(in: CoordinateSpace) -> CGRect`**: 这是最强大的功能。它返回当前视图在**指定坐标空间**中的位置和尺寸（一个 `CGRect`）。

### 坐标空间 (`CoordinateSpace`)

*   **`.local`**: 视图自身的坐标空间，其左上角 `origin` 永远是 `(0, 0)`。
*   **`.global`**: 整个窗口或屏幕的最外层坐标空间。
*   **`.named(_:)`**: 你可以通过 `.coordinateSpace(name: "MySpace")` 修饰符创建的自定义命名空间。这对于计算任意两个视图之间的相对位置至关重要。

#### 示例：获取全局位置

```swift
struct GlobalPositionExample: View {
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                GeometryReader { geo in
                    let frame = geo.frame(in: .global)
                    Text("我的全局位置: (x: \(Int(frame.minX)), y: \(Int(frame.minY)))")
                        .padding()
                        .background(Color.yellow)
                }
                Spacer()
            }
            Spacer()
        }
    }
}
```

## `GeometryReader` 的布局行为

理解 `GeometryReader` 的布局行为非常重要，因为它常常会带来意想不到的结果。

*   **“贪婪”的尺寸**: `GeometryReader` 会尽可能地**占据所有**父视图提供的可用空间。例如，如果你直接将一个 `GeometryReader` 放入 `HStack`，它会把所有其他视图都推开。

    ```swift
    HStack {
        Text("Left")
        GeometryReader { _ in Color.red } // 这个 GeometryReader 会占据所有剩余空间
        Text("Right")
    }
    ```

*   **对齐**: `GeometryReader` 内部的视图对齐是相对于 `GeometryReader` 自身的，而不是其父容器。`GeometryReader` 本身在其父容器中是左上角对齐的。

由于这种“贪婪”和独立的布局行为，通常不建议将 `GeometryReader` 作为主要的布局工具。你应该只在**确实需要读取父视图几何信息**时才使用它，并且最好将它包裹在 `.background()` 或 `.overlay()` 中，以避免它干扰你的主布局。

### 推荐用法：使用 `.background` 或 `.overlay`

```swift
struct RecommendedGeometryReaderUsage: View {
    var body: some View {
        Text("Hello, World!")
            .padding()
            .background(
                // 将 GeometryReader 放在背景中
                GeometryReader { geo in
                    // 在这里可以安全地读取尺寸，而不会影响 Text 的布局
                    let size = geo.size
                    // ...
                    Color.clear // 背景需要返回一个 View
                }
            )
    }
}
```

## `GeometryReader` 的应用场景

*   **创建依赖于尺寸的布局**: 例如，创建一个宽度始终是高度两倍的视图。
*   **视差滚动效果 (Parallax Scrolling)**: 在 `ScrollView` 中，使用 `GeometryReader` 读取每个子视图相对于滚动视图窗口的位置，并据此应用一个偏移，从而创建出背景比前景滚动得慢的视差效果。
*   **自定义图表**: 在绘制图表时，你需要知道可用的绘图区域有多大，以便正确地缩放和定位你的数据点。
*   **获取视图在屏幕上的绝对位置**: 通过 `.frame(in: .global)`，你可以知道一个视图在屏幕上的确切位置，这对于实现一些拖放或弹出菜单的逻辑很有用。

## 总结

`GeometryReader` 是一个强大的工具，它为你打开了一扇通往 SwiftUI 布局系统底层信息的大门。

*   **核心作用**: 读取父视图提供的尺寸和位置信息。
*   **关键对象**: `GeometryProxy`，提供了 `size`, `safeAreaInsets`, 和 `frame(in:)`。
*   **布局行为**: 具有“贪婪”性，会占据所有可用空间。因此，应谨慎使用。
*   **最佳实践**: 优先考虑将 `GeometryReader` 放置在 `.background()` 或 `.overlay()` 中，以避免它干扰你的主布局流。

虽然你不应该滥用 `GeometryReader`，但在需要创建复杂的、自适应的、或依赖于位置的动态布局时，它是一个不可或缺的、强大的解决方案。
