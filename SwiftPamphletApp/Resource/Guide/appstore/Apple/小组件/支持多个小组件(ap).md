# 支持和组合多个小组件 (WidgetBundle)

在一个成熟的 iOS 应用中，通常不会只有一个小组件。你可能有一个展示天气的“信息看板”小组件，还有一个供用户快速记录的“快捷操作”小组件。甚至，同一个小组件还可能支持锁屏样式（Accessory）和主屏幕样式（System）。

Apple 提供了 `WidgetBundle` 协议，让你可以在一个 Widget Extension (小组件目标工程) 中暴露和打包**多个**不同种类的小组件给系统。

## 1. 什么是 WidgetBundle？

当你使用 Xcode 创建第一个 Widget Target 时，系统会自动为你生成一个标有 `@main` 的单一入口点。

```swift
@main
struct MyFirstWidget: Widget {
    let kind: String = "MyFirstWidget"
    var body: some WidgetConfiguration {
        // ...
    }
}
```

`@main` 标志着这是系统加载小组件的入口。但是，**一个 Extension 只能有一个 `@main`**。如果你想添加第二个小组件（比如 `MySecondWidget`），你不能给它也标上 `@main`，否则会引发编译错误。

此时，你需要引入 `WidgetBundle`。

## 2. 使用 WidgetBundle 组合小组件

**第一步**：移除之前单个小组件上的 `@main` 标记。

```swift
// 移除这里的 @main
struct WeatherWidget: Widget {
    let kind: String = "WeatherWidget"
    var body: some WidgetConfiguration { /* ... */ }
}

// 你的第二个小组件
struct TodoListWidget: Widget {
    let kind: String = "TodoListWidget"
    var body: some WidgetConfiguration { /* ... */ }
}
```

**第二步**：创建一个新的结构体，遵循 `WidgetBundle` 协议，并在上面打上 `@main` 标记。在这个 Bundle 的 `body` 内部，将你需要暴露给系统的所有小组件实例化。

```swift
import WidgetKit
import SwiftUI

@main
struct MyAppWidgetsBundle: WidgetBundle {
    // 像 SwiftUI 的 ViewBuilder 一样，罗列出所有的 Widget
    @WidgetBundleBuilder
    var body: some Widget {
        WeatherWidget()
        TodoListWidget()
        
        // 你还可以加入更多...
        // QuickActionWidget()
        // LockScreenSpecificWidget()
    }
}
```

## 3. 注意事项与限制

*   **数量限制**：早期的 iOS 版本中，一个 `WidgetBundle` 最多只能包含 5 个小组件（因为 Swift 的 `@Builder` 早期参数限制）。但现在的版本（特别是在拆分了多个内部 Bundle 的情况下）可以支持更多。不过，为了避免用户的 Widget 选择库过于臃肿，建议单个 App 暴露的核心小组件类型不要超过 5-8 种。
*   **Bundle 嵌套**：如果你有非常多的小组件，你可以将多个 `WidgetBundle` 嵌套在一起返回。
    ```swift
    @main
    struct MegaWidgetBundle: WidgetBundle {
        var body: some Widget {
            WeatherWidgetsBundle() // 这个本身也是一个 Bundle
            TodoWidgetsBundle()
            SettingsWidget()
        }
    }
    ```
*   **Target (Extension) 限制**：虽然你可以在一个 Extension 里塞入无数个小组件，但这会导致这个 Extension 的编译产物（二进制包）变大，内存消耗增加。如果这些小组件的逻辑差异极大（比如有些需要引入庞大的机器学习库，有些只是纯静态文本），在极端情况下可以考虑创建多个 Widget Extension Targets。但在绝大多数日常场景下，一个 Extension 配合一个 `WidgetBundle` 是最佳实践。