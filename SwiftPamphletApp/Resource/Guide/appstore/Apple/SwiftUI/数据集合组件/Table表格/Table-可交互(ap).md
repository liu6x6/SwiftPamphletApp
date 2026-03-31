# SwiftUI Table：交互性

SwiftUI 的 `Table` 不仅仅是一个静态的数据展示工具，它还内置了丰富的交互功能，特别是在 macOS 和 iPadOS 上，可以创建出功能完善的、桌面级的应用体验。这些交互主要围绕着**选择（Selection）**、**排序（Sorting）**和**上下文操作（Contextual Actions）**展开。

## 1. 行选择 (`selection`)

`Table` 支持单选和多选。你需要为 `Table` 的 `selection` 参数提供一个绑定，用于存储当前选中的行的 `ID`。

*   **单选**: 将 `selection` 绑定到一个**可选的** `ID` 类型变量 (`@State private var selection: Item.ID?`)。
*   **多选**: 将 `selection` 绑定到一个**`Set`** 类型的 `ID` 变量 (`@State private var selection = Set<Item.ID>()`)。

```swift
import SwiftUI

struct FileItem: Identifiable { ... }

struct SelectableTableExample: View {
    @State private var items: [FileItem] = ...
    // 1. 创建一个 Set 来存储多选的 ID
    @State private var selection = Set<FileItem.ID>()

    var body: some View {
        VStack {
            Text("已选中 \(selection.count) 个项目")
            
            // 2. 将 selection 绑定到 Table
            Table(items, selection: $selection) {
                TableColumn("文件名", value: \.name)
                TableColumn("大小", value: \.size) { ... }
            }
        }
        .toolbar {
            // 3. EditButton 会自动启用/禁用多选模式
            EditButton()
        }
    }
}
```

在这个例子中：
*   `selection` 状态变量存储了所有被选中行的 `ID`。
*   当用户在表格中点击（或按住 `Cmd`/`Shift` 点击）不同的行时，`selection` 集合会自动更新。
*   `EditButton` 会在导航栏中添加一个“编辑/完成”按钮，它会自动切换表格的选择模式。

## 2. 排序 (`sortOrder`)

`Table` 提供了内置的列排序功能。用户可以通过点击列标题来对表格数据进行排序。

要启用排序，你需要：
1.  **`sortOrder` 绑定**: 创建一个 `@State` 变量，其类型为 `[KeyPathComparator<Item>]`，并将其绑定到 `Table` 的 `sortOrder` 参数。
2.  **可比较的列**: 对于你希望可排序的列，使用 `TableColumn` 的 `value` 初始化方法，并传入一个可比较的 `KeyPath`。
3.  **`.onChange` 监听**: 使用 `.onChange(of: sortOrder)` 来监听排序规则的变化，并在闭包中调用数组的 `.sort(using:)` 方法来实际地对你的数据源进行排序。

```swift
struct SortableTableExample: View {
    @State private var items: [FileItem] = ...
    // 1. 创建 sortOrder 状态变量
    @State private var sortOrder = [KeyPathComparator<FileItem>](
        \.name, // 默认按文件名升序排序
        order: .forward
    )

    var body: some View {
        // 2. 将 sortOrder 绑定到 Table
        Table(items, sortOrder: $sortOrder) {
            // 3. 为可排序的列提供 KeyPath
            TableColumn("文件名", value: \.name)
            TableColumn("大小", value: \.size) { ... }
            TableColumn("种类", value: \.kind)
        }
        // 4. 监听 sortOrder 的变化并执行排序
        .onChange(of: sortOrder) {
            items.sort(using: sortOrder)
        }
    }
}
```

在这个例子中：
*   `sortOrder` 状态变量存储了当前的排序规则数组（可以按多个列进行排序）。
*   当用户点击“文件名”或“大小”等列的标题时，`sortOrder` 的值会自动更新。
*   `.onChange` 闭包被触发，并调用 `items.sort(using: sortOrder)` 来对数据进行重新排序，`Table` 随之刷新。

## 3. 上下文菜单 (`.contextMenu`)

你可以为表格的行提供一个上下文菜单，以便用户通过右键单击（macOS）或长按（iPadOS）来执行快捷操作。

推荐使用 `.contextMenu(forSelectionType:menuItems:primaryAction:)` 修饰符，因为它能很好地与表格的选择状态集成。

```swift
Table(items, selection: $selection) { ... }
    .contextMenu(forSelectionType: FileItem.ID.self) { selectedIDs in
        // 只有当有项目被选中时才显示菜单
        if !selectedIDs.isEmpty {
            Button("打开") { handleOpen(ids: selectedIDs) }
            Button("删除", role: .destructive) { handleDelete(ids: selectedIDs) }
        }
    } primaryAction: { selectedIDs in
        // 定义双击等主要操作
        handleOpen(ids: selectedIDs)
    }
```

（更多详情请参阅 `Table-contextMenu(ap).md`）

## 4. 拖放 (`.draggable` & `.dropDestination`)

`Table` 的行可以作为拖放操作的源头或目的地。

*   **`.draggable()`**: 让行可以被拖动。你需要提供一个 `Transferable` 对象。
*   **`.dropDestination()`**: 让表格可以接收拖放进来的项目。

```swift
// 假设 FileItem 遵循 Transferable
Table(items) {
    TableColumn("文件名", value: \.name)
        .width(min: 150)
}
.onInsert(of: [FileItem.self]) { index, newItems in
    // 处理拖放插入的逻辑
    items.insert(contentsOf: newItems, at: index)
}
```

## 总结

SwiftUI 的 `Table` 不仅仅是一个静态的数据网格，它是一个功能齐全的、为桌面级应用设计的交互式组件。

*   **选择**: 通过 `selection` 绑定，轻松实现单选和多选。
*   **排序**: 通过 `sortOrder` 绑定和 `.onChange`，可以为任意可比较的列添加内置的、多级的排序功能。
*   **上下文操作**: 通过 `.contextMenu`，可以为选中的行提供丰富的快捷操作。
*   **拖放**: 与 SwiftUI 的 `Transferable` 体系无缝集成，轻松实现拖放功能。

通过组合使用这些交互功能，你可以构建出功能强大、用户体验媲美原生桌面应用的表格数据展示和管理界面。
