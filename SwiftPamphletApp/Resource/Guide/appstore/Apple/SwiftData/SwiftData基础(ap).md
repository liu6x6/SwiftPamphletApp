# SwiftData 基础

SwiftData 是 Apple 在 WWDC23 推出的一款全新的数据持久化框架。它专门为 Swift 和 SwiftUI 设计，利用了 Swift 的宏（Macros）功能，以极其声明式和简洁的方式让开发者管理应用的数据模型。

## 核心优势

- **声明式 API**：通过简单的 `@Model` 宏即可定义数据模型，无需繁琐的 XML 或外部模型编辑器。
- **与 SwiftUI 深度集成**：完全贴合 SwiftUI 的数据流，使用 `@Query` 可以自动驱动视图更新。
- **底层基于 Core Data**：虽然 API 是全新的、纯 Swift 的，但 SwiftData 底层依然是由成熟、强大的 Core Data 引擎驱动。这意味着它继承了 Core Data 的高性能、安全性和 iCloud 同步（CloudKit）能力。
- **类型安全**：借助 Swift 的强类型系统，在编译期就能捕获许多潜在的错误。

## SwiftData 的三大核心概念

要掌握 SwiftData，需要理解以下三个核心组件：

1. **`@Model` (模型)**
   使用 `@Model` 宏标记普通的 Swift class，将其转换为受系统管理的数据模型。它描述了应用中的实体以及它们的属性和关系。

2. **`ModelContainer` (模型容器)**
   负责管理数据模型的存储后端。它充当应用和底层数据库（如 SQLite）之间的桥梁。决定了数据存放在哪里（磁盘、内存）以及如何存储。

3. **`ModelContext` (模型上下文)**
   它是你与数据交互的“工作区”。所有的增（Insert）、删（Delete）、改（Update）、查（Fetch）操作都在 `ModelContext` 中进行。它可以追踪内存中数据的变化，并负责将这些变化保存到容器中。

## 基础使用流程概览

1. **定义模型**：使用 `@Model` 宏修饰 class。
2. **注入容器**：在 App 的根视图或顶层视图使用 `.modelContainer(for:)` 修饰符注入。
3. **获取上下文**：在需要操作数据的视图中，通过 `@Environment(\.modelContext) var context` 获取环境中的上下文。
4. **查询与展示**：使用 `@Query` 宏在 SwiftUI 视图中获取数据列表并自动更新视图。

## 适用平台要求

由于 SwiftData 严重依赖 Swift 5.9 的宏特性，它有明确的系统要求：
- **iOS 17.0+**
- **macOS 14.0+**
- **tvOS 17.0+**
- **watchOS 10.0+**
- **visionOS 1.0+**