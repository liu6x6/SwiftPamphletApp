# SwiftUI Table：上下文菜单 (Context Menu)

在 `Table`（表格）中，为行或单元格提供上下文相关的快捷操作是一种非常常见的需求。与 `List` 类似，你可以使用 `.contextMenu()` 修饰符来为 `Table` 的行添加一个上下文菜单。在 macOS 上，这通常通过**右键单击**来触发；在 iPadOS 上，则通过**长按**来触发。

## 核心用法：`.contextMenu()`

你可以将 `.contextMenu()` 修饰符直接附加到 `Table` 的行视图上。在它的 `menuItems` 闭包中，你可以定义一系列 `Button` 或 `Menu` 作为菜单项。

### 1. 为整行添加上下文菜单

最常见的方式是在 `ForEach` 循环中，为代表每一行的视图（例如 `TableRow` 或自定义的视图）附加 `.contextMenu`。

```swift
import SwiftUI

struct FileItem: Identifiable {
    let id = UUID()
    let name: String
    let size: Int
    let kind: String
}

struct TableContextMenuExample: View {
    @State private var items: [FileItem] = [
        .init(name: "Document.pdf", size: 1200, kind: "PDF Document"),
        .init(name: "Image.jpg", size: 2400, kind: "JPEG Image"),
        .init(name: "Archive.zip", size: 5600, kind: "ZIP Archive")
    ]
    
    @State private var selection = Set<FileItem.ID>()

    var body: some View {
        Table(items, selection: $selection) {
            TableColumn("文件名", value: \.name)
            TableColumn("大小", value: \.size) { item in
                Text("\(item.size / 1000) KB")
            }
            TableColumn("种类", value: \.kind)
        }
        .contextMenu(forSelectionType: FileItem.ID.self) { selectedIDs in
            // 当有选择时，为选中的项目提供操作
            if !selectedIDs.isEmpty {
                Button("打开") { handleOpen(ids: selectedIDs) }
                Button("显示简介") { /* ... */ }
                Divider()
                Button("删除", role: .destructive) { handleDelete(ids: selectedIDs) }
            }
        }
    }

    func handleOpen(ids: Set<FileItem.ID>) {
        let selectedItems = items.filter { ids.contains($0.id) }
        print("打开: \(selectedItems.map { $0.name })")
    }

    func handleDelete(ids: Set<FileItem.ID>) {
        items.removeAll { ids.contains($0.id) }
    }
}

#Preview {
    TableContextMenuExample()
}
```

在这个例子中，我们使用了 `Table` 的一个更高级的上下文菜单 API：`.contextMenu(forSelectionType:menuItems:primaryAction:)`。

*   **`forSelectionType`**: 你需要指定表格选择的 `ID` 类型。这使得 `contextMenu` 能够与 `Table` 的 `selection` 绑定进行交互。
*   **`menuItems` 闭包**: 这个闭包接收一个 `Set<ID>`，其中包含了当前所有被选中的行的 `ID`。
*   **动态菜单项**: 你可以根据 `selectedIDs` 是否为空，来决定是否显示菜单项。这可以防止在没有选中任何行的情况下，用户右键点击表头或空白区域时，仍然弹出无意义的菜单。

这种方式是为 `Table` 添加上下文菜单的**推荐做法**，因为它与多选（multi-select）行为完美集成。

### 2. 为单个单元格添加上下文菜单

虽然不太常见，但你也可以只为表格中的某个特定单元格（即某一列的视图）添加上下文菜单。

```swift
Table(items) {
    TableColumn("文件名") { item in
        Text(item.name)
            .contextMenu { // 只为“文件名”这个单元格添加菜单
                Button("拷贝文件名") { 
                    // ...
                }
            }
    }
    TableColumn("大小", value: \.size) { ... }
}
```

## `primaryAction`

`.contextMenu` 修饰符还有一个可选的 `primaryAction` 参数。它允许你定义一个当用户**直接**对选中的项目执行主要操作时（例如，在 macOS 上双击，或在 iPadOS 上单击）触发的行为。

```swift
.contextMenu(forSelectionType: FileItem.ID.self) { selectedIDs in
    // ... 菜单项
} primaryAction: { selectedIDs in
    // 当用户双击选中的行时，执行“打开”操作
    handleOpen(ids: selectedIDs)
}
```

这为用户提供了一个比打开上下文菜单再选择操作更快捷的交互路径。

## 总结

为 `Table` 添加上下文菜单是提升桌面级应用（macOS, iPadOS）用户体验的重要一环。SwiftUI 提供了强大而简洁的 API 来实现这一功能。

*   **核心修饰符**: `.contextMenu()`。
*   **推荐用法**: 使用 `.contextMenu(forSelectionType:menuItems:)`，它与 `Table` 的 `selection` 状态绑定，能够优雅地处理单选和多选情况下的上下文菜单。
*   **主要操作**: 利用 `primaryAction` 参数，可以为双击等直接操作定义一个快捷行为。
*   **语义化**: 在菜单项 `Button` 中使用 `.destructive` 等 `role`，可以让系统自动应用合适的样式。

通过为你的表格数据提供相关的上下文操作，你可以让你的应用变得更高效、更符合用户的操作直觉。
