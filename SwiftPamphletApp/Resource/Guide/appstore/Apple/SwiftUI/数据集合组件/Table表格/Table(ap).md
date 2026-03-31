# SwiftUI 数据集合组件：Table (macOS & iPadOS)

`Table` 是 SwiftUI 在 iOS 16 和 macOS 12 中引入的一个强大的数据集合组件，专门用于以结构化的、多列的形式来展示数据。它非常适合用于构建需要显示大量、具有多个属性的数据的桌面级应用程序，例如文件浏览器、邮件客户端、或任何需要电子表格风格界面的场景。

与 `List` 不同，`Table` 天生就是为**多列数据**而设计的。

## 核心用法：`Table` 与 `TableColumn`

创建一个 `Table` 的核心是定义它的**列（Columns）**。你需要：

1.  **数据模型**: 一个遵循 `Identifiable` 协议的数据模型数组。
2.  **`Table` 容器**: 将你的数据数组传递给 `Table` 的初始化方法。
3.  **`TableColumn`**: 在 `Table` 的闭包中，为你希望展示的每一个数据属性，定义一个 `TableColumn`。

```swift
import SwiftUI

// 1. 定义数据模型
struct FileItem: Identifiable {
    let id = UUID()
    let name: String
    let size: Int
    let modificationDate: Date
}

struct BasicTableExample: View {
    // 示例数据
    @State private var items: [FileItem] = [
        .init(name: "Document.pdf", size: 1200, modificationDate: .now.addingTimeInterval(-100)),
        .init(name: "Image.jpg", size: 2400, modificationDate: .now.addingTimeInterval(-200)),
        .init(name: "Archive.zip", size: 5600, modificationDate: .now.addingTimeInterval(-50))
    ]

    var body: some View {
        // 2. 创建 Table 容器
        Table(items) {
            // 3. 定义每一列
            TableColumn("文件名", value: \.name)
            
            TableColumn("大小", value: \.size) { fileItem in
                // 为单元格提供自定义视图
                Text("\(fileItem.size / 1000) KB")
            }
            
            TableColumn("修改日期", value: \.modificationDate) { fileItem in
                Text(fileItem.modificationDate, style: .date)
            }
        }
    }
}

#Preview {
    BasicTableExample()
}
```

在这个例子中：
*   `Table(items)` 接收 `items` 数组作为数据源。
*   我们定义了三个 `TableColumn`。
*   对于“文件名”列，我们使用了最简单的 `TableColumn(_:value:)` 初始化方法。它接收一个列标题和一个指向 `String` 类型属性的 `KeyPath` (`\.name`)。`Table` 会自动为每一行显示该属性的文本。
*   对于“大小”和“修改日期”列，我们使用了带有 `content` 闭包的初始化方法。这允许我们为每个单元格提供一个完全自定义的 `View`，例如，将字节大小格式化为 KB，或将 `Date` 对象格式化为日期字符串。

## `Table` 的高级功能

`Table` 不仅仅是一个静态的展示工具，它还内置了丰富的、为桌面级应用设计的交互功能。

### 1. 排序 (`sortOrder`)

`Table` 支持按一列或多列进行排序。用户可以通过点击列表头来切换排序顺序。

你需要提供一个 `sortOrder` 状态绑定，并在其变化时对你的数据源进行排序。

```swift
@State private var sortOrder = [KeyPathComparator<FileItem>](\.name)

Table(items, sortOrder: $sortOrder) { ... }
    .onChange(of: sortOrder) {
        items.sort(using: sortOrder)
    }
```

（更多详情请参阅 `Table-多属性排序(ap).md`）

### 2. 选择 (`selection`)

`Table` 支持单选和多选。你需要提供一个 `selection` 状态绑定来存储被选中行的 `ID`。

```swift
@State private var selection = Set<FileItem.ID>()

Table(items, selection: $selection) { ... }
```

（更多详情请参阅 `Table-行的选择(ap).md`）

### 3. 层级数据 (大纲视图)

与 `List` 类似，`Table` 也可以通过 `children` Key Path 来显示具有层级关系的树状数据。

```swift
// 假设 FileItem 有一个 `children: [FileItem]?` 属性
Table(fileItems, children: \.children) { ... }
```

这会自动在具有子项的行旁边显示一个可折叠/展开的箭头。

## `Table` vs. `List`

| 特性 | `Table` | `List` |
| :--- | :--- | :--- |
| **布局** | **多列**，基于 `TableColumn`。 | **单列**，一行就是一个完整的视图。 |
| **主要平台** | **macOS, iPadOS** | **iOS**, macOS, iPadOS, watchOS |
| **核心功能** | 多列排序、列宽调整、列的重新排序。 | 滑动操作（`.swipeActions`）、下拉刷新。 |
| **适用场景** | 显示结构化的、具有多个属性的数据，如电子表格、文件浏览器。 | 显示同质化的、单维度的项目列表，如邮件列表、设置菜单。 |

**选择建议**：
*   当你需要以**多列**形式展示数据，并提供排序、列宽调整等桌面级功能时，**必须使用 `Table`**。
*   当你只需要一个简单的、可滚动的**单列**列表时，使用 **`List`**。

## 总结

`Table` 是 SwiftUI 中用于构建功能丰富的、多列表格视图的专用组件，它填补了 `List` 在数据展示维度上的空白。

*   **多列布局**: 其核心是通过 `TableColumn` 来定义和展示数据的多个维度。
*   **桌面级交互**: 内置了对列排序、行选择、上下文菜单等桌面应用常见的交互功能的支持。
*   **平台优化**: 主要为 macOS 和 iPadOS 设计，提供了符合这些平台规范的原生外观和行为。

对于任何需要在 Mac 或 iPad 上开发数据密集型应用的 SwiftUI 开发者来说，`Table` 都是一个必须掌握的核心组件。
