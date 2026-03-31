# SwiftData 中的检索 (@Query 与 FetchDescriptor)

在 SwiftData 中，检索（Fetching）数据到 UI 是通过 `@Query` 宏或者通过 `ModelContext` 执行 `FetchDescriptor` 来完成的。

## 1. SwiftUI 中的终极利器：`@Query` 宏

如果你在 SwiftUI 中需要展示一组由 SwiftData 托管的数据，`@Query` 宏是首选方法。它不仅负责初始的数据抓取，还会**自动监听数据的变化**并触发视图刷新（类似于 `@State` 或 `@ObservedObject` 的效果）。

### 基础用法

只要在视图中声明 `@Query` 并指定模型类型，SwiftUI 就会在视图加载时自动从环境变量中的 `modelContext` 获取数据。

```swift
import SwiftUI
import SwiftData

struct RecipeListView: View {
    // 获取所有的 Recipe，没有任何排序和过滤条件
    @Query var recipes: [Recipe]

    var body: some View {
        List(recipes) { recipe in
            Text(recipe.title)
        }
    }
}
```

### 排序 (Sort)

通过在 `@Query` 中传入 `sort` 参数，可以指定数据的排列顺序。支持单一属性排序或多属性组合排序。

```swift
// 按创建时间倒序排列 (最新的在前面)
@Query(sort: \Recipe.creationDate, order: .reverse)
var latestRecipes: [Recipe]

// 组合排序：先按是否为收藏 (favorite) 排序，然后按标题字母顺序排序
@Query(sort: [
    SortDescriptor(\Recipe.isFavorite, order: .reverse), // 收藏的在前 (true 在前)
    SortDescriptor(\Recipe.title, order: .forward)
])
var sortedRecipes: [Recipe]
```

### 过滤/谓词 (Filter / Predicate)

使用 `#Predicate` 宏（它是 iOS 17 新引入的类型安全的谓词系统）来对获取的数据进行条件过滤。

```swift
// 只查询被标记为收藏的菜谱
@Query(filter: #Predicate<Recipe> { recipe in
    recipe.isFavorite == true
})
var favoriteRecipes: [Recipe]

// 字符串匹配：查询标题中包含特定关键字的记录
@Query(filter: #Predicate<Recipe> { recipe in
    // 注意：谓词闭包中支持的操作符是有限的（如 contains, startsWith 等）
    recipe.title.contains("牛肉") 
})
var beefRecipes: [Recipe]
```

### 动态构建 @Query（基于搜索框）

很多时候，我们需要根据用户在 `TextField` 或 `searchable` 中输入的文本动态改变查询条件。你可以利用 `init(filter:sort:)` 在自定义视图中手动初始化 `@Query`。

```swift
struct FilteredRecipeList: View {
    @Query var recipes: [Recipe]

    init(searchText: String) {
        // 构建动态谓词
        let predicate = #Predicate<Recipe> { recipe in
            searchText.isEmpty ? true : recipe.title.contains(searchText)
        }
        
        // 重新初始化 @Query
        _recipes = Query(filter: predicate, sort: \.title)
    }

    var body: some View {
        List(recipes) { recipe in
            Text(recipe.title)
        }
    }
}

// 在父视图中使用
struct MainView: View {
    @State private var searchText = ""
    var body: some View {
        FilteredRecipeList(searchText: searchText)
            .searchable(text: $searchText)
    }
}
```

## 2. 后台与逻辑层检索：FetchDescriptor

在非 SwiftUI 视图环境（比如 ViewModel 业务逻辑、后台队列、App 启动时的预处理检查）中，你无法使用 `@Query`，必须使用底层的 `FetchDescriptor`。

`FetchDescriptor` 将你要查询的实体类型、过滤条件（`Predicate`）、排序方式（`SortDescriptor`）以及其他高级配置（比如限制返回条数 `fetchLimit`、偏移量 `fetchOffset` 等）组合在一起。

```swift
func findTop3ExpensiveItems(in context: ModelContext) {
    let predicate = #Predicate<Item> { $0.price > 100 }
    let sortBy = [SortDescriptor(\Item.price, order: .reverse)]
    
    // 1. 创建抓取描述符
    var descriptor = FetchDescriptor<Item>(predicate: predicate, sortBy: sortBy)
    
    // 2. 配置高级选项：例如只抓取前 3 条结果
    descriptor.fetchLimit = 3
    // descriptor.fetchOffset = 10 // 如果需要分页，可以使用 offset
    
    do {
        // 3. 通过 context 执行抓取
        let results = try context.fetch(descriptor)
        for item in results {
            print("Found high price item: \(item.name) - $\(item.price)")
        }
    } catch {
        print("Failed to fetch: \(error)")
    }
}
```

### 预加载关系 (Fetch properties and relationships)

`FetchDescriptor` 还可以优化性能。如果你知道你在处理这些数据时，肯定会需要用到它们关联的对象，你可以使用 `relationshipKeyPathsForPrefetching` 提前加载关联数据，避免 N+1 查询问题产生的性能消耗。