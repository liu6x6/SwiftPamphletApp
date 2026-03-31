# SwiftUI 导航系统简介

导航是任何应用程序的骨架，它定义了用户如何在不同的界面和功能之间移动。SwiftUI 提供了一套强大的、声明式的导航系统，它随着 SwiftUI 的版本更新，经历了一系列重要的演进。

理解这套系统的核心组件和演进历史，对于构建健壮、可维护且具有良好用户体验的 SwiftUI 应用至关重要。

## 导航系统的演进

1.  **`NavigationView` (iOS 13-15, 已废弃)**: 这是 SwiftUI 最初的导航组件。它使用 `NavigationLink` 来进行页面跳转。虽然简单易用，但它存在一些问题，如 API 功能有限、在复杂场景下状态管理困难、以及在 iPadOS 上的一些行为不一致。从 iOS 16 开始，它已被官方废弃。

2.  **`NavigationStack` (iOS 16+)**: 这是苹果推荐的、用于替代 `NavigationView` 的现代化导航容器。它提供了一个基于**路径 (Path)** 的、编程式的导航模型，极大地增强了导航的灵活性和可控性。它非常适合用于层级较深、线性的导航流程（如设置、邮件详情等）。

3.  **`NavigationSplitView` (iOS 16+)**: 这是一个用于创建多栏布局（如侧边栏-主内容-详情）的导航容器，是构建 iPadOS 和 macOS 应用的基石。它取代了 `NavigationView` 在大屏幕设备上的双栏或三栏行为，并提供了更清晰、更强大的 API。

## 核心导航组件

### `NavigationStack`

`NavigationStack` 维护一个导航路径的堆栈。你可以通过 `NavigationLink` 或以编程方式向这个堆栈中推入（push）新的视图。

```swift
import SwiftUI

struct BasicNavigationStack: View {
    var body: some View {
        // 1. 创建 NavigationStack
        NavigationStack {
            List {
                // 2. 使用 NavigationLink 进行跳转
                NavigationLink("进入详情页", destination: DetailView())
            }
            .navigationTitle("首页")
        }
    }
}

struct DetailView: View {
    var body: some View {
        Text("这是详情页").navigationTitle("详情")
    }
}
```

（更多详情请参阅 `NavigationStack(ap).md`）

### `NavigationSplitView`

`NavigationSplitView` 用于创建两栏或三栏布局，非常适合 iPad 和 Mac 应用。

```swift
struct BasicNavigationSplitView: View {
    @State private var selectedCategory: String? = "水果"
    @State private var selectedItem: String?

    var body: some View {
        NavigationSplitView {
            // 侧边栏 (Sidebar)
            List(selection: $selectedCategory) { ... }
        } content: {
            // 主内容 (Content)
            List(selection: $selectedItem) { ... }
        } detail: {
            // 详情 (Detail)
            Text("选择一个项目来查看详情")
        }
    }
}
```

（更多详情请参阅 `NavigationSplitView(ap).md`）

### `NavigationLink`

`NavigationLink` 是触发导航跳转的主要控件。它表现为一个可点击的视图，当用户点击它时，会将其 `destination` 视图推入到当前的 `NavigationStack` 中。

`NavigationLink` 有两种主要形式：

1.  **`NavigationLink(destination:label:)`**: 直接指定目标视图。
2.  **`NavigationLink(value:label:)`**: 推荐的现代用法。它只提供一个与导航相关的**数据**（`value`），而不是一个具体的视图。`NavigationStack` 会通过 `.navigationDestination(for:destination:)` 修饰符来匹配这个数据类型，并动态地创建目标视图。这种方式实现了更好的解耦。

```swift
// 推荐的方式
NavigationStack {
    List(fruits) { fruit in
        NavigationLink(fruit.name, value: fruit)
    }
    .navigationDestination(for: Fruit.self) { fruit in
        FruitDetailView(fruit: fruit)
    }
}
```

## 自定义导航栏

你可以使用一系列修饰符来定制导航栏的外观和内容。

*   **`.navigationTitle(_:)`**: 设置导航栏的标题。
*   **`.navigationBarTitleDisplayMode(_:)`**: 控制标题的显示模式（`.large`, `.inline`, `.automatic`）。
*   **`.toolbar { ... }`**: 向导航栏（或其他工具栏区域）添加按钮或其他控件。
*   **`.toolbarBackground(_:for:)`** (iOS 16+): 自定义导航栏的背景颜色或材质。
*   **`.toolbarColorScheme(_:for:)`** (iOS 16+): 为导航栏设置深色或浅色模式，以确保其中的按钮和标题颜色具有良好的对比度。

## 总结：如何选择？

*   **对于 iPhone 或任何需要线性、堆栈式导航的应用**，使用 **`NavigationStack`**。
*   **对于 iPad 和 Mac，或者任何需要多栏布局的应用**，使用 **`NavigationSplitView`**。
*   **始终使用 `NavigationLink(value:label:)` 和 `.navigationDestination`** 的组合，而不是旧的 `NavigationLink(destination:label:)`，以实现更清晰、更可扩展的导航逻辑。
*   **忘记 `NavigationView`**: 如果你的项目支持 iOS 16 及以上版本，就应该完全避免使用旧的 `NavigationView`。

SwiftUI 的现代导航系统（`NavigationStack` 和 `NavigationSplitView`）提供了一个强大、灵活且类型安全的框架，用于构建各种复杂的导航流程。通过将导航状态与数据流（`NavigationPath`）相结合，它使得深度链接（Deep Linking）、状态恢复和编程式导航等高级功能变得前所未有的简单。
