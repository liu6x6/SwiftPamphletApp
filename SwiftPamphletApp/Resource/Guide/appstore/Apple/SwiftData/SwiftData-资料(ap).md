# SwiftData 学习资料与参考资源

随着苹果在 WWDC23 发布 SwiftData，社区和官方涌现了大量的学习资料。以下是一些精选的学习资源，按官方和第三方进行分类，帮助你快速掌握并精通 SwiftData。

## 1. Apple 官方资源 (WWDC Sessions)

苹果官方的视频是理解 SwiftData 设计哲学和最佳实践的最权威途径。

**WWDC23 (发布年):**
*   **Meet SwiftData**：必看的入门视频。介绍了 `@Model`、`ModelContainer` 和 `@Query` 的基础用法。
*   **Model your schema with SwiftData**：深入讲解如何设计数据模型、处理关联关系 (`@Relationship`) 以及独特的属性约束 (`@Attribute`)。
*   **Dive deeper into SwiftData**：进阶内容。涵盖了与 Core Data 的共存、自定义 `ModelContainer` 配置以及如何在不使用 `@Query` 的情况下手动管理 `ModelContext`。
*   **Build an app with SwiftData**：一个完整的实战演示，展示了如何在 SwiftUI 应用中从头开始集成 SwiftData。

**WWDC24 (更新与增强):**
*   *建议搜索 WWDC24 中关于 SwiftData 的更新（例如对于复杂查询、多线程Actor的支持增强以及更多的定制化配置）。*

**官方文档:**
*   [SwiftData 框架官方文档](https://developer.apple.com/documentation/swiftdata)：查阅 API 细节、宏定义参数的必备字典。

## 2. 优秀的第三方技术博客与教程

许多知名的 Swift 开发者和博客详细拆解了 SwiftData，提供了比官方文档更接地气的实战经验和避坑指南。

*   **Hacking with Swift (Paul Hudson)**
    *   *专栏：SwiftData Tutorial*。Paul 提供了一套极其全面且容易上手的文字版教程，从零开始搭建，涵盖了增删改查、排序、过滤以及迁移等所有核心话题。
*   **Fatbobman (肘子的 Swift 记事本)**
    *   *博客：[fatbobman.com](https://fatbobman.com/)*。作为 Core Data 领域的资深专家，肘子对 SwiftData 的底层机制、它与 Core Data 的对比、以及并发处理 (ModelActor) 都有极其深入的中文剖析，强烈推荐进阶开发者阅读。
*   **Swift by Sundell**
    *   提供了很多关于如何将 SwiftData 与最新的 SwiftUI 新特性（如 `NavigationStack`、`Observation`）结合使用的代码片段和架构探讨。
*   **Donny Wals (SwiftLee)**
    *   详细讲解了如何在非 SwiftUI 的环境（如后台任务、架构层）中优雅地使用 `ModelContext` 和 `FetchDescriptor`。

## 3. 开源示例项目

通过阅读别人写好的优秀代码是学习最快的方式。

*   **苹果官方的 "Backyard Birds" 示例 App**：Apple 官方提供的完整应用源码，完美展示了 SwiftData 与 SwiftUI 的最佳实践。
*   **Github 上的开源项目**：在 GitHub 搜索 `topic:swiftdata`，你可以找到许多开发者重构的 Todo-List、记账本等小型 Demo，可以用来参考它们的 Schema 迁移和多线程架构。

## 4. 社区与求助

如果在开发中遇到了奇怪的崩溃或者由于宏展开带来的编译错误，你可以前往以下地方寻找答案：
*   **Apple Developer Forums (Data Management 区)**
*   **Stack Overflow (标签: swiftdata)**
*   **X (Twitter)**：关注 `#SwiftData` 标签，许多 iOS 大牛会在这里分享他们发现的 Undocumented Features (未在文档中写明的特性) 或是系统 Bug 的临时解决方案 (Workaround)。