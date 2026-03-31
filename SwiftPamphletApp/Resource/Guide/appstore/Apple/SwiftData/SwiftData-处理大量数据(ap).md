# SwiftData 处理大量数据与性能优化

当你的应用需要处理成千上万条记录（例如：从服务器下载数万条日志、导入庞大的 JSON 文件、或进行大批量的数据清洗）时，如果处理不当，会导致内存激增 (OOM)、UI 卡顿甚至应用崩溃。

在 SwiftData 中，应对大量数据的核心策略是：**分批处理、后台上下文、及时释放内存。**

## 1. 为什么大量数据会导致问题？

当你执行 `context.fetch()` 抓取数据或使用 `context.insert()` 插入大量数据时，`ModelContext` 为了追踪所有这些对象的状态，会把它们全部加载到内存中（这被称为 Context 的注册表 Registered Objects）。如果不加干预，这些对象会一直驻留在内存中，直到 Context 被销毁。

## 2. 批量插入 (Batch Insert)

如果你需要一次性插入几万条记录，请一定要将任务放在后台的 `@ModelActor` 中执行（参见多线程章节），并且要**分批保存和清理**。

```swift
@ModelActor
actor DataImporter {
    func importMassiveData(items: [RawItem]) throws {
        let batchSize = 1000 // 根据你的模型复杂度，选择 500-2000 的批次大小
        
        for (index, rawItem) in items.enumerated() {
            let model = Item(name: rawItem.name, value: rawItem.value)
            modelContext.insert(model)
            
            // 每处理完一个批次，就执行保存并清空内存
            if (index + 1) % batchSize == 0 {
                try modelContext.save()
                
                // 【性能关键】: 将上下文中未引用的所有对象从内存中释放
                // 必须在 save 之后调用，否则未保存的数据会丢失！
                modelContext.transaction {
                     // （在未来的 API 中可能有更直接的清理方法，但目前可以通过重置或使用短生命周期的临时 Context）
                }
            }
        }
        
        // 保存最后一批剩余的数据
        if modelContext.hasChanges {
            try modelContext.save()
        }
    }
}
```
*提示：如果是极端的大规模只读数据插入，某些开发者会选择在底层直接生成 SQLite 文件，但这超出了 SwiftData 的标准用法。*

## 3. 批量删除 (Batch Delete)

如果要把某个实体的数万条记录全部删掉，不要去 fetch 出所有对象然后一个一个 `context.delete(item)`。这会先把几万个对象加载进内存，再把它们删掉，极其低效。

SwiftData 提供了按谓词（Predicate）直接执行批量删除的方法：

```swift
func deleteAllOldLogs() throws {
    // 例如：删除一年前的日志
    let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date())!
    
    // 这个操作直接在底层的存储后端发生，不需要把对象加载到内存中
    try modelContext.delete(
        model: LogEntry.self,
        where: #Predicate { $0.timestamp < oneYearAgo }
    )
    
    try modelContext.save()
}
```

## 4. 优化查询 (Fetch Limit & Faults)

### 限制抓取数量 (Fetch Limit & Offset)
如果你只想显示前 10 名用户，千万不要把 10000 个用户抓取下来再 `prefix(10)`。

```swift
var descriptor = FetchDescriptor<User>(sortBy: [SortDescriptor(\.score, order: .reverse)])
descriptor.fetchLimit = 10 // 告诉底层数据库只返回 10 条
let top10 = try modelContext.fetch(descriptor)
```

### 属性惰性加载 (Faulting - 默认开启)
SwiftData 默认继承了 Core Data 的 "Faulting" 机制。当你 fetch 一个包含大量关系或属性（尤其带有 `.externalStorage` 的图片 Data）的对象时，系统实际上返回的是一个“空壳”（Fault）。只有当你真正在代码中访问这个属性时，系统才会去硬盘上把真正的值读出来（Firing the fault）。

**注意事项**：如果在循环中频繁触发 Fault（例如遍历一万个对象，读取每个对象的复杂关联属性），会导致极其严重的 I/O 阻塞（N+1 查询问题）。

### 预取关联 (Prefetching)
为了解决上述的 N+1 问题，如果你确信接下来的循环中肯定要用到关联的属性，你可以提前让数据库一次性把它们和主对象一起抓取上来。

```swift
// 假设我们要抓取作者，并且确定要在界面上显示他们名下的所有书的标题
var descriptor = FetchDescriptor<Author>()
// 告诉 SwiftData 一并把 Author 的 books 关联关系加载上来，避免后续触发 N+1 次查询
descriptor.relationshipKeyPathsForPrefetching = [\.books]

let authors = try context.fetch(descriptor)
```

## 5. UI 层的表现优化

在 SwiftUI 中使用 `@Query` 显示巨长列表时：
1. 始终搭配 `List` 或 `LazyVStack`，它们只会渲染屏幕可见的记录。
2. 避免在每个 List Row 内执行耗时的数据计算或极其复杂的视图逻辑。
3. 如果数据需要频繁的高频跳动（如股票实时跳动 10次/秒），不建议直接使用 `@Query`，应该使用独立的内存模型驱动高频 UI，然后低频（例如 1秒1次）写入 SwiftData 中持久化。