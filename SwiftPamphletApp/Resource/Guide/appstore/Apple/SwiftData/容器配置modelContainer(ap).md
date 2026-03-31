# 容器配置 ModelContainer

`ModelContainer` 是 SwiftData 架构中负责管理持久化存储后端的核心组件。它起着连接你定义的 `@Model` 模型和底层存储机制（比如 SQLite 数据库、内存存储、或者 iCloud）的桥梁作用。

在所有的 SwiftData 操作开始之前，你必须在你的应用程序中创建并配置一个 `ModelContainer`。

## 1. 基础容器配置（快捷方式）

如果你的应用需求非常简单，SwiftData 提供了一个用于 SwiftUI 的便捷视图修饰符 `.modelContainer(for:)`。这个修饰符通常在你的 App 入口点调用。

```swift
import SwiftUI
import SwiftData

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // 告诉 SwiftData 管理哪些模型。不需要传入相互引用的模型。
        .modelContainer(for: [Recipe.self, Ingredient.self])
    }
}
```
**关键点**：SwiftData 是智能的。如果你将 `Recipe.self` 传入了 `for:`，并且 `Recipe` 内部有一个指向 `Ingredient` 的关联关系，即使你不显式提供 `Ingredient.self`，容器也会自动将其识别并包含进来。

## 2. 高级容器配置（ModelConfiguration）

当需要对底层存储的行为进行深度控制时（如只读数据库、修改数据库文件的保存路径、内存存储，或是禁用自动保存），你需要创建一个自定义的 `ModelConfiguration`，并用它来初始化一个显式的 `ModelContainer`。

```swift
import SwiftUI
import SwiftData

@main
struct MyApp: App {
    
    // 显式创建一个容器实例
    let container: ModelContainer
    
    init() {
        do {
            // 第一步：定义配置
            // isStoredInMemoryOnly: true 表示所有数据都仅存在于内存中，应用重启后数据丢失
            // allowsSave: true 允许数据被保存。如果是提供给用户查看的静态预置数据，可以设为 false。
            let config = ModelConfiguration(
                isStoredInMemoryOnly: true, // 非常适合用来构建 SwiftUI Preview 的 mock 数据
                allowsSave: true 
            )
            
            // 第二步：使用你的模型和自定义配置来实例化 ModelContainer
            container = try ModelContainer(for: Recipe.self, configurations: config)
        } catch {
            fatalError("无法初始化 ModelContainer: \(error.localizedDescription)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // 使用实例化的 container，而不是传入类型
        .modelContainer(container)
    }
}
```

## 3. 多重配置 (Multiple Configurations)

如果你有多个不同的存储区域需求（例如，部分数据持久化到磁盘以便持久保存，另一部分敏感数据或缓存数据只存储在内存中），你可以向 `ModelContainer` 传递多个 `ModelConfiguration`。

为了实现这一点，`ModelConfiguration` 允许按模型的类型进行筛选。

```swift
let diskConfig = ModelConfiguration(for: UserProfile.self)
let memoryConfig = ModelConfiguration(for: SearchCache.self, isStoredInMemoryOnly: true)

let container = try ModelContainer(for: UserProfile.self, SearchCache.self, configurations: diskConfig, memoryConfig)
```

## 4. 在 SwiftUI Preview 中的应用

由于 `ModelContainer` 可以配置为基于内存，这对于我们构建不会污染实际数据库的 Preview 环境极其有用。

```swift
#Preview {
    // 创建一个临时的内存存储
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Recipe.self, configurations: config)
    
    // 生成假数据
    let mockRecipe = Recipe(title: "番茄炒蛋")
    container.mainContext.insert(mockRecipe)
    
    return ContentView()
        .modelContainer(container) // 将配置好的临时环境注入到预览视图
}
```

## 总结

- `ModelContainer` 掌管底层的物理存储（默认是位于应用沙盒内的 SQLite 文件）。
- `.modelContainer(for:)` 是一种将配置和注入结合的简便修饰符，主要用在 `App` 结构体或 `WindowGroup` 层级。
- 进阶场景需要手动初始化 `ModelConfiguration` 以便定制内存存储、只读数据库等复杂配置。
- 在 SwiftUI Preview 中，通过传入 `ModelConfiguration(isStoredInMemoryOnly: true)` 可以避免测试数据混入真实应用的数据库。