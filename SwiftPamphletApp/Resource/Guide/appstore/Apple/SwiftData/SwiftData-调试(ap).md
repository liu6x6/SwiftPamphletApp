# SwiftData 调试技巧

在开发使用 SwiftData 的应用时，你可能会遇到数据没有按预期保存、查询结果不正确，或是应用启动时崩溃等问题。以下是一些核心的调试技巧和方法。

## 1. 开启 Core Data / SwiftData 的 SQL 日志

因为 SwiftData 底层是 SQLite 驱动的，查看它实际执行了哪些 SQL 语句是最高效的排错方式。你可以通过配置 Xcode 的启动参数 (Launch Arguments) 来打印底层的日志。

**如何开启：**
1. 在 Xcode 中，点击顶部菜单栏的 Scheme（例如 `MyApp`） -> `Edit Scheme...`
2. 选择左侧的 `Run` -> 顶部的 `Arguments` 标签页。
3. 在 `Arguments Passed On Launch` 中，添加以下参数：
   - `-com.apple.CoreData.SQLDebug 1`
   *(数字 `1` 代表基本日志，最高可以设为 `3` 或 `4` 以查看极其详细的日志。)*
4. 如果你想查看并发或多线程相关的问题（如上文提到的跨线程误用 Context），可以添加：
   - `-com.apple.CoreData.ConcurrencyDebug 1`

开启后，当你执行 `insert` 或 `@Query` 时，Xcode 控制台会直接打印出它生成的 `SELECT` 或 `INSERT INTO` 语句。这对排查为什么某个 Predicate 没有生效极其有用。

## 2. 找到并打开底层的 SQLite 文件

有时候你只想直观地看看数据库里到底存了什么。

在模拟器或 macOS 应用上，你可以通过打印默认 `ModelContainer` 的存储路径来找到 SQLite 文件的位置。

```swift
// 在你的 App 启动或者某个视图的 onAppear 中加入这行代码：
print("数据库路径: ", URL.applicationSupportDirectory.path(percentEncoded: false))
```

运行后，从控制台复制这个路径，然后在 Mac 的 Finder 中按 `Cmd + Shift + G` 粘贴前往。你会看到一个 `default.store` 或者以你 App 命名的 `.sqlite` 文件。

你可以使用第三方的数据库查看工具（如 **DB Browser for SQLite** 或 **TablePlus**）打开它，直接查看里面的数据表。
*(注意：不要在 App 运行期间用第三方工具强行修改数据库文件，这可能会破坏持久化历史记录。)*

## 3. 处理 "Thread 1: Fatal error: failed to find a currently active container"

**常见原因**：你在某个子视图中使用了 `@Environment(\.modelContext)` 或 `@Query`，但是**忘记了**在它的父视图或 App 的入口处使用 `.modelContainer(for:)` 注入容器。

**解决方案**：确保在组件树的最顶端（通常是 `@main` 的 `WindowGroup`）注入了 Container。

## 4. 解决 "Data model does not match the store" 崩溃

**常见原因**：你修改了 `@Model` 类的结构（比如添加了一个没有默认值的非可选属性，或者删除了一个属性），但是**没有**提供版本迁移方案（MigrationPlan）。当你再次运行 App 时，底层发现现有的 SQLite 文件结构与当前代码里的模型对不上，于是崩溃。

**快速解决（仅限开发阶段）**：
如果你还在开发早期，不在乎现有的测试数据丢失，你可以**直接从模拟器/真机上删除这个 App**，然后重新编译运行。这会让 SwiftData 从零开始创建一个匹配当前最新代码结构的新 SQLite 文件。
*(如果是上线的应用，你必须参考 `SwiftData-版本迁移(ap).md` 来写迁移代码！)*

## 5. 打印 Context 的状态

当你怀疑数据没有被保存时，可以打印 `ModelContext` 的状态来辅助判断：

```swift
// 检查是否有尚未保存的更改
print("是否有更改未保存？ \(modelContext.hasChanges)")

// 检查某个特定的对象是否已经被 Context 管理
print("对象是否被删除？ \(item.isDeleted)")
```