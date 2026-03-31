# Just：最简单的同步 Publisher

在 Combine 提供的众多内置 Publisher 中，**\`Just\`** 是最简单、也最容易理解的一个。

正如它的名字一样：**它“仅仅”包含一个值**。当你订阅它时，它会立刻把这个值发送给你，然后立刻宣布结束。

## 1. Just 的核心特征

*   **同步执行**：它没有延迟，也没有异步队列。它在你调用 \`sink\` (订阅) 的那一瞬间，直接在当前线程把数据喷发出去。
*   **永远不会失败**：它的错误类型 (Failure) 永远是 \`Never\`。
*   **发完即死**：发送一次值之后，紧接着就会发送一个 \`.finished\` 完成事件。

## 2. 基础用法演示

```swift
import Combine

// 1. 创建一个包含整数 42 的 Just 发布者
let magicNumberPublisher = Just(42)

// 2. 订阅它
let cancellable = magicNumberPublisher.sink(
    receiveCompletion: { completion in
        print("收到完成信号: \(completion)")
    },
    receiveValue: { value in
        print("收到值: \(value)")
    }
)

/* 控制台的输出顺序是绝对固定的：
收到值: 42
收到完成信号: finished
*/
```

## 3. 实际开发中的应用场景

既然它这么简单，为什么还需要它呢？\`Just\` 通常扮演**“占位符”**或**“错误恢复的降级数据”**的角色。

### 场景 A：在 flatMap 中快速返回常量
当你在使用 \`flatMap\` 处理一个复杂的网络数据流时，如果某个判断分支不需要发网络请求，而是直接返回一个本地缓存或常量，你需要把这个常量包装成一个 Publisher 才能符合 \`flatMap\` 的类型要求。这时就需要 \`Just\`。

```swift
func fetchUserData(useCache: Bool) -> AnyPublisher<String, Never> {
    if useCache {
        // 不需要异步操作，直接用 Just 把本地字符串包装成 Publisher 返回
        return Just("Alice_Cached").eraseToAnyPublisher()
    } else {
        // ... 返回真实的 URLSession 网络请求 Publisher ...
    }
}
```

### 场景 B：与 catch 配合进行错误恢复
当网络请求失败 (\`.failure\`) 时，如果不希望整个数据流崩溃断开，你可以使用 \`catch\` 操作符拦截错误，并用 \`Just\` 提供一个默认的安全值继续传递给 UI。

```swift
URLSession.shared.dataTaskPublisher(for: someURL)
    .map { $0.data }
    // 如果在上面的网络请求中发生了 URLError，流本来应该被销毁
    // 但 catch 把它拦了下来
    .catch { error -> Just<Data> in
        print("网络出错: \(error)，返回默认的空数据")
        // 使用 Just 返回一个空的 Data 顶替上去
        return Just(Data())
    }
    .sink { data in
        // 这里永远会收到 Data，要么是网络的，要么是 Just 给的默认空数据
        print("最终拿到数据大小: \(data.count)")
    }
```

## 总结

\`Just\` 是 Combine 管道拼接中不可或缺的润滑剂。当你手里只有一个普通变量，但你的框架要求你必须传入一个 \`Publisher\` 时，用 \`Just(变量)\` 包裹一下就完事了。
