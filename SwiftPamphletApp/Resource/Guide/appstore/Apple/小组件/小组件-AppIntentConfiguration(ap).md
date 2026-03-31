# 小组件：AppIntentConfiguration 详解

在 WidgetKit 中，有两种主要的小组件配置方式：`StaticConfiguration`（静态配置，无需用户设置）和 `AppIntentConfiguration`（基于意图的动态配置）。

从 iOS 17 开始，Apple 全面拥弃了旧的 `IntentConfiguration`（基于 SiriKit / .intentdefinition 文件），转而**强烈推荐使用基于纯 Swift 编写的 `AppIntentConfiguration`**。

它不仅让用户能长按小组件进行个性化设置（比如选择要看哪个城市的城市天气，选择要看哪个股票池），更是实现**iOS 17 可交互小组件（Interactive Widgets，如直接在桌面上点击打钩任务）**的绝对底层基石。

## 1. 核心组成部分

要构建一个支持 `AppIntentConfiguration` 的小组件，你需要：
1.  **一个 `AppIntent` (意图)**：这是一个遵循 `WidgetConfigurationIntent` 协议的 Swift 结构体，用于定义用户可以配置哪些参数（属性）。
2.  **一个 `AppIntentTimelineProvider` (时间线提供者)**：负责根据用户配置好的 `AppIntent` 去拉取数据并生成时间线。

## 2. 定义 AppIntent (用户配置项)

我们定义一个让用户选择“主题角色”的配置：

```swift
import AppIntents
import WidgetKit

// 必须遵循 WidgetConfigurationIntent
struct SelectCharacterIntent: WidgetConfigurationIntent {
    // 给配置起个名字和描述
    static var title: LocalizedStringResource = "选择角色"
    static var description = IntentDescription("选择你想在桌面上显示的角色。")

    // 使用 @Parameter 宏定义一个可以被用户配置的选项
    // 系统会自动在长按小组件的背面生成一个输入框或选择列表
    @Parameter(title: "角色名称", default: "Mario")
    var characterName: String
    
    // 支持布尔值作为开关
    @Parameter(title: "显示等级", default: true)
    var showLevel: Bool
}
```

## 3. 实现 AppIntentTimelineProvider

这个 Provider 会把用户刚才填写的 `SelectCharacterIntent` 当作参数传递进来。

```swift
struct CharacterTimelineProvider: AppIntentTimelineProvider {
    // 占位符视图数据
    func placeholder(in context: Context) -> CharacterEntry {
        CharacterEntry(date: Date(), name: "Mario", levelVisible: true)
    }

    // 用户在小组件画廊预览时看到的数据
    func snapshot(for configuration: SelectCharacterIntent, in context: Context) async -> CharacterEntry {
        CharacterEntry(date: Date(), name: configuration.characterName, levelVisible: configuration.showLevel)
    }

    // 核心逻辑：根据用户的配置，生成真实的时间线
    func timeline(for configuration: SelectCharacterIntent, in context: Context) async -> Timeline<CharacterEntry> {
        // 从 configuration 中取出用户的选择！
        let selectedName = configuration.characterName
        let isLevelVisible = configuration.showLevel
        
        // （伪代码）去数据库或网络查询这个角色的数据...
        let entry = CharacterEntry(date: Date(), name: selectedName, levelVisible: isLevelVisible)
        
        // 永远不再刷新，除非用户改了配置或主 App 发起通知
        return Timeline(entries: [entry], policy: .never)
    }
}

// 时间线的数据模型
struct CharacterEntry: TimelineEntry {
    let date: Date
    let name: String
    let levelVisible: Bool
}
```

## 4. 组装配置 Configuration

最后，在你的 `Widget` 结构体中使用 `AppIntentConfiguration` 把它们拼接起来。

```swift
struct CharacterWidget: Widget {
    let kind: String = "CharacterWidget"

    var body: some WidgetConfiguration {
        // 使用 AppIntentConfiguration
        AppIntentConfiguration(
            kind: kind,
            intent: SelectCharacterIntent.self, // 传入你定义的 Intent 类型
            provider: CharacterTimelineProvider() // 传入对应的 Provider
        ) { entry in
            // 根据 entry 的数据渲染 UI
            CharacterWidgetView(entry: entry)
        }
        .configurationDisplayName("我的角色")
        .description("在桌面上时刻关注你的角色。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
```

## 总结
*   废弃旧的 `.intentdefinition` 可视化文件配置，全面转向纯 Swift 的 `AppIntents` 框架。
*   通过 `@Parameter` 让系统自动生成小组件背面的设置界面。
*   Provider 的核心回调参数现在变成你定义的强类型 Intent，直接读取配置参数，拒绝硬编码。