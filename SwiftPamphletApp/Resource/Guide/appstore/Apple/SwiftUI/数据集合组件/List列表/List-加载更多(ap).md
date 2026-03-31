# SwiftUI List：加载更多 (Infinite Scrolling)

“加载更多”或“无限滚动”（Infinite Scrolling）是移动应用中一种非常常见的数据分页加载模式。当用户滚动到列表底部时，应用会自动加载下一页的数据，并将其追加到现有列表的末尾，从而创造出一种内容无限延伸的流畅体验。

在 SwiftUI 中，实现这一功能的核心是利用 `.onAppear()` 修饰符来检测列表中的某个特定视图（通常是最后一个）何时出现。

## 核心思路

1.  **数据分页**: 你的数据源（通常是后端 API）需要支持分页。每次请求时，你可以传递一个页码（`page`）或一个偏移量（`offset`），API 会返回相应的数据片段。
2.  **状态管理**: 在你的视图模型或视图中，维护当前已加载的数据列表、当前的页码以及一个表示是否正在加载下一页的状态（以防止重复加载）。
3.  **检测滚动到底部**: 在 `List` 或 `ScrollView` 的 `ForEach` 循环中，为**最后一个元素**附加一个 `.onAppear()` 修饰符。
4.  **触发加载**: 当最后一个元素出现在屏幕上时，`.onAppear()` 闭包会被调用。你在这个闭包中触发加载下一页数据的异步任务。

## 示例：实现一个无限滚动的列表

让我们创建一个模拟从网络加载分页数据的列表。

```swift
import SwiftUI

// 1. 定义数据模型
struct Item: Identifiable, Decodable {
    let id: Int
    let text: String
}

// 2. 创建一个处理数据加载的视图模型
@MainActor // 确保所有对 UI 的更新都在主线程上
class ItemViewModel: ObservableObject {
    @Published var items: [Item] = []
    @Published var isLoadingPage = false
    private var currentPage = 1
    private var canLoadMorePages = true

    func loadMoreContentIfNeeded(currentItem item: Item?) {
        guard let item = item else {
            loadMoreContent()
            return
        }

        let thresholdIndex = items.index(items.endIndex, offsetBy: -5)
        if items.firstIndex(where: { $0.id == item.id }) == thresholdIndex {
            loadMoreContent()
        }
    }

    private func loadMoreContent() {
        guard !isLoadingPage && canLoadMorePages else {
            return
        }

        isLoadingPage = true

        Task {
            // 模拟网络请求
            let url = URL(string: "https://yourapi.com/items?page=\(currentPage)")!
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 模拟 1 秒延迟
            let newItems = (0..<15).map { Item(id: items.count + $0, text: "Item \(items.count + $0)") }
            
            if newItems.isEmpty {
                canLoadMorePages = false
            } else {
                items.append(contentsOf: newItems)
                currentPage += 1
            }
            
            isLoadingPage = false
        }
    }
}

// 3. 创建 SwiftUI 视图
struct InfiniteScrollView: View {
    @StateObject private var viewModel = ItemViewModel()

    var body: some View {
        NavigationView {
            List(viewModel.items) { item in
                Text(item.text)
                    // 4. 为每个项目附加 .onAppear，并检查是否需要加载更多
                    .onAppear {
                        viewModel.loadMoreContentIfNeeded(currentItem: item)
                    }
            }
            .navigationTitle("无限滚动")
            .onAppear {
                // 初始加载
                viewModel.loadMoreContentIfNeeded(currentItem: nil)
            }
        }
    }
}

#Preview {
    InfiniteScrollView()
}
```

### 代码解析

1.  **`ItemViewModel`**: 这个 `ObservableObject` 封装了所有的状态和逻辑。
    *   `items`: 存储已加载的数据列表。
    *   `isLoadingPage`: 一个布尔值，用于防止在当前页的数据还未返回时，就重复触发下一页的加载。
    *   `currentPage`: 追踪当前需要请求的页码。
    *   `canLoadMorePages`: 当 API 返回空数据时，将其设为 `false`，以停止后续的加载尝试。

2.  **`loadMoreContentIfNeeded(currentItem:)`**: 这是触发加载的核心逻辑。
    *   它接收一个可选的 `currentItem`。如果为 `nil`（通常在初始加载时），它会立即开始加载。
    *   **关键技巧**: 它检查 `currentItem` 是否是列表中的**倒数第五个**元素 (`thresholdIndex`)。当用户滚动到接近列表末尾时（而不是必须精确地滚动到最后一个元素），我们就提前开始加载下一页。这创造了一种更平滑、无缝的体验，用户几乎感觉不到加载的停顿。

3.  **`loadMoreContent()`**: 这是一个 `async` 函数，负责执行实际的“网络请求”。
    *   它首先检查 `isLoadingPage` 和 `canLoadMorePages` 以避免不必要的操作。
    *   在 `Task` 中，它模拟了一个网络延迟，然后创建一批新数据。
    *   成功获取数据后，它将新数据追加到 `items` 数组，并增加页码。
    *   最后，它将 `isLoadingPage` 重置为 `false`。

4.  **`InfiniteScrollView`**: 
    *   `List` 遍历 `viewModel.items` 来显示数据。
    *   `.onAppear` 被附加到 `List` 中的**每一个** `Text` 上。当任何一个 `Text` 出现时，都会调用 `viewModel.loadMoreContentIfNeeded`。
    *   视图模型内部的逻辑会判断出现的 `item` 是否满足触发加载的条件（即是否接近列表末尾）。

## 改进：显示加载指示器

你可以在列表的底部添加一个 `ProgressView`，以在加载下一页时向用户提供视觉反馈。

```swift
List {
    ForEach(viewModel.items) { item in
        Text(item.text)
            .onAppear {
                viewModel.loadMoreContentIfNeeded(currentItem: item)
            }
    }
    
    // 在列表底部显示加载指示器
    if viewModel.isLoadingPage {
        HStack {
            Spacer()
            ProgressView()
            Spacer()
        }
    }
}
```

## 总结

在 SwiftUI 中实现“加载更多”或“无限滚动”的核心是**状态驱动**和**事件检测**。

*   **状态管理**: 使用一个视图模型（`ObservableObject`）来清晰地管理数据、页码和加载状态。
*   **触发机制**: 利用 `.onAppear()` 修饰符来检测用户是否已滚动到列表的末尾附近。
*   **预加载**: 不要等到最后一个元素完全出现时才开始加载，而是设置一个阈值（如倒数第 5 或第 10 个元素），提前触发加载，以提供更无缝的体验。
*   **异步处理**: 使用 `async/await` 和 `Task` 来优雅地处理耗时的网络请求，而不会阻塞 UI。

通过这种模式，你可以轻松地为你的应用构建出高性能、用户体验流畅的无限滚动列表。
