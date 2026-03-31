# SwiftUI 数据集合组件：Grid (iOS 16+)

`Grid` 是苹果在 WWDC 2022 (iOS 16) 中引入的一个强大的二维布局容器。与 `LazyVGrid` 和 `LazyHGrid` 不同，`Grid` 是一个**非懒加载**的、功能更丰富的网格系统，它允许你创建更复杂、更具结构化的对齐布局，非常适合用于构建如计算器、棋盘、或需要精确对齐的仪表盘等界面。

## 核心概念：`Grid` 与 `GridRow`

`Grid` 的布局模型更像是传统的 HTML `<table>`。它的内容由一行一行的 `GridRow` 组成。

1.  **`Grid`**: 顶层容器，负责整体的对齐和间距。
2.  **`GridRow`**: 代表网格中的一行。在 `GridRow` 内部，你放置的每个视图都会被视为一个独立的单元格（cell）。

`Grid` 会自动计算所有行中，每一列的最大宽度，并确保所有单元格都与该列的宽度对齐，从而创建出整洁的、表格状的布局。

## 基本用法

```swift
import SwiftUI

struct BasicGridExample: View {
    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 10) {
            // 第一行
            GridRow {
                Text("姓名:")
                Text("John Appleseed")
            }
            
            Divider()
            
            // 第二行
            GridRow {
                Text("职位:")
                Text("iOS Developer and SwiftUI Enthusiast")
                    .multilineTextAlignment(.leading)
            }
        }
        .padding()
    }
}

#Preview {
    BasicGridExample()
}
```

在这个例子中：
*   `Grid` 容器定义了所有单元格的对齐方式和间距。
*   每个 `GridRow` 包含两个 `Text` 视图，它们分别构成了第一列和第二列。
*   注意第二行的“职位”内容非常长，`Grid` 会自动测量所有行中第二列内容的最大宽度，并为 `Text("John Appleseed")` 分配同样多的空间，从而实现了标签和内容的完美对齐。

## 单元格合并 (`.gridCellColumns`)

`Grid` 最强大的功能之一是允许单元格跨越多列，类似于 HTML `<table>` 中的 `colspan` 属性。这通过 `.gridCellColumns()` 修饰符来实现。

```swift
struct CellMergingExample: View {
    var body: some View {
        Grid {
            GridRow {
                Text("左")
                Text("中")
                Text("右")
            }
            .font(.headline)
            
            Divider()
            
            GridRow {
                // 这个 Color 视图会占据两列的空间
                Color.red
                    .frame(height: 50)
                    .gridCellColumns(2)
                
                Text("右")
            }
            
            GridRow {
                Text("左")
                
                // 这个 Color 视图会占据三列的空间
                Color.blue
                    .frame(height: 50)
                    .gridCellColumns(3) // 注意：这会导致这一行超出 Grid 的列数
            }
        }
        .padding()
    }
}

#Preview {
    CellMergingExample()
}
```

## 单元格偏移与占位 (`.gridColumnAlignment` & `GridCell.empty`)

*   **`.gridColumnAlignment()`**: 你可以为 `GridRow` 中的某个特定单元格覆盖其父 `Grid` 的对齐方式。

*   **`GridCell.empty`**: (iOS 17+) 提供了一个方便的方式来创建一个空的占位单元格，这在需要创建不规则的、交错的网格布局时非常有用。

```swift
Grid {
    GridRow {
        Text("左对齐")
            .gridColumnAlignment(.leading)
        Text("居中")
            .gridColumnAlignment(.center)
        Text("右对齐")
            .gridColumnAlignment(.trailing)
    }
    
    GridRow {
        GridCell.empty // 第一个单元格是空的
        Text("第二列")
        Text("第三列")
    }
}
```

## `Grid` vs. `LazyVGrid`/`LazyHGrid`

| 特性 | `Grid` | `LazyVGrid` / `LazyHGrid` |
| :--- | :--- | :--- |
| **加载方式** | **立即加载 (Eager)**。一次性创建和渲染所有子视图。 | **懒加载 (Lazy)**。只在视图即将进入屏幕时才创建和渲染。 |
| **布局模型** | **二维**。基于 `GridRow`，可以精确控制行和列。 | **一维**。你只定义列（`LazyVGrid`）或行（`LazyHGrid`）的规则，系统会自动换行。 |
| **单元格合并** | **支持** (`.gridCellColumns`)。 | **不支持**。 |
| **性能** | 适用于**有限数量**的、需要复杂对齐的子视图。 | 适用于**大量**（成百上千个）子视图的、可滚动的场景。 |
| **适用场景** | 计算器、棋盘、结构化的信息表单。 | 照片墙、商品列表、任何需要滚动的网格。 |

**选择建议**：
*   当你需要一个可滚动的、包含大量项目的网格时，使用 **`LazyVGrid`** 或 **`LazyHGrid`**。
*   当你需要一个非滚动的、项目数量有限的、但需要精确的二维对齐和单元格合并功能的表格状布局时，使用 **`Grid`**。

## 总结

`Grid` 是 SwiftUI (iOS 16+) 中一个用于构建结构化二维布局的强大容器。

*   **核心结构**: 由 `Grid` 容器和 `GridRow` 组成，创建出类似表格的布局。
*   **自动对齐**: 能够自动对齐不同行中对应列的单元格，非常适合创建整洁的表单和信息展示。
*   **单元格合并**: 通过 `.gridCellColumns()` 可以实现复杂的、跨越多列的布局。
*   **非懒加载**: 它会一次性加载所有内容，因此只适合用于项目数量有限的场景。

通过 `Grid`，SwiftUI 开发者终于有了一个官方的、强大的工具来处理以往需要复杂计算和 `alignmentGuide` 才能实现的表格和对齐布局，极大地丰富了 SwiftUI 的布局能力。
