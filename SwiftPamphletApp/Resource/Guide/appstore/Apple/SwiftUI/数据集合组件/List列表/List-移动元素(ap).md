# SwiftUI List：移动行 (Moving Rows)

SwiftUI 的 `List` 提供了一种内置的、交互式的方式来让用户重新排列列表中的行。这通过一个简单的 `.onMove` 修饰符来实现，它通常与 `EditButton` 结合使用，让列表进入和退出“编辑”模式。

## 核心用法：`EditButton` 与 `.onMove`

要实现行的移动，你需要做两件事：

1.  **`EditButton`**: 在导航栏或工具栏中添加一个 `EditButton`。这是一个由 SwiftUI 提供的特殊按钮，它会自动管理列表的编辑状态（在“编辑”和“完成”之间切换）。
2.  **`.onMove(perform:)`**: 将这个修饰符附加到 `List` 内的 `ForEach` 上。它提供一个闭包，当用户完成一次移动操作后，这个闭包会被调用。

`onMove` 的闭包会接收两个参数：
*   `source`: 一个 `IndexSet`，包含了被移动的行在**原始**数据源中的索引。
*   `destination`: 一个 `Int`，表示这些行被移动到的**目标**位置的索引。

你的任务是在这个闭包中，根据这两个参数来更新你的数据源数组。

```swift
import SwiftUI

struct MovableListExample: View {
    @State private var fruits = ["Apple", "Banana", "Cherry", "Date", "Elderberry"]

    var body: some View {
        NavigationView {
            List {
                // 1. 将 .onMove 附加到 ForEach 上
                ForEach(fruits, id: \.self) { fruit in
                    Text(fruit)
                }
                .onMove(perform: moveItems)
            }
            .navigationTitle("可移动的列表")
            .toolbar {
                // 2. 添加 EditButton 来切换编辑模式
                EditButton()
            }
        }
    }

    // 3. 实现移动逻辑的函数
    func moveItems(from source: IndexSet, to destination: Int) {
        // 直接使用数组的 move 方法来更新数据源
        fruits.move(fromOffsets: source, toOffset: destination)
    }
}

#Preview {
    MovableListExample()
}
```

在这个例子中：
1.  我们在 `ForEach` 上附加了 `.onMove(perform: moveItems)`。
2.  我们在 `toolbar` 中添加了一个 `EditButton`。
3.  当用户点击“编辑”按钮后，`List` 会进入编辑模式，每一行的右侧都会出现一个可供拖动的“汉堡”图标。
4.  当用户拖动一行并将其放置到新的位置后，`moveItems` 函数会被调用。
5.  `fruits.move(fromOffsets:toOffset:)` 是 Swift `Array` 的一个便捷方法，它会根据 `source` 和 `destination` 索引，自动地、安全地重新排列数组中的元素。
6.  因为 `fruits` 是一个 `@State` 变量，所以当它的顺序改变时，`List` 会自动更新以反映新的顺序。

## 与 `.onDelete` 结合

`.onMove` 通常与 `.onDelete`（用于实现滑动删除）结合使用，以提供一个完整的列表编辑体验。

```swift
List {
    ForEach(items) { item in
        Text(item.name)
    }
    .onDelete(perform: deleteItems)
    .onMove(perform: moveItems)
}
.toolbar {
    EditButton()
}
```

当列表进入编辑模式时，每一行的左侧会出现一个删除按钮，右侧会出现一个移动句柄，用户可以同时进行这两种操作。

## 注意事项

*   **`ForEach` 是关键**: `.onMove` 和 `.onDelete` 都必须被附加到 `List` **内部**的 `ForEach` 上，而不是 `List` 本身。这是因为这些操作是直接与 `ForEach` 的动态数据源相关联的。
*   **数据源必须是可变的**: 你用来构建 `ForEach` 的数据集合必须是可变的（通常是一个 `@State` 数组），因为 `onMove` 闭包需要修改它。
*   **`EditButton`**: 虽然你也可以通过一个自定义的 `@State` 布尔值和一个普通 `Button` 来手动管理编辑状态（通过 `@Environment(\.editMode)`），但使用 `EditButton` 是最简单、最标准的方式，因为它为你处理了所有的状态切换逻辑。

## 总结

SwiftUI 通过 `.onMove` 修饰符和 `EditButton`，将原本在 `UIKit` 中需要通过 `UITableViewDataSource` 的多个代理方法才能实现的复杂行移动功能，简化为了一个极其简单、声明式的 API。

*   **触发**: 使用 `EditButton` 进入编辑模式。
*   **实现**: 在 `ForEach` 上附加 `.onMove` 修饰符。
*   **逻辑**: 在 `onMove` 的闭包中，调用数组的 `.move(fromOffsets:toOffset:)` 方法来更新你的数据源。

通过这种方式，你可以轻松地为你的应用添加列表项重新排序的功能，为用户提供更强的自定义和管理能力。
