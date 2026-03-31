# SwiftUI List：下拉刷新 (Pull to Refresh)

下拉刷新（Pull to Refresh）是移动应用中一种非常常见的数据刷新交互模式。用户在列表或滚动视图的顶部向下拉动，即可触发一次内容的重新加载。从 iOS 15 开始，SwiftUI 为 `List` 和 `ScrollView` 提供了原生的、易于使用的 `.refreshable()` 修饰符来实现这一功能。

## 核心用法：`.refreshable()`

`.refreshable()` 修饰符可以被附加到任何可滚动的视图上（如 `List` 或 `ScrollView`）。它接收一个**异步**的 `action` 闭包。当用户执行下拉刷新手势时，系统会自动显示一个标准的刷新指示器（`ProgressView`），并**异步执行**你提供的 `action` 闭包。

```swift
import SwiftUI

struct RefreshableListExample: View {
    @State private var items = ["Apple", "Banana", "Cherry"]

    var body: some View {
        NavigationView {
            List(items, id: \.self) { item in
                Text(item)
            }
            .navigationTitle("水果列表")
            // 1. 附加 .refreshable 修饰符
            .refreshable {
                // 2. 在这里执行你的异步刷新逻辑
                await refreshData()
            }
        }
    }

    // 3. 定义一个异步函数来加载新数据
    func refreshData() async {
        // 模拟一个网络请求，耗时 2 秒
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        // 更新数据源
        let newItems = ["Date", "Elderberry", "Fig"]
        items.insert(contentsOf: newItems.shuffled(), at: 0)
    }
}

#Preview {
    RefreshableListExample()
}
```

在这个例子中：
1.  我们将 `.refreshable` 修饰符附加到 `List` 上。
2.  在 `action` 闭包中，我们调用了一个 `async` 函数 `refreshData()`。
3.  在 `refreshData()` 中，我们使用 `Task.sleep` 来模拟一个耗时的网络请求。在此期间，SwiftUI 会一直显示一个旋转的刷新指示器。
4.  当 `refreshData()` 函数执行完毕（`await` 结束）后，刷新指示器会自动消失，`List` 会更新以显示新的数据。

## 与 `async/await` 的集成

`.refreshable()` 的设计与 Swift 的现代并发模型 `async/await` 完美集成。你提供的 `action` 必须是一个 `async` 闭包，这使得在其中执行网络请求、数据库查询等异步操作变得非常自然和简洁。

你无需手动管理刷新指示器的显示和隐藏，SwiftUI 会自动处理：
*   **开始刷新**: 当用户触发下拉手势时，显示指示器并 `await` 你的 `action`。
*   **结束刷新**: 当你的 `action` 闭包执行完毕后，隐藏指示器。

## 在 `ScrollView` 中使用

`.refreshable()` 同样可以应用于 `ScrollView`，其用法与 `List` 完全相同。

```swift
struct RefreshableScrollViewExample: View {
    @State private var number = 0

    var body: some View {
        ScrollView {
            VStack {
                Text("当前数字: \(number)")
                    .font(.largeTitle)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 300)
        }
        .refreshable {
            // 模拟加载
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            number = Int.random(in: 1...100)
        }
    }
}
```

## 注意事项

*   **平台兼容性**: `.refreshable()` 是在 iOS 15 和 macOS 12 中引入的。对于更早的系统版本，你需要回退到封装 `UIRefreshControl` (UIKit) 的方式。
*   **可滚动性**: 这个修饰符只对本身可滚动的视图（如 `List`, `ScrollView`）或被放置在可滚动视图内的内容有效。如果视图没有足够的空间来滚动，用户将无法触发下拉手势。
*   **异步操作**: `action` 闭包必须是 `async` 的。如果你需要调用一个非 `async` 的、但有完成回调的旧版 API，你需要使用 `withCheckedContinuation` 来将其包装成一个 `async` 函数。

## 总结

`.refreshable()` 修饰符是 SwiftUI 中实现“下拉刷新”功能的现代化、标准化的解决方案。

*   **声明式**: 你只需要声明当刷新被触发时**应该做什么**，而无需关心如何检测手势、显示/隐藏指示器等实现细节。
*   **与 `async/await` 完美集成**: 使得在刷新操作中执行异步任务变得异常简单和清晰。
*   **平台一致性**: 自动使用系统原生的刷新指示器和交互行为，确保了良好的用户体验。

通过使用 `.refreshable()`，你可以轻松地为你的列表和滚动视图添加这一常见的、用户所熟悉的数据刷新功能，极大地提升了应用的交互性和可用性。
