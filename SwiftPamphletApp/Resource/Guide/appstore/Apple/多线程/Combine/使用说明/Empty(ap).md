# Empty：立刻终结的沉默发布者

在 Combine 中，**\`Empty\`** 是一个极其特殊的 Publisher。它的行为准则可以用四个字概括：**一毛不拔，光速下班**。

当你订阅一个 \`Empty\` Publisher 时：
1. 它**绝对不会**发送任何 `Value`（输出值）。
2. 它会**立刻**发送一个 `.finished`（完成信号）并结束生命周期。
3. （可选）如果你配置了 `completeImmediately: false`，它连完成信号都不发，就这么沉默地挂在内存里，直到宇宙毁灭。

## 1. 基础用法

```swift
import Combine

// 创建一个声明输出 Int 的空发布者
let emptyPublisher = Empty<Int, Never>()

emptyPublisher.sink(
    receiveCompletion: { print("收到完成: \($0)") },
    receiveValue: { print("收到值: \($0)") } // 这一行永远不会被执行
)

// 输出结果仅仅是一行:
// 收到完成: finished
```

## 2. Empty 的意义何在？

如果你单独使用 \`Empty\`，它确实毫无意义。就像 \`Just\` 一样，\`Empty\` 也是管道拼装中的**错误处理和占位符神器**。

### 场景 A：在 catch 中吃掉错误并切断水流

当网络请求发生错误时，你可能不想给 UI 返回一个默认的兜底假数据（这是 \`Just\` 的干的活），你只是想**悄无声息地让这个错误流消失，不更新 UI**。

```swift
func fetchSettings() -> AnyPublisher<String, Never> {
    return URLSession.shared.dataTaskPublisher(for: URL(string: "https://api.com")!)
        .map { String(data: $0.data, encoding: .utf8) ?? "" }
        .catch { error -> Empty<String, Never> in
            print("网络崩溃了，但我不想给下游任何数据")
            // 抛出一个 Empty。这会把原本带有 URLError 的流，
            // 强行转换成一个不会报错 (Never)、也没有数据、瞬间完成的流。
            return Empty<String, Never>()
        }
        .eraseToAnyPublisher()
}

// 在 UI 层订阅
fetchSettings().sink { value in
    // 如果网络成功，更新 UI。
    // 如果网络失败，因为 catch 返回了 Empty，这里根本不会被触发，UI 保持原样！
    print("更新UI: \(value)") 
}
```

### 场景 B：在 flatMap 中按条件阻断事件

假设你监听了搜索框的输入。如果你判断用户输入的是脏话或为空，你不想发起网络请求，你就可以返回一个 \`Empty\` 结束这次管道的传播。

```swift
$searchText
    .flatMap { text -> AnyPublisher<SearchResult, Never> in
        if text.isEmpty || text.contains("脏话") {
            // 阻断流，下游不会收到任何东西
            return Empty().eraseToAnyPublisher()
        } else {
            // 发起真正的网络搜索
            return api.search(query: text)
        }
    }
    .sink { result in
        // 渲染搜索结果
    }
```

## 3. 极端的变体：completeImmediately = false

当你初始化时传入 `Empty(completeImmediately: false)` 时，它变成了一个**僵尸流**。
它不发数据，也不发完成信号。这通常用于极其特殊的单元测试中，用于模拟一个永远处于“正在挂起（Pending）”状态，永远不响应的请求。
