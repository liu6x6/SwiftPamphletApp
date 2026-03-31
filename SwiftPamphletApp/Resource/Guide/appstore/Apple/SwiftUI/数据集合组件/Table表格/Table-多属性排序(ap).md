# SwiftUI Table：多属性排序

SwiftUI 的 `Table` 组件（主要用于 macOS 和 iPadOS）不仅支持按单个列进行排序，还支持更高级的、基于多个属性的**多级排序**。用户可以通过按住 `Shift` 键并点击多个列表头，来定义一个主排序规则和一个或多个次级排序规则。

例如，用户可以首先按“种类”排序，然后在每个种类内部，再按“修改日期”进行排序。

要实现这一功能，你需要利用 `Table` 的 `sortOrder` 绑定，并正确地处理 SwiftUI 传递给你的排序比较器数组。

## 核心用法：处理 `KeyPathComparator` 数组

实现多属性排序的步骤与单属性排序非常相似，但关键在于理解 `sortOrder` 绑定的值是一个数组：`[KeyPathComparator<Item>]`。

1.  **`sortOrder` 绑定**: 创建一个 `@State` 变量，其类型为 `[KeyPathComparator<Item>]`，并将其绑定到 `Table` 的 `sortOrder` 参数。这个数组的顺序代表了排序的优先级。
2.  **可比较的列**: 确保所有你希望可排序的列，其 `value` 都是一个可比较的 `KeyPath`。
3.  **`.onChange` 监听**: 监听 `sortOrder` 的变化。在闭包中，直接调用数组的 `.sort(using:)` 方法。Swift 标准库的这个方法已经重载，可以直接接收一个 `[KeyPathComparator]` 数组，并按顺序依次应用比较规则。

### 示例：按种类和名称排序

```swift
import SwiftUI

struct FileItem: Identifiable {
    let id = UUID()
    var name: String
    var kind: String
    var modificationDate: Date
}

struct MultiSortTableExample: View {
    @State private var items: [FileItem] = [
        .init(name: "Document.pdf", kind: "PDF", modificationDate: .now.addingTimeInterval(-100)),
        .init(name: "Image.jpg", kind: "Image", modificationDate: .now.addingTimeInterval(-200)),
        .init(name: "Spreadsheet.xlsx", kind: "Sheet", modificationDate: .now.addingTimeInterval(-50)),
        .init(name: "Photo.png", kind: "Image", modificationDate: .now.addingTimeInterval(-300)),
        .init(name: "Report.pdf", kind: "PDF", modificationDate: .now.addingTimeInterval(-150)),
    ]
    
    // 1. 定义 sortOrder 状态，可以设置一个默认的初始排序规则
    @State private var sortOrder = [KeyPathComparator<FileItem>](
        \.kind, // 主排序规则：按种类
        order: .forward
    )

    var body: some View {
        // 2. 将 sortOrder 绑定到 Table
        Table(items, sortOrder: $sortOrder) {
            // 3. 为所有可排序的列提供 KeyPath
            TableColumn("文件名", value: \.name)
            TableColumn("种类", value: \.kind)
            TableColumn("修改日期", value: \.modificationDate) { item in
                Text(item.modificationDate, format: .relative(presentation: .named))
            }
        }
        // 4. 监听 sortOrder 的变化
        .onChange(of: sortOrder) {
            // 5. 直接使用 sort(using:) 对数组进行排序
            items.sort(using: sortOrder)
        }
    }
}

#Preview {
    MultiSortTableExample()
}
```

### 交互流程

1.  **初始状态**: 列表默认按“种类”升序排列 (`.forward`)。
2.  **单击“文件名”**: 用户点击“文件名”列标题。`sortOrder` 的值会变为 `[KeyPathComparator(\.name)]`。`.onChange` 被触发，列表按文件名重新排序。
3.  **再次单击“文件名”**: 用户再次点击“文件名”列标题。`sortOrder` 的值会变为 `[KeyPathComparator(\.name, order: .reverse)]`。列表按文件名降序排列。
4.  **按住 `Shift` 并单击“种类”**: 假设当前是按“文件名”排序。用户按住 `Shift` 键，然后点击“种类”列标题。`sortOrder` 的值会变为 `[KeyPathComparator(\.name), KeyPathComparator(\.kind)]`。`.onChange` 被触发，`items.sort(using:)` 方法会：
    *   首先，按 `name` 排序。
    *   然后，对于 `name` 相同的项目（在这个例子中没有），再按 `kind` 排序。

`Array.sort(using:)` 方法会自动处理这个优先级逻辑，你无需手动编写复杂的比较闭包。

## `KeyPathComparator`

`KeyPathComparator` 是一个封装了 `KeyPath` 和排序顺序（`SortOrder.forward` 或 `SortOrder.reverse`）的结构体。`Table` 会在用户点击列表头时，自动创建和管理这个结构体的数组。

## 总结

SwiftUI 的 `Table` 通过 `sortOrder` 绑定和 `KeyPathComparator`，提供了一个非常强大且易于使用的多属性排序系统。

*   **声明式**: 你只需要声明你的排序列和排序状态，而无需关心用户交互的细节。
*   **数据驱动**: 排序的“真理之源”是 `@State` 的 `sortOrder` 数组。
*   **强大的标准库支持**: `Array.sort(using:)` 方法可以直接消费 `[KeyPathComparator]` 数组，极大地简化了多级排序的实现逻辑。

通过这种方式，你可以轻松地为你的桌面级应用提供用户所期望的、功能完善的表格排序体验。
