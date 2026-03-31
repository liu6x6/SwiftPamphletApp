# 小组件访问 SwiftData 数据

如果你的主 App 使用了 iOS 17 引入的 \`SwiftData\` 进行本地持久化，你必然会希望在桌面的小组件中展示这些数据（比如展示最高优先级的 3 个任务）。

由于主 App 和 Widget Extension 是**两个完全独立的进程**，它们运行在操作系统的不同沙盒中。让它们共享同一个 SwiftData 数据库，需要配置 \`App Groups\` 并定制 \`ModelContainer\`。

## 步骤 1：配置 App Groups

这是所有跨进程数据共享的基础。
1. 在 Xcode 的主 Target 中，前往 **Signing & Capabilities**，点击 **+ Capability** 添加 **App Groups**。
2. 创建一个标识符，通常格式为：\`group.com.yourcompany.yourapp\`。
3. 切换到你的 **Widget Extension Target**，同样添加 App Groups，并**勾选刚才创建的同一个标识符**。

## 步骤 2：主 App：将数据库文件存入共享组目录

默认情况下，SwiftData 会把底层的 SQLite 文件存在主 App 独占的 Application Support 目录下。我们需要写一个自定义配置，强制它把文件写在刚才配置的 App Group 共享目录下。

**在主 App 中 (\`@main\` 文件):**

```swift
import SwiftUI
import SwiftData

@main
struct MyApp: App {
    let sharedContainer: ModelContainer

    init() {
        do {
            // 1. 获取 App Group 的共享目录 URL
            guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.yourcompany.yourapp") else {
                fatalError("无法获取 AppGroup 路径")
            }
            
            // 2. 指定数据库文件的绝对路径
            let databaseURL = appGroupURL.appendingPathComponent("sharedData.sqlite")
            
            // 3. 使用这个特定的 URL 创建配置
            let config = ModelConfiguration(url: databaseURL)
            
            // 4. 初始化容器
            sharedContainer = try ModelContainer(for: TodoItem.self, configurations: config)
            
        } catch {
            fatalError("创建共享容器失败: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedContainer) // 注入
    }
}
```

## 步骤 3：Widget：读取共享数据库

在小组件端，我们不能使用 SwiftUI 的 \`.modelContainer\` 和 \`@Query\`（因为小组件的数据抓取发生在后端的 \`Provider\` 里，而不是视图层）。我们必须**手动实例化**一个 \`ModelContext\` 来抓取数据。

**在 Widget 的 \`TimelineProvider\` 中:**

```swift
struct TodoTimelineProvider: TimelineProvider {
    
    // 这是一个帮助方法，用于在小组件中安全地获取共享的上下文
    @MainActor
    private func getSharedContext() -> ModelContext? {
        guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.yourcompany.yourapp") else {
            return nil
        }
        let databaseURL = appGroupURL.appendingPathComponent("sharedData.sqlite")
        let config = ModelConfiguration(url: databaseURL)
        
        do {
            // 在 Widget 侧使用相同的模型和路径初始化容器
            let container = try ModelContainer(for: TodoItem.self, configurations: config)
            return container.mainContext
        } catch {
            print("Widget 读取数据库失败: \(error)")
            return nil
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodoEntry>) -> ()) {
        // 由于 SwiftData 的上下文必须运行在 MainActor (或者专属的 ModelActor)，我们需要把它包裹在 Task 中
        Task { @MainActor in
            guard let context = getSharedContext() else {
                completion(Timeline(entries: [TodoEntry(date: Date(), items: [])], policy: .never))
                return
            }
            
            // 使用 FetchDescriptor 手动抓取数据
            var descriptor = FetchDescriptor<TodoItem>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
            descriptor.fetchLimit = 3 // 比如只显示前 3 条
            
            do {
                let items = try context.fetch(descriptor)
                // 生成 Entry
                let entry = TodoEntry(date: Date(), items: items)
                completion(Timeline(entries: [entry], policy: .never)) // 依赖主App主动唤醒刷新
            } catch {
                completion(Timeline(entries: [TodoEntry(date: Date(), items: [])], policy: .never))
            }
        }
    }
}
```

## 步骤 4：主干联动 (主动唤醒)

就像在《刷新小组件(ap).md》中提到的一样，设置 \`policy: .never\` 意味着你的小组件在数据发生变化前不会主动吃力不讨好地去查库。
**必须在主 App 中**，当你执行了 \`context.insert()\` 或 \`context.delete()\` 后，主动调用一句：

```swift
import WidgetKit
WidgetCenter.shared.reloadAllTimelines()
```
从而通知小组件去共享目录里读取最新的 SwiftData 数据并刷新 UI。
