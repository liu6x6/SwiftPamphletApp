# 增删改查：ModelContext 操作

在 SwiftData 中，`ModelContext` (模型上下文) 是你执行所有数据变动（增、删、改）以及执行检索（查）的核心中枢。可以将它想象成一个用于容纳和追踪待处理数据变更的“暂存区”（Scratchpad）。只有当上下文的内容被执行 `save()` 操作时，更改才会被持久化到真正的底层的 `ModelContainer`（也就是数据库）中。

## 获取 ModelContext

在 SwiftUI 视图中，推荐的做法是通过环境变量来获取主上下文（Main Context），它会自动绑定到主线程，非常适合直接用来更新 UI。

```swift
import SwiftUI
import SwiftData

struct RecipeListView: View {
    // 关键：通过环境属性注入模型上下文
    @Environment(\.modelContext) private var modelContext
    
    // ...
}
```

## 1. 增 (Insert)

新增一条记录非常简单，主要分为两步：
1. 创建一个新的 `@Model` 对象实例。
2. 使用 `modelContext.insert()` 将这个实例交给上下文管理。

```swift
func addRecipe() {
    // 1. 实例化
    let newRecipe = Recipe(title: "新菜谱: 红烧肉", creationDate: Date())
    
    // 2. 插入到上下文中
    modelContext.insert(newRecipe)
    
    // 注意：在 SwiftUI 中如果 autoSave 开启了，你不需要显式调用 context.save()
}
```

## 2. 删 (Delete)

删除操作是指将某个已存在于模型容器中的 `@Model` 实例给移除掉。你需要引用那个要被删除的对象。

```swift
func deleteRecipe(recipe: Recipe) {
    // 告诉上下文删除指定的对象
    modelContext.delete(recipe)
}

// 常见场景：在 SwiftUI 的 List 滑动删除中使用
func deleteItems(offsets: IndexSet) {
    for index in offsets {
        let recipe = recipes[index] // recipes 是由 @Query 获取的数组
        modelContext.delete(recipe)
    }
}
```

此外，`ModelContext` 提供了按查询条件批量删除的功能，对于需要清空大量数据的场景极具效率：

```swift
// 移除符合条件的所有模型，比如删除所有没有被收藏的记录
try? modelContext.delete(
    model: Recipe.self,
    where: #Predicate { recipe in
        recipe.isFavorite == false
    }
)
```

## 3. 改 (Update)

与其他一些数据库框架不同，在 SwiftData 中，修改一条记录不需要显式地调用特殊的 `update` 方法。因为你获取到的 `@Model` 实例是一个**引用类型 (Class)**，并且这个实例正被上下文监视着。
只要直接修改这个对象的属性，`ModelContext` 就会自动侦测到改变（类似于 `@Observable` 机制），并在合适的时机保存。

```swift
func toggleFavorite(for recipe: Recipe) {
    // 直接修改属性即可！
    recipe.isFavorite.toggle()
    
    // SwiftData 会在幕后捕捉到 'isFavorite' 的变更，并自动执行后续的持久化操作。
}
```

## 4. 查 (Fetch)

大部分情况下，你会在 SwiftUI 中直接使用 `@Query` 这个宏，它封装了内部对 `ModelContext` 的抓取操作并自带数据绑定。但是，如果你在非 SwiftUI 的后台逻辑中或者视图的某个确切的 Action 闭包里需要一次性检索数据，你可以使用 `modelContext.fetch(_:)`。

```swift
func checkData() {
    do {
        // 创建一个 FetchDescriptor (抓取描述符)，可以提供谓词 (条件) 和排序方式
        let descriptor = FetchDescriptor<Recipe>(
            predicate: #Predicate { $0.title.contains("炒") },
            sortBy: [SortDescriptor(\.creationDate, order: .reverse)]
        )
        
        // 从上下文同步执行请求
        let results = try modelContext.fetch(descriptor)
        print("找到了 \(results.count) 个匹配的菜谱")
    } catch {
        print("抓取失败: \(error)")
    }
}
```

## 保存与自动保存 (Auto-save)

通过 SwiftUI 的修饰符（如 `.modelContainer(for:)`）注入到环境中的 `mainContext`，**默认开启了自动保存（autosave）**。这意味着：当你执行了 `insert`、`delete` 或是修改了属性之后，你**不需要**手动调用 `try? modelContext.save()`。系统会自动在 RunLoop 的空闲时刻、App 进入后台、或者相关的窗口被销毁时去保存数据。

但是，某些特定情况下，你可能需要立即保证数据落盘（例如执行了极其重要不可丢失的记录）：
```swift
func forceSave() {
    do {
        if modelContext.hasChanges {
            try modelContext.save()
        }
    } catch {
        print("立即保存失败: \(error)")
    }
}
```

## Undo / Redo (撤销和重做)

SwiftData 与系统的撤销管理器紧密结合。你可以很轻易地在上下文中启用撤销功能，让你的 `insert` / `delete` / `update` 都能像文本编辑器一样撤回。

```swift
@Environment(\.modelContext) private var modelContext

var body: some View {
    Button("撤销") {
        modelContext.undoManager?.undo()
    }
    .onAppear {
        // 绑定一个原生的撤销管理器
        modelContext.undoManager = UndoManager()
    }
}
```