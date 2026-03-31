# WidgetKit / 小组件 学习参考资料

Apple 从 iOS 14 开始引入了全新的 `WidgetKit`，彻底取代了原来基于 Today Extension 的旧版小组件。随着 iOS 16 (引入锁屏小组件) 和 iOS 17 (引入可交互小组件 Interactive Widgets)，小组件的生态变得越来越丰富。

以下是学习和掌握 WidgetKit 的核心参考资料：

## 1. Apple 官方资源 (WWDC)

官方的 WWDC 视频永远是理解 Apple 设计哲学和最佳实践的第一手资料。

*   **WWDC20: Meet WidgetKit**：(必看) WidgetKit 首次发布的介绍，讲解了 Timeline（时间线）、Provider 和 View 的核心概念。
*   **WWDC20: Build SwiftUI views for widgets**：讲解了在小组件这个极其受限的 SwiftUI 环境中，哪些视图能用，哪些不能用。
*   **WWDC22: Complications and widgets: Reloaded**：(必看) 讲解了 iOS 16 锁屏小组件（Accessory 家族）和 watchOS 复杂表盘的统一架构。
*   **WWDC23: Bring widgets to life**：(必看) 引入了基于 `AppIntent` 的**可交互小组件（Interactive Widgets）**，让小组件不再仅仅是只读的，而是可以直接点击按钮完成任务（如打钩 Todo 列表）。

**官方文档**：
*   [WidgetKit Framework Reference](https://developer.apple.com/documentation/widgetkit)
*   [App Intents Framework Reference](https://developer.apple.com/documentation/appintents)

## 2. 优质第三方博客与教程

*   **SwiftLee (Antoine van der Lee)**
    *   博客：*swiftlee.com*。Antoine 写了一系列关于 WidgetKit 的文章，特别是关于如何使用 `AppGroup` 在主 App 和 Widget Extension 之间共享 `UserDefaults` 和 Core Data 数据。
*   **Hacking with Swift (Paul Hudson)**
    *   提供了一整套关于构建 iOS 16 Lock Screen Widget 和 iOS 17 Interactive Widget 的快速入门代码片段。
*   **Fatbobman (肘子的 Swift 记事本)**
    *   对于国内开发者，肘子关于如何在 Widget 中优雅地使用 Core Data / SwiftData 刷新数据的文章是非常硬核且实用的。

## 3. 开源参考项目

*   **Backyard Birds (Apple 官方示例)**：iOS 17 随附的官方 Demo。它是学习如何将 SwiftData, App Intents 和 WidgetKit 结合在一起的最佳源码库。
*   **IceCubesApp**：一款开源的著名 Mastodon 客户端。你可以从中学习到一个成熟的大型应用是如何设计其多形态小组件的。

## 4. 核心概念速查

在开发时，经常需要回忆这几个词：
*   **Provider**：提供数据（Timeline）的大脑。
*   **TimelineEntry**：时间线上的一个数据节点，包含一个日期（Date）和你要展示的数据。
*   **StaticConfiguration**：不需要用户配置的小组件。
*   **AppIntentConfiguration**：(iOS 17+) 支持用户长按编辑配置，且支持按钮交互的小组件。