# SwiftUI Table：行的选择

在 SwiftUI 的 `Table` 组件中，允许用户选择一行或多行是实现交互式数据管理的基础。`Table` 提供了对单选和多选的内置支持，其实现方式与 `List` 非常相似，都是通过一个 `selection` 绑定来与一个状态变量进行同步。

这个功能在 macOS 和 iPadOS 上尤其重要，因为用户期望能够选中表格中的项目，然后执行如“查看详情”、“删除”、“导出”等操作。

## 核心用法：`selection` 绑定

要为 `Table` 启用选择功能，你需要在初始化 `Table` 时，为其 `selection` 参数提供一个 `@State` 变量的绑定。根据你希望实现单选还是多选，这个状态变量的类型会有所不同。

### 1. 单行选择

要实现单行选择，你需要将 `selection` 绑定到一个**可选的**、与你的数据模型 `ID` 类型相同的状态变量。

*   当没有行被选中时，该变量的值为 `nil`。
*   当某一行被选中时，该变量的值会更新为该行的 `ID`。

```swift
import SwiftUI

struct FileItem: Identifiable { ... }

struct SingleSelectionTable: View {
    @State private var items: [FileItem] = ...
    // 1. 声明一个可选的 ID 类型变量用于单选
    @State private var selectedItemID: FileItem.ID?

    var body: some View {
        VStack {
            Text("当前选中: \(selectedItemID?.uuidString ?? "无")")
            
            // 2. 将 selection 绑定到 $selectedItemID
            Table(items, selection: $selectedItemID) {
                TableColumn("文件名", value: \.name)
                TableColumn("大小", value: \.size) { ... }
            }
        }
    }
}
```

在这个例子中，当用户点击表格中的某一行时，`selectedItemID` 的值会自动更新为该行的 `id`。如果用户再次点击该行（或根据平台行为取消选择），`selectedItemID` 会变回 `nil`。

### 2. 多行选择

要实现多行选择，你需要将 `selection` 绑定到一个**`Set`**，该 `Set` 的元素类型是你数据模型的 `ID` 类型。

*   这个 `Set` 会存储所有当前被选中行的 `ID`。

```swift
struct MultiSelectionTableExample: View {
    @State private var items: [FileItem] = ...
    // 1. 声明一个 Set<ID> 类型的变量用于多选
    @State private var selectedItemIDs = Set<FileItem.ID>()

    var body: some View {
        VStack {
            Text("已选中 \(selectedItemIDs.count) 个项目")
            
            // 2. 将 selection 绑定到 $selectedItemIDs
            Table(items, selection: $selectedItemIDs) {
                TableColumn("文件名", value: \.name)
                TableColumn("种类", value: \.kind)
            }
        }
        .toolbar {
            // 3. EditButton 会自动启用/禁用多选模式
            EditButton()
        }
        .navigationTitle("文件列表")
    }
}

#Preview {
    NavigationView { // EditButton 需要在 NavigationView 中
        MultiSelectionTableExample()
    }
}
```

在这个例子中：
*   `selectedItemIDs` 集合存储了所有被选中行的 `ID`。
*   在 macOS 上，用户可以通过按住 `Cmd` 键来点选多个不连续的行，或者按住 `Shift` 键来选择一个连续的范围。
*   `EditButton` 提供了一个标准的方式来进入和退出“编辑模式”。在编辑模式下，多选行为会变得更加明确（例如，在行的左侧可能会出现复选框）。

## 响应选择的变化

你可以使用 `.onChange(of: selection)` 修饰符来观察选择状态的变化，并执行相应的逻辑，例如在详情视图中显示选中项目的信息。

```swift
.onChange(of: selectedItemIDs) { newSelection in
    print("当前选中的 ID 数量: \(newSelection.count)")
    // 在这里可以更新详情视图或执行其他操作
}
```

## 与 `NavigationSplitView` 结合

`Table` 的选择功能与 `NavigationSplitView` 结合使用时，威力最大。你可以将表格作为 `sidebar` 或 `content` 视图，并将 `selection` 绑定传递给 `detail` 视图，以构建经典的主从界面。

```swift
struct SplitViewTableSelection: View {
    @State private var items: [FileItem] = ...
    @State private var selectedItemID: FileItem.ID?

    var body: some View {
        NavigationSplitView {
            // 侧边栏：表格
            Table(items, selection: $selectedItemID) {
                TableColumn("文件名", value: \.name)
            }
        } detail: {
            // 详情视图：根据选择显示内容
            if let selectedID = selectedItemID,
               let item = items.first(where: { $0.id == selectedID }) {
                FileDetailView(item: item)
            } else {
                Text("请选择一个文件")
            }
        }
    }
}
```

## 总结

为 `Table` 添加行选择功能是构建交互式桌面级应用的关键一步。

*   **核心 API**: `Table` 的 `selection` 参数。
*   **单选**: 绑定到一个可选的 `ID` 变量 (`Optional<Item.ID>`)。
*   **多选**: 绑定到一个 `ID` 的集合 (`Set<Item.ID>`)。
*   **交互**: 在 macOS 上，多选行为符合平台标准（`Cmd`+Click, `Shift`+Click）。`EditButton` 可以用来显式地进入/退出编辑模式。
*   **最佳实践**: 将 `Table` 的 `selection` 与 `NavigationSplitView` 的 `detail` 视图结合，是构建主从界面的标准模式。

通过 `selection` 绑定，SwiftUI 以一种简洁、数据驱动的方式，为你处理了所有复杂的选择状态管理和 UI 更新逻辑。
