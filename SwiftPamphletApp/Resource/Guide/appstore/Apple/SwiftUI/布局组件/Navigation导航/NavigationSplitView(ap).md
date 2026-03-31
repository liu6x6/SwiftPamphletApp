# SwiftUI 导航：NavigationSplitView (iOS 16+)

`NavigationSplitView` 是苹果在 WWDC 2022 (iOS 16) 中引入的一个强大的导航容器，专门用于构建多栏布局。它是创建现代化、自适应的 iPadOS 和 macOS 应用的基石，也为在 iPhone Pro Max 等大屏幕设备上提供更丰富的横屏体验奠定了基础。

它正式取代了旧版 `NavigationView` 在大屏幕设备上难以预测和控制的双栏行为，提供了一套更清晰、更强大、更具声明性的 API。

## 核心用法：定义多栏内容

`NavigationSplitView` 允许你定义两栏或三栏的布局。

### 两栏布局 (`sidebar` + `detail`)

最常见的两栏布局包含一个侧边栏和一个详情视图。

```swift
import SwiftUI

struct TwoColumnSplitView: View {
    @State private var selectedFruit: String? = "Apple"
    let fruits = ["Apple", "Banana", "Cherry"]

    var body: some View {
        NavigationSplitView {
            // 1. 侧边栏 (Sidebar)
            List(fruits, id: \.self, selection: $selectedFruit) { fruit in
                Text(fruit)
            }
            .navigationTitle("水果")
        } detail: {
            // 2. 详情视图 (Detail)
            if let selectedFruit = selectedFruit {
                Text("你选择了: \(selectedFruit)")
                    .font(.largeTitle)
            } else {
                Text("请从左侧选择一个水果")
            }
        }
    }
}

#Preview {
    TwoColumnSplitView()
}
```

在这个例子中：
*   第一个闭包是侧边栏，我们用一个 `List` 来显示可选项。
*   `detail` 闭包是详情视图，它根据侧边栏的选择（`selectedFruit`）来显示不同的内容。
*   `List` 的 `selection` 参数与 `@State` 变量绑定，SwiftUI 会自动处理列表选择与状态同步的逻辑。

### 三栏布局 (`sidebar` + `content` + `detail`)

对于更复杂的导航层级，你可以使用三栏布局。

```swift
struct ThreeColumnSplitView: View {
    @State private var selectedCategory: Category? = .fruits
    @State private var selectedItem: String?

    enum Category { case fruits, vegetables }
    let fruits = ["Apple", "Banana", "Cherry"]
    let vegetables = ["Carrot", "Broccoli"]

    var body: some View {
        NavigationSplitView {
            // 1. 侧边栏 (Sidebar)
            List(selection: $selectedCategory) {
                Text("水果").tag(Category.fruits)
                Text("蔬菜").tag(Category.vegetables)
            }
            .navigationTitle("分类")
        } content: {
            // 2. 主内容 (Content)
            let items = (selectedCategory == .fruits) ? fruits : vegetables
            List(items, id: \.self, selection: $selectedItem) { item in
                Text(item)
            }
            .navigationTitle(selectedCategory == .fruits ? "水果" : "蔬菜")
        } detail: {
            // 3. 详情 (Detail)
            if let selectedItem = selectedItem {
                Text("你选择了: \(selectedItem)")
                    .font(.largeTitle)
            } else {
                Text("选择一个项目")
            }
        }
    }
}

#Preview {
    ThreeColumnSplitView()
}
```

在这个例子中，`content` 视图的内容会根据 `sidebar` 的选择而改变，而 `detail` 视图的内容则会根据 `content` 视图的选择而改变，形成了一个清晰的三级导航结构。

## 自适应行为

`NavigationSplitView` 的最大优势在于其强大的自适应能力。

*   **大屏幕 (iPad, Mac)**: 它会并排显示两栏或三栏。
*   **小屏幕 (iPhone)**: 它会自动折叠成一个基于 `NavigationStack` 的单栏导航体验。用户首先看到 `sidebar`，点击一项后会“推入”`content` 视图，再点击一项会再次“推入”`detail` 视图。

这种行为是完全自动的，你无需编写任何设备判断代码，即可让你的应用在所有平台上都表现得自然、得体。

## 控制侧边栏的可见性

你可以通过 `NavigationSplitViewVisibility` 来控制侧边栏的默认行为。

```swift
@State private var visibility: NavigationSplitViewVisibility = .automatic

NavigationSplitView(columnVisibility: $visibility) { ... }
```

*   `.automatic`: 默认行为。
*   `.detailOnly`: 默认只显示详情视图，侧边栏和内容视图需要用户手动滑出。
*   `.doubleColumn`: 始终显示两栏。
*   `.tripleColumn`: 始终显示三栏。

你可以在 `Toolbar` 中添加一个按钮来切换 `visibility` 的值，从而让用户可以手动控制侧边栏的显示和隐藏。

## 样式 (`.navigationSplitViewStyle()`)

你可以通过 `.navigationSplitViewStyle()` 来微调分栏视图的外观。

*   `.automatic`: 默认样式。
*   `.balanced`: 尝试让 `sidebar` 和 `content` 栏的宽度更加均衡。
*   `.prominentDetail`: 优先突出 `detail` 视图，使其占据更多空间。

## 总结

`NavigationSplitView` 是构建现代、跨平台 SwiftUI 应用的导航基础。它取代了 `NavigationView` 在处理多栏布局时的模糊性和局限性。

*   **专为多栏设计**: 提供了清晰的 `sidebar`, `content`, `detail` 三个部分，用于构建分栏界面。
*   **强大的自适应**: 自动在多栏（大屏幕）和单栏堆栈（小屏幕）之间进行转换，无需额外代码。
*   **状态驱动**: 通过将 `selection` 绑定到 `@State` 变量，实现了导航状态与数据的同步。
*   **可控性**: 提供了 `columnVisibility` 和样式来自定义其行为和外观。

对于任何需要支持 iPad 或 Mac 的应用，或者希望在 iPhone 横屏模式下提供更丰富体验的应用，`NavigationSplitView` 都是构建其顶级导航结构的不二之选。它与 `NavigationStack` 共同构成了 SwiftUI 现代导航系统的完整解决方案。
