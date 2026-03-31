# AppIntentTimelineProvider 详解

从 iOS 17 开始，\`AppIntentTimelineProvider\` 是构建支持用户配置（Configuration）和小组件交互（Interactions）的核心协议。它彻底取代了旧版基于 SiriKit 的 \`IntentTimelineProvider\`。

## 1. 协议的核心职责

这个协议有三个主要任务，它告诉系统在不同生命周期下应该渲染什么样的小组件：

1.  **\`placeholder(in:)\`**：返回占位符数据。用于在网络差、首次加载、或处于极其严格隐私保护下（骨架屏）展示给用户。
2.  **\`snapshot(for:in:)\`**：返回快照数据。专门用于在**小组件画廊 (Widget Gallery)** 预览时展示。要求必须**立即（同步或极快的异步）**返回结果，绝对不能在这里发起耗时的网络请求。
3.  **\`timeline(for:in:)\`**：返回真实的时间线。这是小组件正常运行时的核心方法。你在这里发起网络请求、读取数据库，并规划未来几次的刷新策略。

## 2. 核心代码结构

```swift
import WidgetKit
import AppIntents

// 1. 数据模型必须遵循 TimelineEntry
struct WeatherEntry: TimelineEntry {
    let date: Date
    let temperature: Int
    let cityName: String
}

// 2. Provider 必须指定关联的 Intent (用户的配置项)
struct WeatherProvider: AppIntentTimelineProvider {
    // 告诉系统我们用哪个 Intent 来配置
    typealias Intent = SelectCityIntent
    typealias Entry = WeatherEntry

    // 提供骨架屏数据，UI上会自动加上 .redacted(reason: .placeholder) 效果
    func placeholder(in context: Context) -> WeatherEntry {
        WeatherEntry(date: Date(), temperature: 25, cityName: "Loading...")
    }

    // 画廊预览：立即返回一个假数据或缓存数据
    func snapshot(for configuration: SelectCityIntent, in context: Context) async -> WeatherEntry {
        WeatherEntry(date: Date(), temperature: 22, cityName: configuration.city)
    }

    // 真实时间线生成
    func timeline(for configuration: SelectCityIntent, in context: Context) async -> Timeline<WeatherEntry> {
        // 1. 获取用户在背面配置的参数
        let selectedCity = configuration.city
        
        // 2. 异步拉取数据 (支持 async/await 极大简化了代码)
        let currentTemp = await fetchWeather(for: selectedCity)
        
        // 3. 生成当前节点
        let entry = WeatherEntry(date: Date(), temperature: currentTemp, cityName: selectedCity)
        
        // 4. 设定刷新策略：告诉系统 1 小时后再来要数据
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
    
    // 模拟的网络请求
    private func fetchWeather(for city: String) async -> Int {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        return Int.random(in: 10...35)
    }
}
```

## 3. iOS 17 的 Async/Await 优势

相比于 iOS 14-16 的老版本 Provider（必须使用 \`completion\` 闭包），\`AppIntentTimelineProvider\` 全面支持了 Swift 并发模型。
这意味着你可以在 \`timeline\` 方法中直观地使用 \`try await URLSession.shared.data(from:)\` 来请求数据，彻底告别回调地狱，代码更加线性和安全。
