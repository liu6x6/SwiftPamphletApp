# SwiftUI List：添加搜索功能

在 SwiftUI 中，为 `List` 添加搜索功能是一项非常常见的需求。从 iOS 15 开始，SwiftUI 引入了 `.searchable()` 修饰符，使得实现列表搜索变得异常简单和标准化。它会自动在导航栏下方添加一个搜索框，并管理其显示、隐藏和交互状态。

## 核心用法：`.searchable()`

要为一个列表添加搜索功能，你需要：

1.  将你的 `List` 放置在一个 `NavigationStack` 或 `NavigationView` 中。
2.  为 `List` 附加 `.searchable()` 修饰符。
3.  提供一个 `Binding<String>` 来存储用户的搜索文本。

```swift
import SwiftUI

struct SearchableListExample: View {
    let allItems = ["Apple", "Banana", "Cherry", "Date", "Elderberry", "Fig"]
    
    // 1. 状态变量存储搜索文本
    @State private var searchText = ""

    // 2. 计算属性，根据搜索文本过滤数据
    var searchResults: [String] {
        if searchText.isEmpty {
            return allItems
        } else {
            return allItems.filter { $0.lowercased().contains(searchText.lowercased()) }
        }
    }

    var body: some View {
        NavigationStack {
            // 3. List 显示过滤后的结果
            List(searchResults, id: \.self) { item in
                Text(item)
            }
            .navigationTitle("水果")
            // 4. 附加 .searchable 修饰符
            .searchable(text: $searchText, prompt: "搜索水果")
        }
    }
}

#Preview {
    SearchableListExample()
}
```

在这个例子中：
1.  `searchText` 状态变量通过双向绑定与搜索框的内容保持同步。
2.  `searchResults` 计算属性根据 `searchText` 的值，动态地过滤 `allItems` 数组。如果搜索框为空，则返回所有项目；否则，返回包含搜索文本的项目。
3.  `List` 直接使用 `searchResults` 作为其数据源。因为 `searchResults` 是一个计算属性，所以当 `searchText` 改变时，它会自动重新计算，`List` 也会自动更新其内容。
4.  `.searchable(text: $searchText, prompt: ...)` 是实现这一切的核心。`prompt` 参数定义了搜索框在为空时显示的占位符文本。

SwiftUI 会自动处理搜索框的显示和隐藏逻辑（例如，在列表向下滚动时自动隐藏）。

## 搜索建议 (`.searchSuggestions`)

`.searchable()` 还可以与 `.searchSuggestions()` 修饰符结合，来为用户提供实时的搜索建议。

```swift
.searchable(text: $searchText)
.searchSuggestions {
    // 当用户正在输入时，这里的内容会显示为建议列表
    ForEach(searchResults.prefix(5), id: \.self) { result in
        Text("你是不是想找: \(result)?")
            .searchCompletion(result) // 点击建议会自动填充搜索框
    }
}
```

在这个例子中：
*   当用户在搜索框中输入时，`.searchSuggestions` 闭包内的视图会以一个建议列表的形式显示出来。
*   我们只显示了搜索结果的前 5 项作为建议。
*   `.searchCompletion(result)` 是一个关键的修饰符。当你将它附加到一个建议项上时，用户点击该建议项，`result` 的值就会被自动填充到搜索框中。

## 管理搜索状态

有时你需要知道搜索框当前是否处于激活状态（即，用户是否正在输入或准备输入）。你可以通过 `@Environment` 来读取 `isSearching` 这个环境值。

```swift
@Environment(\.isSearching) private var isSearching

var body: some View {
    NavigationStack {
        List { ... }
            .onChange(of: isSearching) { newValue in
                print("搜索状态改变为: \(newValue)")
            }
            .searchable(text: $searchText)
    }
}
```

这在你需要在用户开始或结束搜索时，执行一些特定的 UI 变化或逻辑时非常有用。

## 空状态视图

当搜索结果为空时，向用户显示一个清晰的“无结果”提示是非常好的用户体验。从 iOS 17 开始，`List` 会自动为这种情况显示一个标准的 `ContentUnavailableView`。

如果你想自定义这个空状态，可以在 `List` 上附加一个 `.overlay`。

```swift
List { ... }
    .overlay {
        if searchResults.isEmpty {
            ContentUnavailableView(
                label: { Label("未找到 \"\(searchText)\"", systemImage: "magnifyingglass") },
                description: { Text("请尝试使用不同的关键词进行搜索。") }
            )
        }
    }
```

## 总结

`.searchable()` 修饰符是 SwiftUI 中一个设计得非常出色的 API，它将复杂的搜索交互封装成了一个简单、声明式的修饰符。

*   **简单集成**: 只需一行 `.searchable(text: $searchText)` 即可为任何 `List` 添加功能完善的搜索框。
*   **数据驱动**: 搜索逻辑的核心是创建一个根据搜索文本动态过滤源数据的计算属性。
*   **高级功能**: 支持通过 `.searchSuggestions` 提供实时搜索建议，并通过 `@Environment(\.isSearching)` 监控搜索状态。
*   **平台一致性**: 自动处理搜索框的动画、显示/隐藏行为，并提供符合平台规范的 UI。

通过使用 `.searchable()`，你可以轻松地为你的应用添加强大而用户友好的搜索功能，而无需关心底层复杂的 UI 状态管理。
