# SwiftUI Table：拖拽操作 (Drag and Drop)

为 `Table` 添加拖拽（Drag and Drop）功能，可以极大地提升桌面级应用（macOS, iPadOS）的用户体验，让用户能够直观地对数据进行重新排序或在不同组件间传输数据。SwiftUI 通过 `.draggable()` 和 `.dropDestination()` 这一对现代化的修饰符，并结合 `Transferable` 协议，使得实现拖拽功能变得前所未有的简单和统一。

## 核心理念：`Transferable`

`Transferable` 协议是 SwiftUI 现代数据传输 API 的核心。任何遵循此协议的数据类型，都声明了它自己可以如何被“传输”。你需要定义你的数据可以被表示成哪些通用的、可序列化的格式。

对于拖拽操作，这意味着：
1.  **拖动源 (Drag Source)**: 当拖动开始时，遵循 `Transferable` 的对象会被编码成一种中间表示（例如 `Data`）。
2.  **放置目标 (Drop Destination)**: 当拖动结束、在目标区域释放时，系统会尝试将这个中间表示解码回原始的数据类型。

（更多详情请参阅 `视图组件/Transferable(ap).md`）

## 实现表格行重新排序

在 `Table` 中实现行的拖拽重新排序，通常需要结合使用 `.draggable()` 和 `.onMove` 或 `.onInsert`。

```swift
import SwiftUI
import UniformTypeIdentifiers

// 1. 确保数据模型遵循 Codable 和 Transferable
struct DraggableItem: Identifiable, Codable, Transferable {
    let id: Int
    let name: String
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .draggableItem)
    }
}

extension UTType {
    static let draggableItem = UTType(exportedAs: "com.example.draggable-item")
}

struct DraggableTableExample: View {
    @State private var items: [DraggableItem] = (
        (0..<10).map { DraggableItem(id: $0, name: "Item \($0)") }
    )
    @State private var draggedItem: DraggableItem? = nil

    var body: some View {
        Table(items) {
            TableColumn("ID", value: \.id) { Text("\($0.id)") }
            TableColumn("名称", value: \.name)
        }
        // 2. 使每一行都可拖动
        .draggable(items) { item in
            // 当拖动开始时，记录被拖动的项目
            draggedItem = item
            return NSItemProvider()
        }
        // 3. 定义放置行为
        .onDrop(of: [DraggableItem.self], isTargeted: nil) { providers, location in
            // ... 在这里处理放置逻辑 ...
            // 对于重新排序，更简单的方式是使用 .onMove
            return true
        }
    }
}

#Preview {
    DraggableTableExample()
}
```

**注意**: 虽然你可以使用 `.onDrop` 来手动实现重新排序的逻辑（通过计算 `location` 并更新数据源数组），但对于 `List` 和 `Table` 这种支持 `ForEach` 的视图，使用 `.onMove` 是一个更简单、更直接的方式。

### 结合 `.onMove` (更简单的方式)

`Table` 本身并不直接提供 `.onMove` 修饰符，但如果你的 `Table` 是基于 `ForEach` 构建的（这在自定义单元格时很常见），你就可以像在 `List` 中一样使用 `.onMove`。

对于 `Table`，更常见的交互模式不是在内部重新排序，而是与其他组件或应用进行数据交换。

## 实现拖拽到 `Table` (`.dropDestination`)

从 iOS 16 开始，`.dropDestination` 成为了处理放置操作的现代化 API。

```swift
struct DropDestinationTableExample: View {
    @State private var tableItems: [DraggableItem] = []
    @State private var isTargeted = false

    var body: some View {
        Table(tableItems) {
            TableColumn("ID", value: \.id) { Text("\($0.id)") }
            TableColumn("名称", value: \.name)
        }
        // 1. 定义为放置目标
        .dropDestination(for: DraggableItem.self) { droppedItems, location in
            // 2. 处理接收到的项目
            tableItems.append(contentsOf: droppedItems)
            return true // 返回 true 表示成功处理
        } isTargeted: { status in
            // 3. 当有可接收的项目拖动到上方时，改变外观
            isTargeted = status
        }
        .background(isTargeted ? Color.blue.opacity(0.2) : Color.clear)
    }
}
```

在这个例子中：
1.  `.dropDestination(for: DraggableItem.self, ...)` 声明了这个 `Table` 可以接收 `DraggableItem` 类型的数据。
2.  第一个闭包 `action` 在用户释放拖动时被调用。它接收一个包含所有被拖放进来的 `DraggableItem` 的数组，我们在这里将它们追加到表格的数据源中。
3.  第二个闭包 `isTargeted` 在有可接收的项目进入或离开 `Table` 的边界时被调用。我们可以用它来改变表格的外观（例如，显示一个高亮边框），向用户提供视觉反馈。

## 从 `Table` 拖出 (`.draggable`)

`.draggable()` 修饰符让 `Table` 中的行可以被拖动出去。

```swift
// 假设我们有一个可拖动的视图
struct DraggableView: View {
    let item: DraggableItem
    var body: some View {
        Text(item.name)
            .padding()
            .background(Color.mint)
            .cornerRadius(8)
            // 附加 .draggable 修饰符
            .draggable(item)
    }
}
```

你可以将这个 `DraggableView` 与上面的 `DropDestinationTableExample` 结合起来，实现从一个地方拖动项目到表格中的完整流程。

## 总结

SwiftUI 的 `Transferable` 协议和相关的 `.draggable` / `.dropDestination` 修饰符，为实现拖拽功能提供了一套统一、声明式且类型安全的 API。

*   **`Transferable` 是基础**: 确保你的数据模型遵循 `Transferable`（通常通过 `Codable`），这是让数据可被拖拽的前提。
*   **`.draggable`**: 使一个视图成为可拖动的源头。你只需要提供一个 `Transferable` 的数据实例。
*   **`.dropDestination`**: 使一个视图成为可以接收拖放的目标。你需要指定它可以接收的数据类型，并提供闭包来处理接收到的数据和高亮状态。

通过这套现代化的 API，你可以轻松地为你的 `Table` 甚至任何 SwiftUI 视图添加强大的拖拽交互，极大地提升了应用在桌面和 iPad 环境下的生产力和用户体验。
