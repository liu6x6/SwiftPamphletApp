# SwiftData 和 CoreData 的关系与共存

SwiftData 和 Core Data 并不是水火不容的竞争对手，而是**前台（API 层）与后台（引擎层）**的关系。理解它们之间的联系，对于开发复杂的 iOS/macOS 应用至关重要。

## 1. SwiftData 的底层就是 Core Data

这是最重要的一点：**SwiftData 的底层存储引擎完全是建立在 Core Data 之上的。**
当你使用 `@Model` 宏并在 App 中配置 `ModelContainer` 时，SwiftData 在幕后实际上创建了一个封装好的 Core Data 栈（包括 `NSPersistentContainer`、`NSManagedObjectContext` 和底层的 SQLite 数据库）。

这意味着 SwiftData 天生就继承了 Core Data 十几年发展积累下来的全部优势：
- 高效的 SQLite 查询和存储
- 内存管理（Faulting 惰性加载）
- 与 CloudKit 的无缝同步
- 事务与并发处理的底层保障

## 2. 为什么还要推出 SwiftData？

尽管 Core Data 极其强大，但它的 API 是基于 Objective-C 时代的动态特性设计的。
- **Core Data 的痛点**：你需要使用外部的模型编辑器（`.xcdatamodeld` 文件），生成的 `NSManagedObject` 代码十分冗长，而且它与现代声明式的 SwiftUI（特别是基于 `@State` 和 `@Observable` 的数据流）结合起来相当繁琐和不自然。
- **SwiftData 的使命**：利用 Swift 5.9 的宏 (Macros) 技术，提供一套**纯 Swift 的、类型安全的、高度声明式的** API，彻底抛弃外部模型编辑器，完美融入 SwiftUI。

## 3. 两者的共存与混合使用 (Coexistence)

苹果在设计 SwiftData 时考虑到了庞大的老项目生态。你**完全可以在同一个 App，甚至同一个底层 SQLite 数据库中，同时使用 Core Data 和 SwiftData。**

### 同步同一个底层数据库

因为 SwiftData 就是构建在 Core Data 之上的，只要它们的“模型定义 (Schema)”是一致的，它们就可以读写同一个物理文件。

当你有一个庞大的 Core Data 旧项目想要逐步迁移时，这是最佳途径：
1. 不要删除现有的 Core Data 栈和 `.xcdatamodeld`。
2. 针对你现有的 `NSManagedObject` 类，写一个对应的 `@Model` 类。**必须确保类名、属性名、类型完全匹配。**
3. 使用同一个文件 URL 去初始化你的 `ModelContainer` (SwiftData) 和 `NSPersistentContainer` (Core Data)。
4. 新的 SwiftUI 视图使用 SwiftData 的 `@Query` 查数据。旧的 UIKit 控制器继续使用 `NSFetchedResultsController`。
5. 两边无论谁改了数据并保存到 SQLite 中，另一边都能通过持久化历史追踪 (Persistent History Tracking) 获得更新。

## 4. 如何选择？

对于现在的新项目，如何进行技术选型？

*   **首选 SwiftData**：如果你的项目是要求 iOS 17+ / macOS 14+ 的全新项目，并且主要使用 SwiftUI 构建，**毫无疑问应该直接使用 SwiftData**。它的开发体验、代码简洁度远超 Core Data。
*   **选择 Core Data**：
    1. 你需要支持 iOS 16 及更低版本。
    2. 你需要使用 `NSFetchedResultsController` 驱动复杂的 `UITableView` 或 `UICollectionView`。
    3. 你的应用属于极其复杂的企业级架构，需要用到一些 SwiftData 暂不支持的边缘特性（如极其深度的、手动的 `NSUndoManager` 底层控制，或是某些特殊的持久化存储类型）。

## 总结

你可以把 Core Data 看作是“内燃机”，而 SwiftData 则是最新款的“智能中控台”。你不需要把内燃机拆了重做，SwiftData 只是给了你一个更容易、更现代、更安全的驾驶体验。