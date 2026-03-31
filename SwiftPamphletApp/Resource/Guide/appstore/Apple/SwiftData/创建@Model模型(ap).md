# 创建 @Model 模型

`@Model` 宏是 SwiftData 框架的核心。它的主要作用是将一个普通的 Swift 引用类型（类 class）转换为由 SwiftData 管理和持久化的数据模型实体。

## 基础用法

要创建一个受管理的模型，你只需要在普通的 `class` 之前添加 `@Model` 宏，并且确保所有存储属性都有初始值。SwiftData 会自动在后台为你生成必要的代码（例如存储结构、观察者、CRUD 方法）。

```swift
import SwiftData
import Foundation

@Model
class Recipe {
    var title: String
    var ingredients: [String]
    var creationDate: Date
    var isFavorite: Bool
    
    // 所有的存储属性都必须有初始值，或者提供构造函数 (init)
    init(title: String, ingredients: [String] = [], isFavorite: Bool = false) {
        self.title = title
        self.ingredients = ingredients
        self.creationDate = Date() // 默认使用当前时间
        self.isFavorite = isFavorite
    }
}
```

### 属性类型

`@Model` 支持绝大多数 Swift 基础类型作为存储属性，包括：
- 基础类型：`String`、`Int`、`Double`、`Bool`、`Date`、`UUID`。
- 枚举类型（必须遵循 `Codable` 和 `RawRepresentable`，如基于 `Int` 或 `String` 的枚举）。
- 集合类型：比如 `[String]`、`[Int]`。
- 自定义结构体（必须遵循 `Codable`，会被序列化为二进制数据存储）。
- 关系模型：其他标记了 `@Model` 的类对象或对象数组。

## 高阶属性定制：`@Attribute`

使用 `@Attribute` 宏，我们可以深度控制模型中的特定属性在底层的持久化行为。

### 1. 唯一性限制（Unique Constraints）

在业务中，我们经常要求某个属性必须是唯一的，比如“用户名”或“条形码”。你可以使用 `.unique` 选项。

```swift
@Model
class User {
    // 系统将保证数据库中不会存在两个 name 相同的 User 对象
    // 如果插入了重名对象，SwiftData 默认会执行 Upsert（更新已存在的记录）
    @Attribute(.unique) var name: String
    var age: Int
    
    init(name: String, age: Int) {
        self.name = name
        self.age = age
    }
}
```

### 2. 外部存储大型数据（External Storage）

对于大型的属性（例如高清图片 `Data` 或大段的富文本），存储在数据库本身可能导致性能下降。使用 `.externalStorage`，SwiftData 会将这些数据存储在数据库文件旁边的独立文件系统中。

```swift
@Model
class Note {
    var title: String
    // 这个属性将被独立存储在文件系统中，从而保持 SQLite 数据库精简和轻量
    @Attribute(.externalStorage) var imageData: Data?
    
    init(title: String, imageData: Data? = nil) {
        self.title = title
        self.imageData = imageData
    }
}
```

### 3. Spotlight 索引

如果你的应用希望某些属性内容能在系统级的 Spotlight 搜索中被检索到，可以使用 `.spotlight`。

```swift
@Attribute(.spotlight) var content: String
```

## 忽略属性：`@Transient`

默认情况下，`@Model` 类中的所有存储属性都会被 SwiftData 保存到数据库中。但有时，你可能只想利用计算属性，或是有一个在应用运行时产生的“临时状态”，不需要保存到硬盘。这时就要使用 `@Transient`。

```swift
@Model
class DownloadTask {
    var url: URL
    
    // 表示这个属性在应用关闭后不需要保存到数据库
    @Transient var downloadProgress: Double = 0.0
    
    init(url: URL) {
        self.url = url
    }
}
```

## 模型关系：`@Relationship`

SwiftData 能自动推断类与类之间的简单关系。但对于更复杂的引用管理（比如删除规则 `deleteRule`，或者是明确的双向引用 `inverse`），就需要使用 `@Relationship` 宏。这部分内容详见《SwiftData-模型关系(ap).md》。