# SwiftUI 导航：NavigationStack (iOS 16+)

`NavigationStack` 是苹果在 WWDC 2022 (iOS 16) 中引入的、用于构建基于堆栈式导航流的现代化容器视图。它被设计用来完全替代旧的、已被废弃的 `NavigationView`，并提供了一套更强大、更灵活、更具声明性的 API。

`NavigationStack` 是构建任何具有层级关系的、线性导航流程（如设置菜单、邮件应用、购物流程等）的首选工具。

## 核心理念：数据驱动的路径

与 `NavigationView` 严重依赖 `NavigationLink` 的 `destination` 闭包来构建视图不同，`NavigationStack` 的核心是**数据驱动**。它维护一个导航“路径”（path），这个路径是一个代表了导航堆栈中每个页面的**数据**的集合。

这个工作流程如下：
1.  **`NavigationLink` 提供数据**: 用户点击一个 `NavigationLink(value: ...)`，这个 `value`（一个可哈希的数据，如 `Int`, `String` 或自定义结构体）被推入到导航路径中。
2.  **`NavigationStack` 观察路径**: `NavigationStack` 观察到其路径发生了变化。
3.  **`.navigationDestination` 创建视图**: `NavigationStack` 在其内容中，查找能够处理该数据类型的 `.navigationDestination(for: ...)` 修饰符，并使用它来创建并显示对应的目标视图。

这种解耦的方式使得导航逻辑更加清晰，并且极大地增强了编程式导航的能力。

## 基本用法

```swift
import SwiftUI

// 1. 定义你的数据模型
struct Fruit: Identifiable, Hashable {
    let id = UUID()
    let name: String
}

struct BasicNavigationStack: View {
    let fruits = [Fruit(name: "Apple"), Fruit(name: "Banana"), Fruit(name: "Cherry")]

    var body: some View {
        // 2. 创建 NavigationStack
        NavigationStack {
            List(fruits) { fruit in
                // 3. 使用 NavigationLink(value:label:)
                NavigationLink(fruit.name, value: fruit)
            }
            .navigationTitle("水果")
            // 4. 为特定数据类型提供目标视图
            .navigationDestination(for: Fruit.self) { fruit in
                FruitDetailView(fruit: fruit)
            }
        }
    }
}

struct FruitDetailView: View {
    let fruit: Fruit
    var body: some View { Text("详情页: \(fruit.name)").font(.largeTitle) }
}

#Preview {
    BasicNavigationStack()
}
```

在这个例子中：
*   `NavigationLink` 不再关心它的 `destination` 是什么视图，它只负责“宣告”一个导航意图，并附上相关的数据（`value: fruit`）。
*   `.navigationDestination(for: Fruit.self)` 修饰符负责“响应”这个意图。它声明了自己能够处理 `Fruit` 类型的数据，并在接收到数据后，创建对应的 `FruitDetailView`。

## 编程式导航：`NavigationPath`

`NavigationStack` 最强大的功能之一是它能够与一个外部的路径状态（`path`）进行绑定。这允许你以编程方式完全控制导航堆栈。

你可以将 `path` 绑定到一个特定类型的数组（如 `[Fruit]`），或者一个可以存储混合数据类型的、类型擦除的 `NavigationPath` 对象。

```swift
struct ProgrammaticNavigationStack: View {
    @State private var navigationPath: [Fruit] = []

    var body: some View {
        NavigationStack(path: $navigationPath) {
            // ... 与上面例子相同的 List 和 .navigationDestination
            
            Button("随机跳转到一个水果") {
                guard let randomFruit = fruits.randomElement() else { return }
                // 直接修改 path 来触发导航
                navigationPath.append(randomFruit)
            }
        }
    }
}
```

通过直接操作 `navigationPath` 数组（如 `append`, `removeLast`, `removeAll`），你可以实现：
*   **一键返回首页**: `navigationPath.removeAll()`
*   **跳转到多个层级**: `navigationPath = [fruit1, fruit2, fruit3]`
*   **深度链接**: 解析 URL，并用其参数来构建初始的 `navigationPath`。
*   **状态恢复**: 保存和恢复 `navigationPath`，让用户回到上次离开时的导航位置。

（更多详情请参阅 `NavigationPath(ap).md`）

## `NavigationStack` vs. `NavigationSplitView`

*   **`NavigationStack`**: 用于**单栏**的、基于堆栈的导航。它在所有尺寸的设备上都表现为一个可“推入”和“弹出”的视图堆栈。这是 **iPhone 应用**和 iPad/Mac 应用中线性流程（如设置、向导）的标准选择。

*   **`NavigationSplitView`**: 用于**多栏**（两栏或三栏）的导航。它会自动适应不同尺寸的屏幕，在大屏幕上并排显示多栏，在小屏幕上则自动折叠成类似 `NavigationStack` 的行为。这是 **iPad 和 Mac 应用**的顶级导航结构的首选。

## 总结

`NavigationStack` 是 SwiftUI 现代导航系统的核心，它为构建层级式导航流提供了一个健壮、灵活且声明式的解决方案。

*   **数据驱动**: 导航的核心是数据的变化，而不是视图的创建。
*   **解耦**: 将导航的“触发”（`NavigationLink`）与“响应”（`.navigationDestination`）分离开来，使代码更清晰、更可测试。
*   **编程式控制**: 通过绑定 `path`，可以实现对导航堆栈的完全控制，轻松实现深度链接和状态恢复等高级功能。
*   **替代 `NavigationView`**: 对于所有支持 iOS 16+ 的项目，都应该使用 `NavigationStack` 来替代旧的 `NavigationView`。

通过掌握 `NavigationStack` 和数据驱动的导航思想，你可以构建出结构清晰、功能强大且易于维护的复杂导航体验。
