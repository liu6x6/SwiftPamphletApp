# SwiftUI 布局组件：ContentUnavailableView (iOS 17+)

`ContentUnavailableView` 是苹果在 WWDC 2023 (iOS 17) 中引入的一个新的、高度标准化的视图，专门用于展示“空状态”（Empty State）或“内容不可用”的界面。在此之前，开发者需要手动组合 `VStack`, `Image`, `Text` 和 `Button` 来创建这类界面，而 `ContentUnavailableView` 将这一常见模式封装成了一个单一、易于使用的组件。

它的主要目的是为用户提供清晰的上下文，解释为什么当前没有内容可显示，并可能提供一个可执行的操作。

## 核心作用与场景

`ContentUnavailableView` 非常适合用于以下场景：

*   **空列表**: 当一个列表、`List` 或 `Table` 中没有任何数据时。
*   **搜索无结果**: 当用户的搜索查询没有返回任何匹配项时。
*   **需要登录**: 当用户需要登录才能查看某些内容时。
*   **网络错误**: 当因为网络问题无法加载内容时。
*   **功能引导**: 在用户首次使用某个功能、尚未创建任何内容时，提供引导。

使用 `ContentUnavailableView` 可以确保你的空状态界面与系统原生应用的风格（如“文件”或“邮件”中的空状态）保持一致，提供更统一、更专业的体验。

## 基本用法

`ContentUnavailableView` 提供了多种初始化方法，最常见的版本允许你提供一个标签（`Label`）、一个描述（`description`）和一个操作（`actions`）。

```swift
import SwiftUI

struct BasicContentUnavailableExample: View {
    var body: some View {
        ContentUnavailableView(
            // 1. 标签：通常包含一个图标和标题
            label: {
                Label("无收藏", systemImage: "star.slash")
            },
            // 2. 描述：提供更详细的上下文
            description: {
                Text("你收藏的项目将会出现在这里。")
            },
            // 3. 操作：提供一个或多个可执行的按钮
            actions: {
                Button("开始浏览") {
                    // ... 执行操作 ...
                }
                .buttonStyle(.borderedProminent)
            }
        )
    }
}

#Preview {
    BasicContentUnavailableExample()
}
```

在这个例子中，`ContentUnavailableView` 会自动将这三个部分以一种标准的、居中的方式进行布局，并应用合适的字体和间距。

## 系统预设的空状态

为了进一步简化最常见的场景，SwiftUI 还为 `List` 和 `NavigationStack` 等视图提供了内置的、基于搜索的空状态视图。

当你在一个 `List` 上使用了 `.searchable` 修饰符，并且搜索结果为空时，系统会自动显示一个“无结果”的 `ContentUnavailableView`。

```swift
struct SearchableListExample: View {
    @State private var allItems = ["Apple", "Banana", "Cherry", "Date"]
    @State private var searchText = ""

    var searchResults: [String] {
        if searchText.isEmpty {
            return allItems
        } else {
            return allItems.filter { $0.lowercased().contains(searchText.lowercased()) }
        }
    }

    var body: some View {
        NavigationStack {
            List(searchResults, id: \.self) { item in
                Text(item)
            }
            .navigationTitle("水果")
            // 当 searchResults 为空时，系统会自动显示一个预设的“无结果”视图
            .searchable(text: $searchText)
        }
    }
}

#Preview {
    SearchableListExample()
}
```

如果你想自定义这个搜索无结果的视图，你可以直接将一个 `ContentUnavailableView` 放置在 `.overlay` 中。

```swift
.overlay {
    if searchResults.isEmpty {
        ContentUnavailableView.search(text: searchText)
    }
}
```

`ContentUnavailableView.search(text:)` 是一个方便的静态方法，用于创建一个标准的“搜索无结果”视图。

## 自定义内容

`ContentUnavailableView` 的 `label`, `description`, 和 `actions` 闭包都可以接受任何 `View`。这为你提供了充分的自定义空间。

```swift
ContentUnavailableView {
    // Label
    VStack {
        Image("my-app-logo").resizable().frame(width: 80, height: 80)
        Text("欢迎!").font(.largeTitle)
    }
} description: {
    Text("开始你的第一步，创建一个新项目吧！")
} actions: {
    Button("创建新项目") { /* ... */ }
}
```

## 总结

`ContentUnavailableView` 是一个看似简单但非常有用的布局组件，它将一个常见的 UI 模式标准化、组件化了。

*   **标准化**: 提供了一种标准的方式来呈现空状态，确保了与系统应用的外观一致性。
*   **语义化**: 它的名字清晰地表达了其用途——“内容不可用”。
*   **简化代码**: 无需再手动组合 `VStack`, `Image`, `Text` 等来创建空状态视图。
*   **引导用户**: 通过 `description` 和 `actions`，可以有效地引导用户进行下一步操作，而不是让他们面对一个空白的屏幕不知所措。

在你的应用中，任何可能出现内容为空的界面，都应该考虑使用 `ContentUnavailableView` 来提供一个清晰、友好且有帮助的空状态提示。这是提升应用完整性和用户体验的一个重要细节。
