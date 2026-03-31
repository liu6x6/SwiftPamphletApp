# SwiftUI 布局组件：TabView

`TabView` 是 SwiftUI 中用于创建标签式界面的核心容器视图。它允许用户在多个并列的子视图（或“标签页”）之间进行切换。在 iOS 上，它通常表现为屏幕底部的标签栏（Tab Bar），这是移动应用中最常见、最重要的导航模式之一。

## 核心用法：`.tabItem`

创建一个 `TabView` 的基本方式是，将多个视图放置在其闭包中，并为每一个视图附加一个 `.tabItem` 修饰符。`.tabItem` 的闭包定义了该标签页在标签栏中对应的图标和文字。

```swift
import SwiftUI

struct BasicTabViewExample: View {
    var body: some View {
        // 1. 创建 TabView 容器
        TabView {
            // 第一个标签页
            HomeView()
                .tabItem { // 2. 定义标签栏项目
                    Label("首页", systemImage: "house.fill")
                }
            
            // 第二个标签页
            SearchView()
                .tabItem {
                    Label("搜索", systemImage: "magnifyingglass")
                }
            
            // 第三个标签页
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape.fill")
                }
        }
    }
}

// 示例的子视图
struct HomeView: View {
    var body: some View { Text("首页内容").font(.largeTitle) }
}
struct SearchView: View {
    var body: some View { Text("搜索内容").font(.largeTitle) }
}
struct SettingsView: View {
    var body: some View { Text("设置内容").font(.largeTitle) }
}

#Preview {
    BasicTabViewExample()
}
```

在这个例子中：
*   `TabView` 包裹了三个子视图：`HomeView`, `SearchView`, `SettingsView`。
*   每个子视图都通过 `.tabItem` 修饰符，提供了一个由 `Label`（包含图标和文字）构成的标签栏项目。
*   SwiftUI 会自动处理标签栏的创建、布局以及点击标签时切换到对应视图的逻辑。

## 编程式的标签页切换

除了让用户手动点击标签栏来切换，你也可以通过编程方式来控制当前显示的标签页。这需要：

1.  **`tag`**: 为每一个子视图附加一个唯一的、可哈希的 `.tag()` 修饰符。
2.  **`selection`**: 为 `TabView` 提供一个到状态变量的双向绑定 (`Binding`)。

```swift
struct ProgrammaticTabViewExample: View {
    // 2. 状态变量存储当前选中的标签
    @State private var selectedTab: Int = 1

    var body: some View {
        TabView(selection: $selectedTab) {
            Text("首页")
                .tabItem { Label("首页", systemImage: "house") }
                .tag(1) // 1. 为每个视图设置唯一的 tag
            
            Text("设置")
                .tabItem { Label("设置", systemImage: "gear") }
                .tag(2)
        }
        
        // 在 TabView 外部的按钮可以改变 selectedTab 的值，从而切换标签页
        Button("切换到设置") {
            selectedTab = 2
        }
        .padding()
    }
}

#Preview {
    ProgrammaticTabViewExample()
}
```

在这个例子中，`TabView` 的 `selection` 绑定到了 `selectedTab`。当用户点击标签栏时，`selectedTab` 的值会自动更新为对应视图的 `tag` 值。反之，当代码（例如点击外部的按钮）修改 `selectedTab` 的值时，`TabView` 也会自动切换到对应的标签页。

## `TabView` 的样式：`.tabViewStyle()`

`TabView` 的外观可以通过 `.tabViewStyle()` 修饰符来改变。这使得 `TabView` 不仅仅能用作底部的标签栏，还能用作可水平滑动的分页视图。

*   **`.automatic`**: 默认样式。在 iOS 上通常是底部的标签栏。
*   **`.page`**: 分页样式。它会将子视图渲染成一系列可水平滑动的“页面”，通常会伴随一个页面指示器（小圆点）。
*   **`.page(indexDisplayMode:)`**: 更精细地控制页面指示器的显示方式（`.automatic`, `.always`, `.never`）。

### 示例：创建分页视图 (Onboarding/Walkthrough)

分页样式的 `TabView` 非常适合用于创建应用的引导页或图片轮播。

```swift
struct PageTabViewExample: View {
    var body: some View {
        TabView {
            OnboardingPageView(systemImage: "1.circle", text: "第一页")
            OnboardingPageView(systemImage: "2.circle", text: "第二页")
            OnboardingPageView(systemImage: "3.circle", text: "第三页")
        }
        .tabViewStyle(.page(indexDisplayMode: .always)) // 应用分页样式
        .background(Color.gray.opacity(0.2))
    }
}

struct OnboardingPageView: View {
    let systemImage: String
    let text: String
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: systemImage).font(.system(size: 100))
            Text(text).font(.title)
        }
    }
}

#Preview {
    PageTabViewExample()
}
```

在这个例子中，我们只是将 `.tabViewStyle` 从默认值改为了 `.page`，就将一个标准的标签栏视图转换成了一个功能完善的、可水平滑动的分页浏览器。

## 为标签添加角标 (`.badge()`)

你可以使用 `.badge()` 修饰符在标签栏的项目上显示一个角标，用于提示用户有新的通知或未读消息。

```swift
Text("消息")
    .tabItem { Label("消息", systemImage: "message.fill") }
    .badge(5) // 显示一个包含数字 5 的角标

Text("通知")
    .tabItem { Label("通知", systemImage: "bell.fill") }
    .badge("!") // 显示一个包含文本的角标
```

## 总结

`TabView` 是 SwiftUI 中实现顶级导航和内容分页的核心组件。

*   **标签栏导航**: 默认情况下，`TabView` 会创建一个标准的底部标签栏，这是大多数 iOS 应用的主要导航结构。
*   **分页视图**: 通过应用 `.tabViewStyle(.page)`，可以轻松地将其转换为一个可水平滑动的分页视图，非常适合用于引导页和图片轮播。
*   **编程式控制**: 通过 `selection` 和 `tag`，可以实现对当前显示页面的精确控制。
*   **信息提示**: 使用 `.badge()` 可以方便地在标签上显示通知角标。

通过灵活运用 `TabView` 及其不同的样式，你可以轻松地构建出符合平台规范、用户体验流畅的多种核心导航和展示模式。
