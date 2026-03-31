# SwiftUI List：大纲视图 (Outline Group)

在 SwiftUI 中，`List` 不仅能显示简单的单层列表，还支持创建具有层级关系的、可折叠的**大纲视图**（Outline View）。这种视图在 macOS 上非常常见（例如“访达”的文件目录），在 iOS 上也常用于显示树状结构的数据，如文件系统、组织架构或带有多级子任务的待办事项列表。

创建大纲视图的核心是使用一个特殊的 `List` 初始化方法，该方法接收一个可以递归地描述子节点的数据源。

## 核心用法：树状数据与 `children`

要创建一个大纲视图，你需要：

1.  **一个树状的数据模型**: 你的数据模型需要能够表示层级关系。通常，这意味着每个数据项都有一个可选的、包含其子项的数组。这个子项数组的类型必须与父项的类型相同。
2.  **一个特殊的 `List` 初始化方法**: `List(_:children:rowContent:)`。
    *   `data`: 你的数据源的顶层项目数组。
    *   `children`: 一个关键路径（Key Path），指向数据模型中代表其子项的那个可选数组。
    *   `rowContent`: 一个闭包，用于为每个数据项创建其对应的行视图。

### 示例：创建一个文件目录浏览器

```swift
import SwiftUI

// 1. 定义一个可递归的、Identifiable 的数据模型
struct FileItem: Identifiable {
    let id = UUID()
    let name: String
    // `children` 属性存储了子项目，其类型是自身的可选数组
    let children: [FileItem]?
}

// 创建示例数据
let fileHierarchyData: [FileItem] = [
    FileItem(name: "用户", children: [
        FileItem(name: "文档", children: [
            FileItem(name: "ProjectA.swift", children: nil),
            FileItem(name: "ProjectB.swift", children: nil)
        ]),
        FileItem(name: "下载", children: nil),
        FileItem(name: "图片", children: [
            FileItem(name: "photo1.jpg", children: nil)
        ])
    ]),
    FileItem(name: "应用程序", children: nil)
]

struct OutlineGroupExample: View {
    var body: some View {
        // 2. 使用特殊的 List 初始化方法
        List(fileHierarchyData, children: \.children) { item in
            // 3. 为每个 item 创建行视图
            if item.children != nil {
                // 如果有子项，显示一个文件夹图标
                Label(item.name, systemImage: "folder.fill")
            } else {
                // 如果没有子项，显示一个文件图标
                Label(item.name, systemImage: "doc.text")
            }
        }
        .navigationTitle("文件系统")
    }
}

#Preview {
    NavigationView { // List 的大纲样式在 NavigationView 中效果最佳
        OutlineGroupExample()
    }
}
```

在这个例子中：
1.  `FileItem` 结构体通过 `children: [FileItem]?` 属性来定义其层级关系。
2.  `List(fileHierarchyData, children: \.children)` 是关键。我们告诉 `List`：
    *   顶层的数据是 `fileHierarchyData` 数组。
    *   对于任何一个 `FileItem`，它的子项可以通过 `\.children` 这个 Key Path 来找到。
3.  SwiftUI 会自动地、递归地遍历这个树状数据结构。
4.  对于任何一个拥有非 `nil` 且非空 `children` 数组的 `item`，`List` 会自动在其旁边呈现一个可点击的**展开/折叠箭头**。

## `OutlineGroup`

除了直接在 `List` 中使用 `children` 参数，SwiftUI 还提供了一个更底层的视图构建器：`OutlineGroup`。

`OutlineGroup` 的工作方式与 `List` 的大纲模式非常相似，但它本身不提供 `List` 的滚动和行样式。它只是一个根据树状数据递归地生成视图的构建器。你可以将它放置在任何你想要的地方，例如一个可滚动的 `LazyVStack` 中。

```swift
ScrollView {
    LazyVStack(alignment: .leading) {
        OutlineGroup(fileHierarchyData, children: \.children) { item in
            Text(item.name).padding(.leading)
        }
    }
}
```

这为你提供了更大的自定义布局的灵活性。

## 总结

SwiftUI 的大纲视图功能，通过一个巧妙的 `List` 初始化方法，将复杂的树状数据结构优雅地转换为了一个可交互的、可折叠的层级列表。

*   **核心**: 一个**可递归的数据模型**（一个包含可选的、同类型子项数组的结构体）和一个特殊的 **`List(data:children:content:)`** 初始化方法。
*   **自动行为**: SwiftUI 会自动处理节点的展开/折叠状态，并显示相应的 UI（如箭头）。
*   **平台适应性**: 在 macOS 上，它会渲染成一个标准的、类似“访达”的大纲视图；在 iOS 上，它会渲染成一个带有缩进的、可折叠的列表。
*   **灵活性**: 对于更高级的自定义需求，可以使用 `OutlineGroup` 来在任何布局容器中递归地构建视图。

当你需要展示和操作具有层级关系的数据时，`List` 的大纲视图功能是 SwiftUI 提供的最直接、最高效的解决方案。
