# SwiftData 的版本迁移 (Migration)

随着应用的不断迭代，你的数据模型（`@Model`）必然会发生变化——你可能会添加新属性、删除旧字段、或者重命名某个模型。如果用户设备上已经存在了基于旧模型的数据库，直接运行新代码会导致应用崩溃。为了解决这个问题，SwiftData 提供了强大的模型迁移 (Model Migration) 机制。

SwiftData 的迁移分为两类：**轻量级自动迁移** 和 **自定义迁移**。

## 1. 自动迁移 (Lightweight / Automatic Migration)

如果你的改动非常简单，SwiftData 可以自动推断并执行迁移，你不需要编写任何额外的迁移代码。

支持自动迁移的改动包括：
*   **添加新属性**：并且给这个新属性提供了一个默认值（或者将其设为 Optional `?`）。
*   **删除属性**：直接从代码中删掉某个 `var`。
*   **重命名属性/模型 (需加标记)**：如果你只是想改代码里的名字，但不丢失数据库里的旧数据，你需要使用 `@Attribute(originalName:)` 或给类加 `@Model(originalName:)` 宏来告诉底层数据库。

```swift
// V1 版本
@Model
class User {
    var name: String
    init(name: String) { self.name = name }
}

// V2 版本：添加新属性，自动迁移
@Model
class User {
    var name: String
    var age: Int? // 新增可选属性，自动迁移支持
    // var age: Int = 18 // 或者提供默认值，自动迁移也支持
    
    // 如果你把 name 改成了 fullName，需要这样写才能保留原有数据：
    // @Attribute(originalName: "name") var fullName: String
    
    init(name: String, age: Int? = nil) {
        self.name = name
        self.age = age
    }
}
```
*在自动迁移下，只要你启动 App，SwiftData 就会在幕后默默把底层的 SQLite 表结构升级。*

## 2. 自定义迁移 (Custom Migration)

当模型的结构发生了破坏性改变，或者你需要对旧数据进行逻辑计算后再存入新字段时（例如：把 `firstName` 和 `lastName` 合并为一个 `fullName` 字段），自动迁移就无能为力了。你必须使用 `SchemaMigrationPlan`。

### 步骤 1：定义你的 Schema 版本

你需要明确告诉系统，你的 App 经历过哪些版本的数据结构。

```swift
import SwiftData

// 第一版模型结构
enum AppSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [UserV1.self] }
}

// 第二版模型结构
enum AppSchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] { [UserV2.self] }
}
```

### 步骤 2：创建 MigrationPlan

在这个计划中，你要定义从 V1 升级到 V2 之间具体发生了什么，并编写**自定义迁移代码** (Custom Migration Stage)。

```swift
enum AppMigrationPlan: SchemaMigrationPlan {
    // 声明所有参与迁移的 Schema
    static var schemas: [any VersionedSchema.Type] {
        [AppSchemaV1.self, AppSchemaV2.self]
    }
    
    // 声明迁移的阶段
    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }
    
    // 具体的一个迁移阶段
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: AppSchemaV1.self,
        toVersion: AppSchemaV2.self,
        willMigrate: { context in
            // 迁移前的准备工作（可选）
        },
        didMigrate: { context in
            // 迁移后的数据处理！
            // 这里你可以抓取所有 V2 的模型，根据它们身上残留的 V1 痕迹来重新计算数据
            let users = try context.fetch(FetchDescriptor<UserV2>())
            for user in users {
                // 假设 V1 只有 firstName 和 lastName，V2 只有 fullName
                // 需要确保你的 V2 模型中用 @Attribute(originalName:) 承接了旧字段，或者在这里手动计算。
                user.fullName = "\(user.firstName) \(user.lastName)"
            }
            try context.save()
        }
    )
}
```

### 步骤 3：在 App 启动时应用迁移计划

最后，当你初始化 `ModelContainer` 时，需要把刚才写好的迁移计划 `MigrationPlan` 传进去。

```swift
import SwiftUI
import SwiftData

@main
struct MyApp: App {
    let container: ModelContainer

    init() {
        do {
            // 使用最终版的 Schema (AppSchemaV2) 创建容器，并指定迁移计划
            container = try ModelContainer(
                for: AppSchemaV2.models,
                migrationPlan: AppMigrationPlan.self
            )
        } catch {
            fatalError("数据库迁移失败: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
```

## 总结

- **多利用自动迁移**：在设计初期，尽量通过加减 Optional 属性或带默认值的属性来推进版本，这能省下很多力气。
- **改名需加宏**：修改属性名称切记加上 `@Attribute(originalName:)`，否则会被当成“删掉旧字段、增加新空字段”，导致数据丢失。
- **重大重构需 Plan**：遇到合并字段、拆分实体的强业务需求，老老实实写 `VersionedSchema` 和 `SchemaMigrationPlan`。