# removeDuplicates：过滤重复的连续事件

在处理连续的数据流（比如用户的实时输入、传感器高频回传的滚动坐标）时，我们经常会遇到**紧挨着的两次数据完全一模一样**的情况。

为了节省计算资源（比如避免不必要的 UI 刷新或网络请求），我们需要一种机制：**只要新的值和上一个值相同，就扔掉它**。这正是 \`removeDuplicates()\` 操作符的职责。

## 1. 基本用法 (要求元素遵循 Equatable)

如果 Publisher 发出的数据类型本身遵循了 \`Equatable\`（例如 \`Int\`, \`String\`, \`Bool\`），你可以直接调用这个方法，不需要传任何参数。

```swift
import Combine

let numbers = [1, 1, 2, 2, 2, 3, 1, 4, 4].publisher

let cancellable = numbers
    // 拦截流，丢弃与前一个元素相同的元素
    .removeDuplicates()
    .sink { print($0) }

// 输出结果:
// 1
// 2
// 3
// 1  (注意：1 再次出现时不会被丢弃，因为它和前一个元素 3 不一样。removeDuplicates 只看相邻的元素！)
// 4
```

## 2. 自定义判断逻辑 (闭包版本)

如果你发出的数据是一个极其复杂的结构体，或者它没有遵循 \`Equatable\`，又或者你只想根据**某个特定的属性**来判断是否“重复”。你可以提供一个自定义的闭包。

```swift
struct Point {
    let x: Int
    let y: Int
}

let points = [
    Point(x: 0, y: 0),
    Point(x: 0, y: 10), // x 没变，y 变了
    Point(x: 0, y: 20),
    Point(x: 5, y: 20)  // x 变了
].publisher

let cancellable = points
    // 自定义规则：我们只关心 x 坐标，只要 x 坐标没变，我们就认为是“重复”的数据
    .removeDuplicates { prevPoint, currentPoint in
        return prevPoint.x == currentPoint.x
    }
    .sink { print("有效点: x: \($0.x), y: \($0.y)") }

// 输出结果:
// 有效点: x: 0, y: 0
// 有效点: x: 5, y: 20
```

## 3. 在 SwiftUI 和 MVVM 中的典型应用

\`removeDuplicates\` 在结合 SwiftUI 的 TextField 搜索功能时堪称神器。

假设用户在快速输入 "Apple"，状态可能是 "A" -> "Ap" -> "App" -> "App" (用户犹豫了一下，输入法可能重复发送了状态) -> "Apple"。

```swift
class SearchViewModel: ObservableObject {
    @Published var searchText: String = ""
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        $searchText
            // 1. 等用户停止打字 0.5 秒后再往后走 (防抖)
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            // 2. 核心：如果用户删除了一个字母又极快地打上了相同的字母，导致 0.5 秒后最终的词和上次搜索的词一模一样，就拦截掉！
            .removeDuplicates()
            .sink { query in
                print("向服务器发起真实的搜索请求: \(query)")
            }
            .store(in: &cancellables)
    }
}
```
通过 \`debounce\` + \`removeDuplicates\` 的黄金组合，你能挡下 90% 的无效网络请求浪费。
