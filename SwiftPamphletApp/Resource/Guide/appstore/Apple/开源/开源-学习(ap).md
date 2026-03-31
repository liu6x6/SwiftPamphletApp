# Apple 平台开源学习资源与教程项目

除了完整的 App 源码，GitHub 上还有许多专门为了“教学”和“演示新特性”而存在的开源项目。这些项目通常代码精简、注释详尽，是学习特定技术栈的绝佳起点。

## 1. Apple 官方提供的 Demo 代码

Apple 开发者网站和每年的 WWDC 都会释放出极具含金量的官方示例代码。这些代码代表了苹果官方钦定的“最佳实践”。

*   **Fruta / Backyard Birds**
    *   **简介**：这是苹果用于展示 SwiftUI 跨平台能力（iOS, macOS, watchOS, widget）和 SwiftData 的官方示范应用。
    *   **学习点**：如何在一套代码库中通过条件编译和 \`ViewModifier\` 适配不同尺寸的屏幕；SwiftData 的标准用法。
*   **Food Truck**
    *   **简介**：主要展示 Live Activities (实时活动) 和 Dynamic Island (灵动岛) 甚至 App App Intents 的使用。
    *   **学习点**：WidgetKit 的高阶交互、ActivityKit 完整生命周期。

## 2. 顶级技术博客的附属源码库

许多知名的 Swift 博主不仅写文章，还会把文章中的代码整理成可运行的仓库。

*   **Hacking with Swift (100 Days of SwiftUI)**
    *   **简介**：Paul Hudson 的《100 Days of SwiftUI》是全球最受欢迎的 SwiftUI 入门教程。他的 GitHub 仓库里包含了这 100 天所有的练习项目源码。
    *   **学习点**：从基础的 \`@State\` 到复杂的 \`NavigationStack\` 路由，循序渐进。
*   **Swift by Sundell 示例代码**
    *   **简介**：John Sundell 的博客代码。
    *   **学习点**：涵盖极其硬核的 Swift 语言特性（如 Opaque Types, Property Wrappers，最新的 Concurrency 并发模型）。

## 3. 大厂架构与组件库开源

*   **RIBs (Uber)**
    *   **简介**：Uber 开源的跨平台架构框架。
    *   **学习点**：如何为数百人协作的超级 App 设计严格的路由和业务隔离。虽然非常重，但其思想值得学习。
*   **Texture / AsyncDisplayKit (由 Pinterest 和 Facebook 开发)**
    *   **简介**：虽然现在已不太活跃，但它曾经是解决 iOS 复杂列表滚动卡顿的“神级框架”。
    *   **学习点**：它展示了如何在后台线程预先计算 UI 布局并将绘制任务异步化，理解了它，你就彻底理解了 iOS 的 RunLoop 和渲染管线原理。

## 4. 算法与数据结构

*   **swift-algorithm-club**
    *   **简介**：Ray Wenderlich 社区维护的，用 Swift 语言实现的所有经典算法和数据结构。
    *   **学习点**：准备 iOS 面试的必看项目。通过它你可以学习到如何使用 Swift 优雅的泛型和高阶函数来写出极简的排序、树、图等算法。
