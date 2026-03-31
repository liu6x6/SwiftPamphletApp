# SwiftUI 数据集合组件：List

`List` 是 SwiftUI 中用于显示一行行、可滚动的、垂直数据的核心组件。它在功能上类似于 `UIKit` 中的 `UITableView`，但提供了更简单、更具声明性的 API。`List` 能够高效地处理从少量静态行到成千上万个动态行的各种场景。

## 核心用法

`List` 的核心是与数据集合进行交互。它通常与 `ForEach` 结合使用，来根据一个数据数组动态地创建行。

### 1. 静态列表

对于少量、固定的行，你可以直接在 `List` 闭包中放置视图。

```swift
import SwiftUI

struct StaticListExample: View {
    var body: some View {
        List {
            Text("第一行")
            Text("第二行")
            Label("第三行", systemImage: "star")
        }
    }
}
```

### 2. 动态列表

对于动态数据，你需要提供一个遵循 `Identifiable` 协议的数据模型，或者在 `ForEach` 中为每个元素提供一个唯一的 `id`。

```swift
struct Fruit: Identifiable {
    let id = UUID()
    let name: String
}

struct DynamicListExample: View {
    let fruits = [Fruit(name: "Apple"), Fruit(name: "Banana"), Fruit(name: "Cherry")]

    var body: some View {
        // List 提供了一个便捷的初始化方法，它隐式地创建了一个 ForEach
        List(fruits) { fruit in
            Text(fruit.name)
        }
    }
}
```

## `List` 的高级功能

`List` 不仅仅是一个简单的滚动列表，它还内置了许多强大的功能。

### 1. 分组 (`Section`)

你可以使用 `Section` 将列表内容分成逻辑上的组，并为每个组提供一个页眉（`header`）和页脚（`footer`）。

```swift
List {
    Section(header: Text("水果")) {
        Text("Apple")
        Text("Banana")
    }
    Section(header: Text("蔬菜")) {
        Text("Carrot")
        Text("Broccoli")
    }
}
```

### 2. 选择 (`selection`)

`List` 支持单选和多选。你需要提供一个 `@State` 变量来存储当前选中的项目。

*   **单选**: 绑定到一个可选的、与数据 `id` 类型相同的状态变量。
*   **多选**: 绑定到一个 `Set` 类型的状态变量。

```swift
struct SelectionListExample: View {
    @State private var fruits = ["Apple", "Banana", "Cherry"]
    @State private var selectedFruit: String? // 单选
    @State private var multiSelection = Set<String>() // 多选

    var body: some View {
        VStack {
            // 多选示例
            List(fruits, id: \.self, selection: $multiSelection) {
                Text($0)
            }
        }
        .navigationTitle("选择列表")
        .toolbar { EditButton() } // EditButton 会自动启用多选模式
    }
}
```

### 3. 行操作

`List` 支持丰富的行级交互。

*   **删除**: 使用 `.onDelete(perform:)` 来实现滑动删除。
*   **移动**: 使用 `.onMove(perform:)` 来实现行的重新排序。
*   **轻扫操作**: 使用 `.swipeActions()` (iOS 15+) 来添加自定义的滑动操作按钮（如“收藏”、“标记为已读”）。

```swift
List {
    ForEach(items) { item in
        Text(item.name)
    }
    .onDelete(perform: deleteItems)
    .onMove(perform: moveItems)
}
```

### 4. 大纲视图 (层级列表)

`List` 支持显示具有层级关系的树状数据，并自动提供可折叠/展开的功能。

```swift
// 假设 FileItem 有一个 `children: [FileItem]?` 属性
List(fileItems, children: \.children) { item in
    Text(item.name)
}
```

### 5. 搜索

使用 `.searchable()` (iOS 15+) 可以轻松地为 `List` 添加一个搜索框。

```swift
List(searchResults) { ... }
    .searchable(text: $searchText)
```

### 6. 下拉刷新

使用 `.refreshable()` (iOS 15+) 可以为 `List` 添加原生的下拉刷新功能。

```swift
List(items) { ... }
    .refreshable { 
        await loadData()
    }
```

## `List` vs. `ScrollView` + `LazyVStack`

| 特性 | `List` | `ScrollView` + `LazyVStack` |
| :--- | :--- | :--- |
| **样式** | **平台特定**。自动应用行分隔线、内边距、分组样式等。 | **完全自定义**。没有任何默认样式，你需要自己添加所有视觉元素。 |
| **功能** | **内置丰富功能**：选择、删除、移动、轻扫操作、大纲视图。 | **无内置功能**。只提供滚动能力，所有交互都需要手动实现。 |
| **适用场景** | *   设置页面 (`Form` 是 `List` 的一种特殊形式)
*   邮件列表、通讯录等需要标准行交互的场景。
*   任何需要快速构建一个具有平台原生观感的列表时。 | *   需要完全自定义行外观和布局的场景。
*   创建非传统的、不遵循标准列表样式的滚动内容。 |

**选择建议**：
*   当你需要一个“列表”时，**优先使用 `List`**。它为你处理了大量的工作，并确保你的应用符合平台的设计规范。
*   只有当你发现 `List` 的样式或功能限制了你的设计，并且你需要对布局和外观进行完全的、像素级的控制时，才回退到使用 `ScrollView` + `LazyVStack` 的组合。

## 总结

`List` 是 SwiftUI 中用于展示集合数据的核心组件，它远不止是一个简单的滚动 `VStack`。

*   **数据驱动**: 通过 `ForEach` 高效地显示动态数据。
*   **功能丰富**: 内置了选择、编辑（删除/移动）、层级大纲、搜索、下拉刷新等大量高级功能。
*   **样式化**: 通过 `.listStyle()` 和一系列行级修饰符，可以轻松定制其外观。
*   **语义化**: 使用 `List` 而不是 `ScrollView`，向 SwiftUI 和系统提供了更清晰的语义信息，有助于可访问性等功能的实现。

熟练掌握 `List` 及其丰富的 API，是构建任何数据驱动的 SwiftUI 应用的关键一步。
