# macOS 与 iPadOS 布局：三栏结构

三栏布局（Three-Column Layout）是桌面级和平板应用中一种非常经典、高效的导航和内容展示模式。它通常由以下三个垂直的栏目组成：

1.  **侧边栏 (Sidebar)**: 最左侧的栏目，用于显示顶级的导航项目，如文件夹、邮箱账户、或应用的主要功能模块。
2.  **主内容区 (Content)**: 中间的栏目，用于显示在侧边栏中选定项目的内容列表。例如，文件夹中的文件列表，或收件箱中的邮件列表。
3.  **详情区 (Detail)**: 最右侧的栏目，用于显示在主内容区中选定项目的详细信息。例如，一个文件的预览，或一封邮件的正文。

这种布局模式允许用户在保持导航上下文的同时，快速地在不同层级的信息之间进行浏览和切换。苹果的许多原生应用，如“邮件”、“访达”、“备忘录”和“快捷指令”，都广泛地使用了三栏布局。

## `NavigationSplitView`：SwiftUI 的标准答案 (iOS 16+)

从 iOS 16 和 macOS 13 开始，SwiftUI 提供了 `NavigationSplitView`，这是一个专门用于构建两栏和三栏布局的、现代化的导航容器。它完全取代了旧版 `NavigationView` 在这方面的功能，并提供了更强大、更可预测的 API。

### 核心用法

创建一个三栏布局的 `NavigationSplitView` 需要提供三个视图闭包：`sidebar`, `content`, 和 `detail`。

```swift
import SwiftUI

struct ThreeColumnLayoutExample: View {
    // 状态变量追踪每一栏的选择
    @State private var selectedCategoryId: Category.ID?
    @State private var selectedItemId: Item.ID?

    // 示例数据
    let categories: [Category] = ...

    var body: some View {
        NavigationSplitView {
            // 1. 侧边栏 (Sidebar)
            List(categories, selection: $selectedCategoryId) { category in
                Text(category.name).tag(category.id)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .navigationTitle("分类")
        } content: {
            // 2. 主内容 (Content)
            if let category = findCategory(id: selectedCategoryId) {
                List(category.items, selection: $selectedItemId) { item in
                    Text(item.name).tag(item.id)
                }
                .navigationTitle(category.name)
            } else {
                Text("请选择一个分类")
            }
        } detail: {
            // 3. 详情 (Detail)
            if let item = findItem(id: selectedItemId) {
                ItemDetailView(item: item)
            } else {
                Text("请选择一个项目")
            }
        }
    }
    
    // ... (findCategory 和 findItem 的辅助函数)
}
```

**工作流程**: 
1.  **侧边栏 (`sidebar`)**: 用户在最左侧的 `List` 中选择一个分类。`List` 的 `selection` 参数会自动更新 `@State` 变量 `selectedCategoryId`。
2.  **主内容区 (`content`)**: `content` 视图会检测到 `selectedCategoryId` 的变化，并根据这个 ID 找到对应的分类，然后显示该分类下的项目列表。
3.  **详情区 (`detail`)**: 当用户在 `content` 视图的列表中选择一个项目时，`selectedItemId` 会被更新。`detail` 视图则会根据这个 ID 显示最终的详细内容。

这个数据流是单向且清晰的，完美地体现了 SwiftUI 的数据驱动思想。

### `NavigationSplitView` 的优势

*   **自适应**: `NavigationSplitView` 会自动适应不同的设备和尺寸。在宽屏的 Mac 和 iPad 上，它会显示为三栏；而在窄屏的 iPhone 上，它会自动折叠成一个基于 `NavigationStack` 的、逐级推入的单栏导航体验。你无需编写任何设备判断代码。
*   **状态驱动**: 导航状态完全由你的 `@State` 变量控制，易于理解和管理。
*   **API 清晰**: `sidebar`, `content`, `detail` 三个闭包的职责非常明确。
*   **可定制**: 提供了 `.navigationSplitViewColumnWidth()` 和 `.navigationSplitViewStyle` 等修饰符来控制栏目的宽度和整体风格。

## 旧的方式：`NavigationView` (已废弃)

在 iOS 16 之前，开发者需要使用 `NavigationView` 来创建多栏布局。这种方式存在诸多问题：

*   **API 模糊**: 你需要在一个 `NavigationView` 中嵌套多个视图，并通过 `.navigationViewStyle(.doubleColumn)` 等修饰符来“暗示”系统你想要一个多栏布局。
*   **行为不可预测**: 在不同设备和方向上的行为常常不符合预期，难以控制。
*   **状态管理困难**: 缺乏像 `NavigationSplitView` 那样清晰的、基于 `selection` 的状态管理机制。

因此，对于所有支持 iOS 16+ / macOS 13+ 的新项目，都应该**完全避免使用 `NavigationView` 来创建多栏布局**。

## 总结

三栏布局是构建功能强大的、信息密集的 macOS 和 iPadOS 应用的核心布局模式。

*   **标准答案**: **`NavigationSplitView`** 是 SwiftUI 中实现三栏（或两栏）布局的唯一、正确的现代方式。
*   **数据驱动**: 它的核心是通过将每一栏的 `selection` 绑定到 `@State` 变量，来驱动下一栏内容的显示。
*   **跨平台自适应**: 它是构建真正自适应的、能够同时在 iPhone, iPad 和 Mac 上提供原生体验的应用的关键。

通过熟练掌握 `NavigationSplitView`，你可以轻松地构建出具有专业水准的、桌面级的应用程序架构。
