# SwiftUI 数据集合组件：LazyVGrid 与 LazyHGrid

`LazyVGrid` 和 `LazyHGrid` 是 SwiftUI 中用于创建二维网格布局的强大容器。与标准的 `Grid` (iOS 16+) 不同，它们是“懒加载”（Lazy）的，这意味着它们只会在其子视图即将进入屏幕时才创建和渲染，这使得它们在处理大量数据时具有极高的性能和内存效率。

*   **`LazyVGrid`**: 创建一个**垂直**滚动的网格，你在其中定义**列（Column）**的布局。
*   **`LazyHGrid`**: 创建一个**水平**滚动的网格，你在其中定义**行（Row）**的布局。

这两种网格通常被放置在一个 `ScrollView` 中，以提供滚动能力。

## 核心用法：定义 `GridItem`

创建懒加载网格的核心是定义一个 `GridItem` 数组，它描述了网格的列（对于 `LazyVGrid`）或行（对于 `LazyHGrid`）应该如何布局。

`GridItem` 是一个非常灵活的结构体，它允许你通过 `GridItem.Size` 来定义其尺寸：

*   **`.fixed(_:)`**: 创建一个具有固定尺寸的列/行。
*   **`.flexible(minimum:maximum:)`**: 创建一个灵活的列/行。它会与其他灵活的项平分可用空间，但你可以通过 `minimum` 和 `maximum` 参数来限制其尺寸范围。
*   **`.adaptive(minimum:maximum:)`**: 创建一个自适应的列/行。这是最强大的选项。你只需要指定一个最小尺寸，`Grid` 就会在可用空间内尽可能多地填充该项。例如，如果你指定 `minimum: 80`，在一个 390 点宽的屏幕上，它可能会自动创建 4 列。

### 示例：创建一个 `LazyVGrid`

```swift
import SwiftUI

struct LazyVGridExample: View {
    // 1. 定义列的布局规则
    // 创建一个自适应的网格，每个项目的最小宽度为 100
    let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 100))
    ]

    var body: some View {
        ScrollView {
            // 2. 创建 LazyVGrid
            LazyVGrid(columns: columns, spacing: 20) {
                // 3. 使用 ForEach 提供内容
                ForEach(0..<100) { index in
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue.opacity(0.7))
                        Text("Item \(index)")
                            .foregroundColor(.white)
                    }
                    .frame(height: 100)
                }
            }
            .padding()
        }
    }
}

#Preview {
    LazyVGridExample()
}
```

在这个例子中：
1.  我们定义了一个 `columns` 数组，其中包含一个 `.adaptive(minimum: 100)` 的 `GridItem`。这意味着 `LazyVGrid` 会自动计算在当前可用宽度下，可以容纳多少个最小宽度为 100 的列。
2.  `LazyVGrid` 被放置在一个 `ScrollView` 中以实现垂直滚动。
3.  `ForEach` 循环创建了 100 个项目，但只有当它们即将滚动到屏幕上时，它们才会被真正地创建和渲染。

### 示例：创建一个 `LazyHGrid`

`LazyHGrid` 的工作方式完全相同，只是方向变为了水平。

```swift
struct LazyHGridExample: View {
    // 1. 定义行的布局规则
    let rows: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView(.horizontal) { // 使用水平滚动视图
            LazyHGrid(rows: rows, spacing: 15) {
                ForEach(0..<100) { index in
                    Color.red
                        .frame(width: 80)
                }
            }
            .padding()
        }
        .frame(height: 300) // 必须为水平滚动视图提供一个确定的高度
    }
}
```

在这个例子中，我们定义了三行灵活高度的 `GridItem`，创建了一个三行高、可水平滚动的网格。

## `Grid` vs. `LazyVGrid`/`LazyHGrid`

| 特性 | `LazyVGrid` / `LazyHGrid` | `Grid` (iOS 16+) |
| :--- | :--- | :--- |
| **加载方式** | **懒加载 (Lazy)** | **立即加载 (Eager)** |
| **布局模型** | **一维** (只定义列或行) | **二维** (基于 `GridRow`) |
| **单元格合并** | 不支持 | **支持** (`.gridCellColumns`) |
| **性能** | **高**，适合大量数据。 | **中等**，适合有限数量的数据。 |
| **适用场景** | 可滚动的照片墙、商品列表。 | 非滚动的、需要精确对齐的表格状布局，如计算器。 |

## 固定页眉和页脚 (`Section`)

你可以在 `LazyVGrid` 或 `LazyHGrid` 中使用 `Section` 来为你的网格数据进行分组。`Section` 的 `header` 和 `footer` 在滚动时会自动“固定”（sticky）在屏幕的边缘，直到该 `Section` 的所有内容都滚出屏幕。

```swift
ScrollView {
    LazyVGrid(columns: columns) {
        Section(header: Text("Section 1").font(.largeTitle)) {
            ForEach(0..<20) { ... }
        }
        
        Section(header: Text("Section 2").font(.largeTitle)) {
            ForEach(20..<40) { ... }
        }
    }
}
```

## 总结

`LazyVGrid` 和 `LazyHGrid` 是 SwiftUI 中用于构建高性能、可滚动网格布局的核心工具。

*   **懒加载**: 它们的核心优势在于其“懒加载”特性，只在需要时才创建视图，极大地优化了处理大量数据时的性能和内存使用。
*   **`GridItem`**: 通过定义一个 `GridItem` 数组，你可以灵活地控制列（`LazyVGrid`）或行（`LazyHGrid`）的尺寸和行为（固定、灵活或自适应）。
*   **滚动**: 它们必须被放置在一个相应方向的 `ScrollView` 中才能滚动。
*   **分组**: 支持使用 `Section` 来进行数据分组，并提供固定的页眉/页脚。

当你需要以网格形式展示一个可能包含大量项目的数据集合时，`LazyVGrid` 和 `LazyHGrid` 是你的不二之选。
