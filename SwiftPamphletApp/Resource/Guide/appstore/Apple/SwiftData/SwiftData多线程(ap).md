# SwiftData 的多线程处理

SwiftData （与其底层的 Core Data 一样）在多线程处理上有着严格的规则：**你绝对不能跨线程传递或使用同一个 `ModelContext` 或者由该 Context 获取到的受管对象 (`@Model`)。**

如果你在后台线程（如 `Task { }` 或 `DispatchQueue.global()`）中使用了属于主线程的 Context 或对象，应用大概率会发生竞态条件并导致崩溃 (Crash)。

## 1. Actor 与 ModelActor (推荐的现代多线程方案)

在 Swift 现代并发模型中，解决并发数据访问的最佳方案是使用 `Actor`。苹果专门为 SwiftData 提供了 `ModelActor` 协议，让你能够安全、便捷地在后台执行耗时的数据处理任务。

### 创建后台 ModelActor

创建一个遵循 `ModelActor` 的类型非常简单。Swift 宏会自动为你补全必须的实现代码（例如 `modelContainer` 和 `modelExecutor` 属性）。

```swift
import SwiftData
import Foundation

// 定义一个 Actor 并遵循 ModelActor 协议
@ModelActor
actor DataProcessor {
    
    // 自定义一个后台方法来执行大量数据抓取或更新
    func processMassiveData() throws {
        // 在 ModelActor 内部，你可以安全地使用内置的 `modelContext` 属性
        // 这个 context 是为这个 Actor 的后台队列专门创建的独立上下文
        
        let descriptor = FetchDescriptor<LogEntry>()
        let items = try modelContext.fetch(descriptor)
        
        for item in items {
            item.processed = true // 在后台更新属性
        }
        
        // 记得手动保存。由于它是后台上下文，没有自动保存功能。
        try modelContext.save()
    }
}
```

### 在视图或主线程中调用 ModelActor

为了让 `ModelActor` 工作，你需要在初始化它时，传入你的主 `ModelContainer`。容器本身是线程安全的，可以跨线程共享。

```swift
struct DataProcessingView: View {
    // 获取容器，而不是 Context
    @Environment(\.modelContainer) private var modelContainer
    
    var body: some View {
        Button("开始后台处理") {
            Task {
                // 1. 使用共享的 Container 初始化后台 Actor
                let processor = DataProcessor(modelContainer: modelContainer)
                
                // 2. 异步调用 Actor 内的方法，所有工作都在后台线程完成
                do {
                    try await processor.processMassiveData()
                    print("后台处理完成")
                } catch {
                    print("错误: \(error)")
                }
            }
        }
    }
}
```

## 2. 跨线程传递数据的唯一标识：PersistentIdentifier

正如开头所述，你不能直接把一个 `@Model` 对象传递给后台线程。如果你在 UI（主线程）选中了一个对象，并想在后台线程修改它，你必须传递该对象的**身份标识（ID）**，然后在后台线程根据这个 ID 重新抓取该对象。

在 SwiftData 中，这个身份标识就是 `PersistentIdentifier` (可以通过对象的 `id` 属性获取)。

```swift
@ModelActor
actor ItemUpdater {
    // 接收对象的 ID 而不是对象本身
    func updateItem(id: PersistentIdentifier, newTitle: String) throws {
        // 1. 在后台上下文中根据 ID 查找对象对应的本地内存模型
        // modelContext.model(for:) 是一种极其高效的按 ID 查询的方法
        if let localItem = try modelContext.model(for: id) as? Item {
            // 2. 修改属性
            localItem.title = newTitle
            
            // 3. 保存后台上下文
            try modelContext.save()
        }
    }
}

// ------ 主线程 UI 中的调用 ------ //
Button("后台修改当前选中项") {
    // 获取当前对象的 ID
    let currentItemID = selectedItem.id
    
    Task {
        let updater = ItemUpdater(modelContainer: container)
        // 传递 ID 给后台 Actor
        try await updater.updateItem(id: currentItemID, newTitle: "新标题")
    }
}
```

## 3. (不推荐的旧方法) 手动隔离与 backgroundContext

虽然你可以不用 Actor，而是手动提取 `ModelContainer` 并在 Task 中调用 `let backgroundContext = ModelContext(container)`，但这要求你必须极其小心地手动管理线程隔离边界，很容易出错。**在 SwiftData 中，强烈建议一律使用 `ModelActor` 来处理后台并发任务。**

## 总结

- **铁律**：`ModelContext` 和它内部的 `@Model` 对象是不安全的，**禁止跨线程使用**。
- **Container 是安全的**：`ModelContainer` 是线程安全的，可以传给后台。
- **使用 ModelActor**：所有在后台进行的数据加载、清洗和更新，封装到一个 `@ModelActor` 类中。
- **传递 ID，不传对象**：如果你需要告诉后台去处理某个特定对象，请传递它的 `persistentModelID`（即 `object.id`）。