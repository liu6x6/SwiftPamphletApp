# 小组件的后台定时与数据拉取

让小组件能够“自动”且“定时”地从远程服务器获取最新数据，是小组件开发中最核心也是最容易踩坑的环节。

## 1. 为什么小组件不能保证“绝对准时”？

iOS 极度看重电池寿命。Apple **绝对禁止**任何应用在后台无节制地唤醒网络并刷新 UI。
*   **Budget (预算)**：每个小组件都有一个系统分配的刷新预算（通常每天几十次）。
*   **启发式算法 (Heuristics)**：系统会学习用户习惯。如果用户把你的小组件放在了主屏幕的第一页，并且每天频繁查看，系统会给你更多的刷新机会。如果放在最后一页且很少滑动到那里，系统会强行忽略你的刷新请求（即使你代码里写了要求 5 分钟后刷新）。

## 2. 策略一：基于 Timeline 的前瞻性拉取 (推荐)

最优雅的做法是，当你的 \`getTimeline\` 被系统唤醒时，**一次性向服务器请求未来一段时间内的所有数据节点**。

例如，天气预报小组件：
1. 系统在早晨 8:00 唤醒你。
2. 你向服务器请求数据，服务器直接返回了从 8:00 到晚上 20:00 每小时的天气预报（共 12 条数据）。
3. 你把这 12 个节点封装成 \`TimelineEntry\` 的数组。
4. 告诉系统 \`policy: .atEnd\`。
系统会在接下来的 12 个小时里，到了特定的整点，**不需要唤醒你的代码，也不需要网络**，直接把对应的 UI 渲染出来。这是最省电、最稳定的做法。

## 3. 策略二：基于 Reload Policy 的定时唤醒

如果你做的是“突发新闻”或者“股票价格”，未来数据是不可预测的。你只能要求系统过一段时间再唤醒你一次。

```swift
func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
    // 1. 发起网络请求拿到当前最新股票价格
    fetchCurrentStockPrice { price in
        let entry = SimpleEntry(date: Date(), currentPrice: price)
        
        // 2. 告诉系统：我希望 15 分钟后你再把我唤醒一次
        // 注意：这只是一个“建议”。系统可能会在 15 分钟后唤醒你，也可能是在 30 分钟后。
        let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
        completion(timeline)
    }
}
```
*警告：不要将刷新间隔设置得太短（如 1 分钟）。Apple 官方建议最小间隔不低于 15-30 分钟。如果设置过短，极易触碰预算红线导致被系统拉黑，停止刷新。*

## 4. 策略三：利用主 App 或后台任务 (Background Tasks) 推送刷新

如果你需要极高的实时性，单靠小组件自身的 Timeline 是做不到的。必须借助外力：

*   **主 App 在前台活跃时**：利用 \`Timer\` 或 \`WebSocket\` 接收数据，收到数据后，调用 \`WidgetCenter.shared.reloadTimelines()\`。这种操作不消耗小组件的刷新预算。
*   **后台推送 (Silent Push Notifications)**：服务器发送一个带有 \`content-available: 1\` 的静默推送。主 App 的 AppDelegate 被唤醒，此时在后台下载数据并保存到 AppGroup 中，然后调用 \`WidgetCenter\` 触发小组件刷新。这种方案常用于突发重大新闻的推送。
*   **Background Fetch**：利用 \`BGTaskScheduler\` 在主 App 里注册后台刷新任务，定期同步数据并刷新 Widget。
