# SwiftUI 数据集合组件：LazyVStack 与 LazyHStack

`LazyVStack` 和 `LazyHStack` 是 SwiftUI 中用于排列大量视图的“懒加载”版本的堆栈。与常规的 `VStack` 和 `HStack` 不同，它们只会在其子视图即将进入屏幕时才创建和渲染，这使得它们在处理成百上千个项目的可滚动列表时，具有极高的性能和内存效率。

*   **`LazyVStack`**: 创建一个**垂直**排列的、懒加载的视图堆栈。
*   **`LazyHStack`**: 创建一个**水平**排列的、懒加载的视图堆栈。

它们几乎总是被放置在一个 `ScrollView` 中，以提供滚动能力。

## 核心理念：懒加载 (Lazy Loading)

想象一下，如果你在一个常规的 `VStack` 中放置 10,000 个 `Text` 视图，SwiftUI 会在视图出现时，**一次性**地创建和渲染所有这 10,000 个视图。这会导致应用启动缓慢，甚至可能因为内存耗尽而崩溃。

`LazyVStack` 解决了这个问题。它只会创建当前屏幕上可见的、以及屏幕外一小部分缓冲区内的视图。当用户滚动时，它会销毁滚出屏幕的视图，并创建即将滚入屏幕的新视图。

## 基本用法

`LazyVStack` 和 `LazyHStack` 的用法与常规的 `VStack` 和 `HStack` 非常相似，你可以指定 `alignment` 和 `spacing`。

```swift
import SwiftUI

struct LazyVStackExample: View {
    var body: some View {
        // 1. 必须放置在 ScrollView 中才能滚动
        ScrollView {
            // 2. 使用 LazyVStack
            LazyVStack(alignment: .leading, spacing: 10) {
                // 3. 使用 ForEach 提供大量内容
                ForEach(1...1000, id: \.self) { index in
                    Text("Row \(index)")
                        .padding()
                        .onAppear {
                            // 可以通过 onAppear 观察到视图是何时被创建的
                            print("Row \(index) appeared")
                        }
                }
            }
        }
    }
}

#Preview {
    LazyVStackExample()
}
```

在这个例子中：
1.  `LazyVStack` 被包裹在一个 `ScrollView` 中。
2.  `ForEach` 创建了 1000 个 `Text` 视图。
3.  当你运行这个例子并滚动时，你会看到控制台只会打印出当前可见行和即将出现行的 `onAppear` 信息，而不是一次性打印 1000 条。这证明了其“懒加载”的行为。

## `LazyVStack` vs. `VStack`

| 特性 | `LazyVStack` | `VStack` |
| :--- | :--- | :--- |
| **加载方式** | **懒加载 (Lazy)** | **立即加载 (Eager)** |
| **性能** | **高**，适合大量、动态的数据。 | **低**，只适合少量、静态的视图。 |
| **布局行为** | 会尽可能地在其主轴方向上占据所有可用空间。 | 只会占据其子视图所需的最小空间。 |
| **适用场景** | 在 `ScrollView` 中显示长列表。 | 构建由少量固定元素组成的静态布局，如卡片、表单节。 |

**一个重要的布局差异**: `LazyVStack` 在垂直方向上是“贪婪”的，而 `VStack` 不是。如果你将它们都放在一个 `frame` 中，你会看到 `LazyVStack` 会填满整个高度，而 `VStack` 只会包裹其内容。

## `LazyHStack`

`LazyHStack` 的工作原理与 `LazyVStack` 完全相同，只是方向是水平的。

```swift
struct LazyHStackExample: View {
    var body: some View {
        ScrollView(.horizontal) { // 使用水平滚动视图
            LazyHStack(spacing: 15) {
                ForEach(1...100, id: \.self) { index in
                    Text("Item \(index)")
                        .padding()
                        .background(Color.mint)
                }
            }
        }
        .frame(height: 100) // 水平滚动视图需要一个确定的高度
    }
}
```

## 固定页眉/页脚 (`pinnedViews`)

`LazyVStack` 和 `LazyHStack` 可以与 `Section` 结合使用，以创建带有“固定”（sticky）页眉和页脚的列表。

你可以通过 `pinnedViews` 参数来控制哪些部分应该被固定。

*   `.sectionHeaders`: 只固定页眉。
*   `.sectionFooters`: 只固定页脚。

```swift
ScrollView {
    LazyVStack(pinnedViews: [.sectionHeaders, .sectionFooters]) {
        ForEach(1...5, id: \.self) { sectionIndex in
            Section(
                header: Text("Header \(sectionIndex)").frame(maxWidth: .infinity).background(Color.blue),
                footer: Text("Footer \(sectionIndex)").frame(maxWidth: .infinity).background(Color.green)
            ) {
                ForEach(1...3, id: \.self) { rowIndex in
                    Text("Row \(rowIndex)")
                }
            }
        }
    }
}
```

在这个例子中，当你向上滚动时，每个 `Section` 的蓝色 `header` 会固定在屏幕顶部，直到该 `Section` 的所有内容都滚出屏幕。同样，`footer` 也会固定在底部。

## 总结

`LazyVStack` 和 `LazyHStack` 是 SwiftUI 中构建高性能可滚动内容的基础。

*   **核心优势**: **懒加载**。只在需要时创建视图，极大地优化了处理大量数据时的性能和内存。
*   **使用场景**: 必须与 `ScrollView` 结合使用，用于创建垂直或水平滚动的长列表。
*   **与常规 Stack 的区别**: `Lazy` 堆栈是为**动态的、大量的**内容设计的，而常规堆栈是为**静态的、少量的**内容设计的。
*   **分组与固定**: 支持 `Section`，并可以通过 `pinnedViews` 参数创建固定的页眉和页脚。

当你需要显示一个可能包含数十、数百甚至数千个项目的列表时，`LazyVStack` 或 `LazyHStack` 是你必须使用的工具。
