# flatMap：流的升维与降维魔法

在 Combine 的操作符中，**\`flatMap\`** 是最难理解，但也是在处理异步网络请求时**最不可或缺**的一个。
如果 \`map\` 是“把一个苹果变成一杯苹果汁”，那么 \`flatMap\` 就是“把一个苹果变成一个**果汁加工厂（新的 Publisher）**，然后系统会自动帮你把这个工厂生产出来的果汁接回原来的主管道里”。

## 1. 为什么不能用普通的 map？

假设我们有一个搜索框，用户输入文本。我们把文本变成流：
\`let searchStream = PassthroughSubject<String, Never>()\`

现在我们想拿着这个字符串，去发网络请求。网络请求本身会返回一个 \`URLSession.DataTaskPublisher\`。

如果你用普通的 \`map\`：
```swift
searchStream.map { text in
    // 拿着字符串发起请求
    return fetchNetworkData(query: text) 
}
.sink { value in
    // 灾难！这里的 value 不是最终的 JSON 数据，
    // 而是一个 Publisher 类型的对象！
    // 你得到的是一堆尚未执行的网络管道图纸！
    print(type(of: value)) 
}
```
**\`map\` 只是做映射，它不会去“订阅并执行”你返回的那个内部 Publisher。**

## 2. flatMap 的降维打击

为了让内部的 Publisher 跑起来，并且把内部发出的最终数据“拍平（Flatten）”挤到主管道里，你必须使用 \`flatMap\`。

```swift
searchStream
    .flatMap { text in
        // flatMap 要求你必须返回一个 Publisher
        // 它会在幕后自动帮你订阅这个 fetchNetworkData 产生的流
        return fetchNetworkData(query: text)
            // 内部的流可能报错，但主干流是 Never。你必须在内部把错误处理掉 (比如用 catch 转成 Empty 或 Just)
            .catch { _ in Just("请求失败") }
    }
    .sink { finalResult in
        // 完美！这里收到的就是内部网络请求真正解析出来的最终结果数据了
        print("拿到最终结果: \(finalResult)")
    }
```

## 3. 并发控制：maxPublishers

\`flatMap\` 还有一个极其重要但常被忽略的参数：\`maxPublishers\`。它决定了同时允许多少个内部的 Publisher 并发执行。

假设用户在一秒内疯狂输入了 "A", "Ap", "App"。主管道瞬间发射了 3 个词。\`flatMap\` 会瞬间创建 3 个网络请求！

*   **默认情况**：\`maxPublishers: .unlimited\`。3 个网络请求齐头并进。由于网络延迟，"A" 的结果可能比 "App" 的结果回来得还晚，导致 UI 最终显示的是 "A" 的错误搜索结果（时序错乱，竞态条件）。
*   **串行控制**：\`maxPublishers: .max(1)\`。告诉 flatMap：“一次只准启动一个网络请求！”。如果你还在发 "A" 的请求，此时来了 "App"，"App" 会被**放入缓冲队列排队等待**。直到 "A" 彻底发完并 \`.finished\`，才开始发 "App"。（这通常配合 \`buffer\` 使用）。

### 解决搜索竞态的终极杀器：\`switchToLatest\`
在搜索的场景下，我们既不想无限制并发，也不想慢慢排队，我们想要的是：“一旦我输入了 'App'，请立刻**取消并抛弃**之前那个 'A' 的网络请求，只保留最新的！”

在 Combine 中，有一个比 \`flatMap\` 更专业的变体，它本质上就是 \`map\` + \`switchToLatest()\` 的组合：

```swift
searchStream
    // 每次有新词来，就开启新 Publisher。
    // 如果旧的 Publisher 还没跑完，立刻掐死 (Cancel) 旧的！永远只听最新一个人的话。
    .map { text in fetchNetworkData(query: text) }
    .switchToLatest()
    .sink { ... }
```
这就是 Combine 在网络防抖和最新请求控制上的终极魅力。
