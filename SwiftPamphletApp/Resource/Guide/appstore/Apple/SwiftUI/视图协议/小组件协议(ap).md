# SwiftUI 与 WidgetKit：小组件相关协议

自 iOS 14 起，苹果引入了主屏幕小组件（Widgets），允许应用以一种美观、信息密集的方式在主屏幕上展示内容。构建小组件的核心是 **WidgetKit** 框架，它与 SwiftUI 紧密集成，并依赖于一套特定的协议来定义小组件的行为和外观。

## WidgetKit 的核心架构

WidgetKit 的工作方式是**时间线驱动**的。你的应用并不直接控制小组件的实时渲染，而是向系统提供一个“时间线”（Timeline），其中包含了一系列在未来特定时间点要显示的视图和数据。系统会根据这个时间线，在合适的时机（如电池电量、性能负载允许时）更新小组件的显示。

构建一个小组件主要涉及以下几个关键协议：

1.  **`Widget`**: 定义小组件的配置和内容的顶层协议。
2.  **`TimelineProvider`**: 负责为小组件生成时间线，告诉系统何时以及如何更新小组件。
3.  **`TimelineEntry`**: 定义了在时间线上某个特定时间点展示的数据模型。

## 1. `Widget` 协议

`Widget` 是你小组件的入口点。你需要创建一个遵循此协议的结构体，并在其 `body` 中返回一个 `WidgetConfiguration`。

```swift
import WidgetKit
import SwiftUI

@main
struct MyAwesomeWidget: Widget {
    let kind: String = "com.myapp.myawesomewidget" // 小组件的唯一标识符

    var body: some WidgetConfiguration {
        // 使用 StaticConfiguration 或 IntentConfiguration
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            // 这是小组件的 SwiftUI 视图
            MyAwesomeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("我的小组件")
        .description("这是一个展示信息的示例小组件。")
        .supportedFamilies([.systemSmall, .systemMedium]) // 支持的尺寸
    }
}
```

*   **`kind`**: 一个唯一的字符串，用于在系统中标识你的小组件。
*   **`WidgetConfiguration`**: 有两种类型：
    *   **`StaticConfiguration`**: 用于不需要用户配置的、静态的小组件。
    *   **`IntentConfiguration`**: 用于用户可配置的小组件（例如，选择显示哪个城市的天气）。这需要与 SiriKit 的 `Intents` 框架结合使用。
*   **`.configurationDisplayName` & `.description`**: 在小组件库中向用户显示的名称和描述。
*   **`.supportedFamilies`**: 声明你的小组件支持哪些尺寸（`.systemSmall`, `.systemMedium`, `.systemLarge`, 以及锁屏和 watchOS 的尺寸）。

## 2. `TimelineProvider` 协议

`TimelineProvider` 是小组件的“大脑”，它负责告诉 WidgetKit 何时更新小组件。你需要实现三个方法：

*   **`placeholder(in:) -> Entry`**: 提供一个用于“占位符”状态的 `TimelineEntry`。当系统首次显示小组件或在无法获取真实数据时，会使用这个占位符视图。

*   **`getSnapshot(in:completion:)`**: 提供一个用于在小组件库等瞬时场景下展示的、单个的 `TimelineEntry`。你应该在这里提供一个具有代表性的、真实的数据快照。

*   **`getTimeline(in:completion:)`**: 这是最核心的方法。你需要在这里创建一个 `Timeline` 对象，其中包含一个 `TimelineEntry` 数组和一 个**刷新策略** (`TimelineReloadPolicy`)。

```swift
struct Provider: TimelineProvider {
    // ... placeholder() 和 getSnapshot() ...

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [MyWidgetEntry] = []

        // 创建一个从现在开始，每小时更新一次的时间线，持续5个小时
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            // 在这里获取你的真实数据
            let entry = MyWidgetEntry(date: entryDate, data: fetchData(for: entryDate))
            entries.append(entry)
        }

        // 创建时间线，并设置刷新策略为在最后一个条目显示后刷新
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}
```

**`TimelineReloadPolicy`** 刷新策略决定了下一次调用 `getTimeline` 的时机：
*   `.atEnd`: 当时间线上最后一个条目显示完毕后，请求新的时间线。
*   `.after(Date)`: 在指定的未来某个时间点后，请求新的时间线。
*   `.never`: 永不自动请求新的时间线。你需要通过 `WidgetCenter.shared.reloadTimelines(ofKind:)` 来手动触发刷新。

## 3. `TimelineEntry` 协议

`TimelineEntry` 是一个非常简单的协议，它只要求你的数据模型有一个 `date` 属性。这个 `date` 属性告诉系统，这个条目应该在何时显示。

```swift
import WidgetKit

struct MyWidgetEntry: TimelineEntry {
    let date: Date // 必须实现的属性
    
    // 你自己的自定义数据
    let temperature: Double
    let weatherCondition: String
}
```

你的小组件 SwiftUI 视图会接收这个 `TimelineEntry` 作为其数据源。

```swift
struct MyAwesomeWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text("温度: \(entry.temperature, specifier: "%.1f")°")
            Text(entry.weatherCondition)
            Text("更新于: \(entry.date, style: .time)")
        }
    }
}
```

## 交互性 (iOS 17+)

从 iOS 17 开始，小组件变得具有交互性。你可以使用 `Button` 和 `Toggle` 来触发 **App Intents**。

```swift
// 1. 定义一个 App Intent
struct MyActionIntent: AppIntent {
    static var title: LocalizedStringResource = "我的操作"
    func perform() async throws -> some IntentResult { .result() }
}

// 2. 在小组件视图中使用 Button
struct InteractiveWidgetView: View {
    var body: some View {
        Button(intent: MyActionIntent()) {
            Label("执行操作", systemImage: "star")
        }
        .buttonStyle(.bordered)
    }
}
```

当用户点击这个按钮时，系统会在后台执行 `MyActionIntent` 的 `perform()` 方法，而不会打开主应用。

## 总结

WidgetKit 通过一套清晰的协议，将小组件的 UI（由 SwiftUI 负责）、数据（由 `TimelineEntry` 定义）和更新逻辑（由 `TimelineProvider` 管理）分离开来。

*   **`Widget`**: 小组件的配置入口。
*   **`TimelineProvider`**: 提供数据和更新计划，是小组件的“大脑”。
*   **`TimelineEntry`**: 定义在特定时间点显示的数据模型。

通过遵循这些协议，你可以将你的应用核心信息以一种高效、美观且省电的方式呈现在用户的主屏幕上。
