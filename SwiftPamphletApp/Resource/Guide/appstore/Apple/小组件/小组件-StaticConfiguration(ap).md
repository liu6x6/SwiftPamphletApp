# 小组件配置：StaticConfiguration

与允许用户进行长按编辑的 \`AppIntentConfiguration\` 不同，**\`StaticConfiguration\`** 用于创建那些**不需要、也不允许用户配置任何参数**的小组件。

当你开发的小组件只展示固定信息（例如：全局的系统状态、全站热榜、或者是基于 App 内当前登录账号自动推导出的个人信息面板）时，你应该使用它。

## 1. 核心架构

一个 \`StaticConfiguration\` 小组件由以下三部分组成：
1. **\`TimelineEntry\`**：定义数据模型的结构。
2. **\`TimelineProvider\`** (注意没有 AppIntent 前缀)：负责提供时间线数据。
3. **\`StaticConfiguration\`** 本身：将数据与视图绑定。

## 2. 编写 TimelineProvider

由于没有用户的 Intent 输入，Provider 的方法签名变得更加简单：

```swift
import WidgetKit

struct StaticNewsProvider: TimelineProvider {
    // 骨架屏数据
    func placeholder(in context: Context) -> NewsEntry {
        NewsEntry(date: Date(), headline: "正在加载最新头条...")
    }

    // 画廊预览
    func getSnapshot(in context: Context, completion: @escaping (NewsEntry) -> ()) {
        let entry = NewsEntry(date: Date(), headline: "苹果发布全新 iOS 18")
        completion(entry)
    }

    // 实际时间线
    func getTimeline(in context: Context, completion: @escaping (Timeline<NewsEntry>) -> ()) {
        // ... 发起网络请求获取头条数据 ...
        let currentEntry = NewsEntry(date: Date(), headline: "今日头条: ...")
        
        // 设定下一次刷新的时间 (例如 2 小时后)
        let refreshDate = Calendar.current.date(byAdding: .hour, value: 2, to: Date())!
        let timeline = Timeline(entries: [currentEntry], policy: .after(refreshDate))
        
        completion(timeline)
    }
}
```
*(注意：在纯 StaticConfiguration 中，iOS 17 前必须使用 completion 闭包。在最新的 SDK 中也有对 \`AppIntentTimelineProvider\` 的退化支持或直接使用 async 扩展的趋势，但基于老协议的 completion 仍是最标准的写法)*

## 3. 组装 StaticConfiguration

在主 \`Widget\` 结构体中，使用 \`StaticConfiguration\`：

```swift
import WidgetKit
import SwiftUI

struct NewsWidget: Widget {
    let kind: String = "com.myapp.widgets.news"

    var body: some WidgetConfiguration {
        // 核心区别：不再需要传入 intent: 参数
        StaticConfiguration(
            kind: kind, 
            provider: StaticNewsProvider()
        ) { entry in
            // 渲染视图
            NewsWidgetView(entry: entry)
        }
        .configurationDisplayName("热门资讯")
        .description("在桌面上时刻掌握最新科技动态。")
        // 设置支持的尺寸
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
```

## 4. 与 AppIntentConfiguration 的选择抉择

*   **选 Static**：
    *   步数/卡路里展示（数据固定来自 HealthKit，用户无需选）。
    *   当前播放的音乐（系统自动推断）。
    *   简单的“每日一句”格言。
*   **选 AppIntent**：
    *   天气应用（必须让用户选城市）。
    *   时钟应用（必须让用户选时区）。
    *   代办事项（用户想要选择显示“工作清单”还是“购物清单”）。
    *   **任何需要 iOS 17 \`Button\` 点击交互的小组件**（因为交互的底层逻辑也是靠 AppIntent 驱动的）。
