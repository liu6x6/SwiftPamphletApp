# prepend：在数据流的头部抢跑数据

在了解了 `append`（在原数据流结束后追加数据）之后，它的孪生兄弟 **`prepend`** 就非常好理解了。

`prepend` 的作用是：**在订阅者（Subscriber）连接到这个 Publisher 的那一瞬间，强行在真正的原数据到达之前，先“抢跑”发射一段我们预设好的数据。** 等这段预设数据发完，主管道里的真实数据才开始正常流淌。

## 1. 基础用法

和 `append` 一样，你可以 prepend 单个值、一个序列，或者另一个完整的 Publisher。

### A. 预设单个或一组常量
```swift
import Combine

let numbers = [3, 4, 5].publisher

numbers
    // 在 3, 4, 5 发出之前，先强行发出 1 和 2
    .prepend(1, 2)
    .sink { print($0) }

// 严格按顺序输出: 1, 2, 3, 4, 5
```

### B. 抢跑另一个 Publisher
这就比较有趣了。**主 Publisher 必须被挂起等待！** 必须等到你 prepend 的那个占位 Publisher 彻底发送了 `.finished` 完成信号，主管道的数据才能被允许放行。

```swift
let mainStream = PassthroughSubject<String, Never>()
let warmupStream = PassthroughSubject<String, Never>()

mainStream
    .prepend(warmupStream)
    .sink { print("收到: \($0)") }

// 此时如果主线有数据发出，会被强制拦截在缓冲区！
mainStream.send("主线数据A")

// 预热流发出数据
warmupStream.send("预热1")
warmupStream.send("预热2")

// 告诉预热流结束了！
// 这一行极其关键，没有这一行，主线数据永远出不来
warmupStream.send(completion: .finished)

/* 控制台输出:
收到: 预热1
收到: 预热2
收到: 主线数据A  <- 预热流结束后，刚才憋在主线里的数据瞬间喷涌而出
*/
```

## 2. 极其经典的实战场景：初次加载状态与本地缓存

`prepend` 在真实的业务开发中非常实用，尤其是在涉及**状态机初始化**和**快速展示缓存**的时候。

### 场景 A：强制提供初始默认状态
你在用一个没有初始值的 `PassthroughSubject` 监听一个下拉刷新事件。你希望在 UI 刚刚绑定 (\`sink\`) 的那一瞬间，先自动触发一次刷新。

```swift
let refreshTrigger = PassthroughSubject<Void, Never>()

refreshTrigger
    // 在没有任何人点击刷新时，强行在头部塞入一个“无形”的触发信号
    .prepend(()) 
    .flatMap { _ in api.fetchFeed() }
    .sink { data in
        // 绑定成功的一瞬间，这里就会执行一次初始网络请求！
    }
```

### 场景 B：离线弱网下的本地缓存秒开 (Cache then Network)
当用户打开一篇文章时，为了避免盯着白屏看转圈圈，我们通常希望**先立刻把数据库里的旧缓存显示出来，然后在后台静默发起网络请求，等网络新数据回来了再去覆盖它。**

用 `prepend` 几行代码就能完美实现这个极其复杂的工业级逻辑：

```swift
func loadArticle(id: String) {
    // 这是一个代表网络请求的 Publisher，可能需要 2 秒才返回
    let networkRequest = api.fetchArticle(id: id)
    
    // 这是一个同步从本地数据库读取的方法
    let localCache = database.getArticle(id: id)
    
    networkRequest
        // 魔法就在这里：在网络数据（可能很慢）到达之前，先抢跑把本地缓存（瞬间）发射给下游！
        .prepend(localCache)
        .receive(on: RunLoop.main)
        .sink { article in
            // 这个闭包会被调用两次！
            // 第 1 次：在订阅的一瞬间，收到来自 prepend 的旧缓存数据，UI 瞬间展示（秒开体验）。
            // 第 2 次：等了 2 秒后，收到了 networkRequest 真正的最新数据，UI 再次刷新。
            self.render(article)
        }
        .store(in: &cancellables)
}
```
通过 `prepend` 实现的 Cache-Then-Network 模式，是 Combine 优雅取代庞大意大利面条代码的巅峰之作。
