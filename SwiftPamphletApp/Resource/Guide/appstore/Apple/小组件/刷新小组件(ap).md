# 如何刷新 iOS 小组件 (Widget Reloading)

小组件（Widget）并不像主 App 那样一直存活在内存中并持续刷新。为了省电，系统极其严格地限制小组件的刷新频率（每天通常有固定的预算，约 40-70 次不等）。

理解小组件刷新的核心在于：**主动触发**与**被动时间线**。

## 1. 被动刷新：Timeline (时间线)

当你为小组件提供数据时（在 `getTimeline` 方法中），你并不是提供“当前”的数据，而是提供一条“时间线”——即一系列未来的数据节点（`TimelineEntry`）。

```swift
func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
    var entries: [SimpleEntry] = []

    // 生成未来几个小时的数据
    let currentDate = Date()
    for hourOffset in 0 ..< 5 {
        let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
        let entry = SimpleEntry(date: entryDate, data: "这是第 \(hourOffset) 小时的数据")
        entries.append(entry)
    }

    // policy: .atEnd 告诉系统：当这 5 个条目（5小时）播放完毕后，再次调用 getTimeline 向我索要新数据。
    let timeline = Timeline(entries: entries, policy: .atEnd)
    completion(timeline)
}
```

### 刷新策略 (Reload Policy)
*   `.atEnd`：当前时间线上的最后一个 entry 显示完毕后，请求新数据。
*   `.after(Date)`：在指定的特定时间点（无论当前时间线有没有播完）强制请求新数据。
*   `.never`：时间线播完后永远不自动刷新。必须由主 App 主动唤醒。

## 2. 主动触发：WidgetCenter 强制刷新

很多时候，用户在主 App 里进行了操作（比如添加了一个新的任务、修改了个人头像），此时我们希望桌面上的小组件能**立刻**发生变化，而不是傻等系统的下一个时间线节点。

这时，你需要使用 `WidgetCenter` API。

### A. 刷新特定种类的小组件
你需要传入你在 `Widget` 结构体中定义的 `kind` 字符串标识符。

```swift
import WidgetKit

// 在主 App 的某个按钮点击事件中调用：
func userDidAddNewTask() {
    // 保存数据到 AppGroup 的 UserDefaults 或 CoreData 中...
    
    // 通知系统强制刷新名为 "TaskWidget" 的小组件
    WidgetCenter.shared.reloadTimelines(ofKind: "TaskWidget")
}
```

### B. 刷新所有小组件
如果你的 App 有多个不同种类的小组件，并且它们都依赖了同一个刚刚被修改的数据库：

```swift
import WidgetKit

func userDidClearAllData() {
    // 强制刷新属于该 App 的所有小组件
    WidgetCenter.shared.reloadAllTimelines()
}
```

## 3. iOS 17 的交互式刷新

从 iOS 17 开始，小组件上的 `Button` 绑定了一个 `AppIntent`。
当用户在桌面上点击这个按钮执行 `perform()` 逻辑后，系统会**自动且隐式地**为关联的小组件重新请求一次 Timeline。因此，如果你的数据是在 `AppIntent` 内部被修改的，你通常不需要显式调用 `WidgetCenter`。

## 注意事项与预算 (Budget)限制

*   **不要频繁调用 reloadTimelines**：如果你在主 App 的 `ScrollView` 滑动时疯狂调用刷新，系统会认为你在恶意消耗资源，并**直接忽略**你的刷新请求。
*   **预算惩罚**：即使是基于时间的 `.after(Date)` 刷新，系统也不保证 100% 准时执行。如果用户的手机电量极低，或者用户极少查看该屏幕，系统会大幅推迟你的刷新请求。
*   **突破预算**：唯一不受预算限制的刷新情况是：主 App 处于前台活跃状态时调用的 `reloadTimelines`。