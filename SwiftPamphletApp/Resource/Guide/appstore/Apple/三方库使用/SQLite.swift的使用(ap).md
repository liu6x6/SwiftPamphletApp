# SQLite.swift 使用指南

`SQLite.swift` 是 iOS/macOS 平台上一款非常流行、轻量级且类型安全的 SQLite 数据库封装库。相比于沉重的 Core Data 或是纯 C 语言的底层 SQLite3 API，`SQLite.swift` 提供了极其优雅的 Swift 风格 API（尤其是链式调用和运算符重载），深受许多开发者的喜爱。

## 1. 核心优势
- **纯 Swift 编写**：利用了 Swift 的类型系统，避免了拼写错误的 SQL 字符串。
- **类型安全**：在编译期间就能检查表名和列名是否对应。
- **轻量级**：没有复杂的上下文（Context）和多线程死锁陷阱，即拿即用。

## 2. 建立连接 (Connection)

所有的操作都始于与数据库文件建立连接。如果指定路径的文件不存在，它会自动创建一个新的数据库文件。

```swift
import SQLite

// 1. 获取应用的沙盒 Documents 目录
let path = NSSearchPathForDirectoriesInDomains(
    .documentDirectory, .userDomainMask, true
).first!

do {
    // 2. 建立连接。如果数据库不存在，会自动创建 db.sqlite3
    let db = try Connection("\(path)/db.sqlite3")
    print("数据库连接成功")
} catch {
    print("无法连接到数据库: \(error)")
}
```

## 3. 定义数据表与列 (Table & Expressions)

在 `SQLite.swift` 中，你不写 "CREATE TABLE..."，而是定义代表表和列的常量。

```swift
// 定义表名
let users = Table("users")

// 定义列（类型安全）
let id = Expression<Int64>("id")
let email = Expression<String>("email")
let name = Expression<String?>("name") // 可选类型
let balance = Expression<Double>("balance")

do {
    // 创建表
    try db.run(users.create(ifNotExists: true) { t in
        // t.column 相当于建表语句中的字段声明
        t.column(id, primaryKey: true) // 主键，自增
        t.column(email, unique: true)  // 唯一约束
        t.column(name)
        t.column(balance, defaultValue: 0.0) // 默认值
    })
} catch {
    print("建表失败: \(error)")
}
```

## 4. 增删改查 (CRUD)

### 增 (Insert)
使用 `insert` 方法，并传入列名对应的赋值表达式。

```swift
// 插入一条记录
let insert = users.insert(email <- "alice@mac.com", name <- "Alice")
do {
    let rowId = try db.run(insert) // 返回插入的自增主键 ID
    print("插入成功，ID: \(rowId)")
} catch {
    print("插入失败: \(error)")
}
```

### 查 (Select)
查询非常直观，支持类似高阶函数的 `filter`（条件）和 `order`（排序）。

```swift
// 查询所有人，遍历
for user in try db.prepare(users) {
    print("ID: \(user[id]), Email: \(user[email]), Name: \(user[name] ?? "无名")")
}

// 带条件的查询 (WHERE)
let query = users.filter(email == "alice@mac.com")
if let alice = try db.pluck(query) { // pluck 返回单条记录
    print("找到了 Alice: \(alice[email])")
}
```

### 改 (Update)
要更新记录，你需要先 `filter` 定位到目标行，然后再执行 `update`。

```swift
let targetUser = users.filter(id == 1) // 找到 ID 为 1 的记录
let updateQuery = targetUser.update(balance <- balance + 100.0, name <- "Alice Pro")

do {
    let changes = try db.run(updateQuery) // 返回受影响的行数
    print("更新了 \(changes) 条记录")
} catch {
    print("更新失败: \(error)")
}
```

### 删 (Delete)
删除操作同理，先过滤，后删除。

```swift
let targetUser = users.filter(id == 1)
do {
    let deletedCount = try db.run(targetUser.delete())
    print("删除了 \(deletedCount) 条记录")
} catch {
    print("删除失败: \(error)")
}
```

## 5. 聚合函数与执行原生 SQL

`SQLite.swift` 支持常见的聚合函数。

```swift
let count = try db.scalar(users.count) // 获取总行数
let totalBalance = try db.scalar(users.select(balance.sum)) // 计算总余额
```

如果有非常复杂的、无法用链式 API 表达的 SQL 查询，你依然可以执行原生字符串 SQL：

```swift
let stmt = try db.prepare("SELECT id, email FROM users WHERE balance > ?")
for row in try stmt.run(500.0) { // 传入绑定参数，防止 SQL 注入
    print("ID: \(row[0]), Email: \(row[1])")
}
```

## 总结
`SQLite.swift` 是介于底层 SQL 和厚重 ORM 之间的一个绝佳甜点。它保留了关系型数据库的直观感，同时通过 Swift 的泛型和运算符重载提供了现代化的类型安全体验。非常适合中小规模、或者结构不需要频繁变动的 iOS 独立项目使用。